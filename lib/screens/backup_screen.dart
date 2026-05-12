import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/diary_provider.dart';
import '../services/backup_service.dart';
import '../services/drive_backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _service = BackupService();
  final DriveBackupService _drive = DriveBackupService();

  bool _busy = false;
  String? _statusMessage;
  bool _isError = false;
  GoogleSignInAccount? _account;

  @override
  void initState() {
    super.initState();
    _account = _drive.currentUser;
    _drive.onUserChanged.listen((user) {
      if (mounted) setState(() => _account = user);
    });
    _drive.signInSilently().then((user) {
      if (mounted) setState(() => _account = user);
    });
  }

  void _setStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _isError = isError;
    });
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          icon: Icon(
            Icons.check_circle_rounded,
            color: palette.tabBarActive,
            size: 40,
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.commonOk),
            ),
          ],
        );
      },
    );
  }

  Future<T?> _runBusy<T>(Future<T> Function() task) async {
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      return await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- Share sheet backup ----------

  Future<void> _handleShareExport() async {
    final loc = AppLocalizations.of(context);
    await _runBusy(() async {
      try {
        final file = await _service.exportToFile();
        final params = ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          text: loc.backupShareText,
          subject: loc.backupShareSubject,
        );
        final result = await SharePlus.instance.share(params);
        if (!mounted) return;
        if (result.status == ShareResultStatus.dismissed) {
          _setStatus(loc.backupCancelledStatus, isError: true);
        } else {
          await _showSuccessDialog(
            title: loc.backupCompleteTitle,
            message: loc.backupSavedMessage,
          );
        }
      } catch (err) {
        if (mounted) _setStatus(loc.backupFailedStatus(err), isError: true);
      }
    });
  }

  Future<void> _handleFileImport() async {
    final loc = AppLocalizations.of(context);
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      _setStatus(loc.backupFileReadError, isError: true);
      return;
    }
    if (!mounted) return;
    final confirmed = await _confirmRestore();
    if (confirmed != true) return;
    await _runBusy(() async {
      try {
        final outcome = await _service.importFromBytes(bytes);
        if (!mounted) return;
        await context.read<DiaryProvider>().loadTodayEntries();
        if (!mounted) return;
        await _showSuccessDialog(
          title: loc.backupRestoreCompleteTitle,
          message: loc.backupRestoreCompleteMessage(
              outcome.inserted, outcome.updated),
        );
      } catch (err) {
        if (mounted) {
          _setStatus(loc.backupRestoreFailedStatus(err), isError: true);
        }
      }
    });
  }

  // ---------- Google Drive ----------

  Future<void> _handleDriveSignIn() async {
    final loc = AppLocalizations.of(context);
    await _runBusy(() async {
      try {
        final account = await _drive.signIn();
        if (!mounted) return;
        if (account == null) {
          _setStatus(loc.backupDriveSignInCancelledStatus, isError: true);
        } else {
          _setStatus(loc.backupDriveSignedInStatus(account.email));
        }
      } catch (err) {
        if (mounted) {
          _setStatus(loc.backupDriveSignInFailedStatus(err), isError: true);
        }
      }
    });
  }

  Future<void> _handleDriveSignOut() async {
    final loc = AppLocalizations.of(context);
    await _runBusy(() async {
      await _drive.signOut();
      if (mounted) _setStatus(loc.backupDriveSignedOutStatus);
    });
  }

  Future<void> _handleDriveUpload() async {
    final loc = AppLocalizations.of(context);
    await _runBusy(() async {
      try {
        final file = await _drive.uploadBackup();
        if (!mounted) return;
        await _showSuccessDialog(
          title: loc.backupDriveUploadCompleteTitle,
          message: loc.backupDriveUploadCompleteMessage(file.name),
        );
      } catch (err) {
        if (mounted) {
          _setStatus(loc.backupDriveUploadFailedStatus(err), isError: true);
        }
      }
    });
  }

  Future<void> _handleDriveRestoreList() async {
    final loc = AppLocalizations.of(context);
    final files = await _runBusy(() async {
      try {
        return await _drive.listBackups();
      } catch (err) {
        if (mounted) {
          _setStatus(loc.backupDriveListFailedStatus(err), isError: true);
        }
        return null;
      }
    });
    if (files == null || !mounted) return;
    if (files.isEmpty) {
      _setStatus(loc.backupDriveListEmptyStatus, isError: true);
      return;
    }
    final picked = await showModalBottomSheet<DriveBackupFile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<AppPaletteExt>()!.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DriveBackupListSheet(files: files),
    );
    if (picked == null || !mounted) return;
    final confirmed = await _confirmRestore();
    if (confirmed != true) return;
    await _runBusy(() async {
      try {
        final outcome = await _drive.restoreBackup(picked.id);
        if (!mounted) return;
        await context.read<DiaryProvider>().loadTodayEntries();
        if (!mounted) return;
        await _showSuccessDialog(
          title: loc.backupRestoreCompleteTitle,
          message: loc.backupRestoreCompleteMessage(
              outcome.inserted, outcome.updated),
        );
      } catch (err) {
        if (mounted) {
          _setStatus(loc.backupRestoreFailedStatus(err), isError: true);
        }
      }
    });
  }

  Future<bool?> _confirmRestore() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(loc.backupRestoreDialogTitle),
          content: Text(loc.backupRestoreDialogMessage),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(loc.commonCancel)),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(loc.backupRestoreDialogConfirm)),
          ],
        );
      },
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.commonClose,
              style: TextStyle(
                  color: palette.tabBarActive,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        leadingWidth: 64,
        title: Text(loc.backupTitle,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: palette.text)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _infoCard(palette, loc),
                const SizedBox(height: 24),
                _sectionHeader(palette, 'Google Drive'),
                const SizedBox(height: 8),
                _driveAccountCard(palette, loc),
                if (_account != null) ...[
                  const SizedBox(height: 12),
                  _actionTile(
                    palette: palette,
                    icon: Icons.cloud_upload_rounded,
                    title: loc.backupDriveUploadTitle,
                    subtitle: loc.backupDriveUploadSubtitle,
                    onTap: _busy ? null : _handleDriveUpload,
                  ),
                  const SizedBox(height: 12),
                  _actionTile(
                    palette: palette,
                    icon: Icons.cloud_download_rounded,
                    title: loc.backupDriveRestoreTitle,
                    subtitle: loc.backupDriveRestoreSubtitle,
                    onTap: _busy ? null : _handleDriveRestoreList,
                  ),
                ],
                const SizedBox(height: 28),
                _sectionHeader(palette, loc.backupSectionFile),
                const SizedBox(height: 8),
                _actionTile(
                  palette: palette,
                  icon: Icons.ios_share_rounded,
                  title: loc.backupFileExportTitle,
                  subtitle: loc.backupFileExportSubtitle,
                  onTap: _busy ? null : _handleShareExport,
                ),
                const SizedBox(height: 12),
                _actionTile(
                  palette: palette,
                  icon: Icons.folder_open_rounded,
                  title: loc.backupFileImportTitle,
                  subtitle: loc.backupFileImportSubtitle,
                  onTap: _busy ? null : _handleFileImport,
                ),
                const SizedBox(height: 24),
                if (_statusMessage != null) _statusBanner(palette),
              ],
            ),
            if (_busy)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withAlpha(0x1A),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(AppPalette palette, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: palette.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.backupInfoMessage,
              style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  color: palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(AppPalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
              letterSpacing: 0.4)),
    );
  }

  Widget _driveAccountCard(AppPalette palette, AppLocalizations loc) {
    final account = _account;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: account == null
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.tabBarActive.withAlpha(0x1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cloud_off_rounded,
                      color: palette.tabBarActive, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.backupDriveSignedOutTitle,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.text)),
                      const SizedBox(height: 4),
                      Text(loc.backupDriveSignedOutSubtitle,
                          style: TextStyle(
                              fontSize: 12,
                              height: 18 / 12,
                              color: palette.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _handleDriveSignIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.tabBarActive,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(loc.backupDriveSignInButton),
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: palette.tabBarActive.withAlpha(0x1F),
                  backgroundImage: account.photoUrl != null
                      ? NetworkImage(account.photoUrl!)
                      : null,
                  child: account.photoUrl == null
                      ? Icon(Icons.account_circle_rounded,
                          color: palette.tabBarActive, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.displayName ?? account.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.text)),
                      const SizedBox(height: 2),
                      Text(account.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: palette.textSecondary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _handleDriveSignOut,
                  child: Text(loc.backupDriveSignOutButton,
                      style: TextStyle(color: palette.textSecondary)),
                ),
              ],
            ),
    );
  }

  Widget _statusBanner(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (_isError ? const Color(0xFFE74C3C) : palette.tabBarActive)
            .withAlpha(0x18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusMessage!,
        style: TextStyle(
          color: _isError ? const Color(0xFFE74C3C) : palette.text,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _actionTile({
    required AppPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.tabBarActive.withAlpha(0x1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: palette.tabBarActive, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: palette.text)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            height: 18 / 12,
                            color: palette.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriveBackupListSheet extends StatelessWidget {
  final List<DriveBackupFile> files;
  const _DriveBackupListSheet({required this.files});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                loc.backupDriveListSheetTitle(files.length),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.text),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: palette.border),
                itemBuilder: (ctx, i) {
                  final f = files[i];
                  final modified = f.modifiedTime != null
                      ? fmt.format(f.modifiedTime!.toLocal())
                      : loc.backupDriveListNoTime;
                  final sizeKb = f.size != null
                      ? '${(f.size! / 1024).toStringAsFixed(1)} KB'
                      : '';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    leading: Icon(Icons.description_rounded,
                        color: palette.tabBarActive),
                    title: Text(modified,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.text)),
                    subtitle: Text(
                      [f.name, if (sizeKb.isNotEmpty) sizeKb].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: palette.textSecondary),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: palette.textSecondary),
                    onTap: () => Navigator.of(context).pop(f),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

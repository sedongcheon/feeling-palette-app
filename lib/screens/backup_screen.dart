import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/theme.dart';
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
    await _runBusy(() async {
      try {
        final file = await _service.exportToFile();
        final params = ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          text: 'Feeling Palette 일기 백업',
          subject: 'Feeling Palette 백업',
        );
        final result = await SharePlus.instance.share(params);
        if (!mounted) return;
        if (result.status == ShareResultStatus.success) {
          _setStatus('백업 파일이 저장되었습니다.');
        } else if (result.status == ShareResultStatus.dismissed) {
          _setStatus('백업이 취소되었습니다.', isError: true);
        } else {
          _setStatus('백업이 완료되었습니다.');
        }
      } catch (err) {
        if (mounted) _setStatus('백업 실패: $err', isError: true);
      }
    });
  }

  Future<void> _handleFileImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      _setStatus('파일을 읽을 수 없습니다.', isError: true);
      return;
    }
    if (!mounted) return;
    final confirmed = await _confirmRestore();
    if (confirmed != true) return;
    await _runBusy(() async {
      try {
        final outcome = await _service.importFromBytes(bytes);
        if (!mounted) return;
        _setStatus(
          '복원 완료 — 새로 추가 ${outcome.inserted}개, 덮어쓰기 ${outcome.updated}개',
        );
        await context.read<DiaryProvider>().loadTodayEntries();
      } catch (err) {
        if (mounted) _setStatus('복원 실패: $err', isError: true);
      }
    });
  }

  // ---------- Google Drive ----------

  Future<void> _handleDriveSignIn() async {
    await _runBusy(() async {
      try {
        final account = await _drive.signIn();
        if (!mounted) return;
        if (account == null) {
          _setStatus('로그인이 취소되었습니다.', isError: true);
        } else {
          _setStatus('${account.email}(으)로 로그인되었습니다.');
        }
      } catch (err) {
        if (mounted) _setStatus('로그인 실패: $err', isError: true);
      }
    });
  }

  Future<void> _handleDriveSignOut() async {
    await _runBusy(() async {
      await _drive.signOut();
      if (mounted) _setStatus('로그아웃되었습니다.');
    });
  }

  Future<void> _handleDriveUpload() async {
    await _runBusy(() async {
      try {
        final file = await _drive.uploadBackup();
        if (mounted) {
          _setStatus('Drive 업로드 완료: ${file.name}');
        }
      } catch (err) {
        if (mounted) _setStatus('업로드 실패: $err', isError: true);
      }
    });
  }

  Future<void> _handleDriveRestoreList() async {
    final files = await _runBusy(() async {
      try {
        return await _drive.listBackups();
      } catch (err) {
        if (mounted) _setStatus('목록 조회 실패: $err', isError: true);
        return null;
      }
    });
    if (files == null || !mounted) return;
    if (files.isEmpty) {
      _setStatus('Drive에 저장된 백업이 없어요.', isError: true);
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
        _setStatus(
          '복원 완료 — 새로 추가 ${outcome.inserted}개, 덮어쓰기 ${outcome.updated}개',
        );
        await context.read<DiaryProvider>().loadTodayEntries();
      } catch (err) {
        if (mounted) _setStatus('복원 실패: $err', isError: true);
      }
    });
  }

  Future<bool?> _confirmRestore() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('복원'),
        content: const Text(
          '백업의 일기를 가져옵니다.\n같은 ID의 일기는 덮어써집니다. 계속할까요?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('복원')),
        ],
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('닫기',
              style: TextStyle(
                  color: palette.tabBarActive,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        leadingWidth: 64,
        title: Text('백업 / 복원',
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
                _infoCard(palette),
                const SizedBox(height: 24),
                _sectionHeader(palette, 'Google Drive'),
                const SizedBox(height: 8),
                _driveAccountCard(palette),
                if (_account != null) ...[
                  const SizedBox(height: 12),
                  _actionTile(
                    palette: palette,
                    icon: Icons.cloud_upload_rounded,
                    title: 'Drive에 백업',
                    subtitle: '내 Drive의 앱 전용 폴더에 새 백업 파일을 업로드합니다.',
                    onTap: _busy ? null : _handleDriveUpload,
                  ),
                  const SizedBox(height: 12),
                  _actionTile(
                    palette: palette,
                    icon: Icons.cloud_download_rounded,
                    title: 'Drive에서 복원',
                    subtitle: '저장된 백업 목록에서 골라 복원합니다.',
                    onTap: _busy ? null : _handleDriveRestoreList,
                  ),
                ],
                const SizedBox(height: 28),
                _sectionHeader(palette, '파일로 백업 / 복원'),
                const SizedBox(height: 8),
                _actionTile(
                  palette: palette,
                  icon: Icons.ios_share_rounded,
                  title: '파일로 내보내기',
                  subtitle: '공유 시트에서 Drive·iCloud·메일 등에 자유롭게 저장합니다.',
                  onTap: _busy ? null : _handleShareExport,
                ),
                const SizedBox(height: 12),
                _actionTile(
                  palette: palette,
                  icon: Icons.folder_open_rounded,
                  title: '파일에서 복원',
                  subtitle: '기기·Drive·iCloud의 JSON 백업 파일을 선택해서 복원합니다.',
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

  Widget _infoCard(AppPalette palette) {
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
              '데이터는 기기에만 저장됩니다.\n다른 기기로 옮기거나 백업하려면 아래 기능을 사용하세요.',
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

  Widget _driveAccountCard(AppPalette palette) {
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
                      Text('로그인 안 됨',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.text)),
                      const SizedBox(height: 4),
                      Text('Google 계정으로 로그인하면 Drive에 백업할 수 있어요.',
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
                  child: const Text('로그인'),
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
                  child: Text('로그아웃',
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
                'Drive 백업 (${files.length})',
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
                      : '시간 정보 없음';
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

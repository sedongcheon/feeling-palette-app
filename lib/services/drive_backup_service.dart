import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'backup_service.dart';

/// Stored in Drive's hidden `appDataFolder` so backups are tied to the user's
/// Google account but are invisible from the regular Drive UI and cannot be
/// modified by other apps.
const String _appDataSpace = 'appDataFolder';
const String _backupMimeType = 'application/json';
const String _filenamePrefix = 'feeling-palette-backup-';

class DriveBackupFile {
  final String id;
  final String name;
  final DateTime? modifiedTime;
  final int? size;

  const DriveBackupFile({
    required this.id,
    required this.name,
    this.modifiedTime,
    this.size,
  });
}

class DriveBackupService {
  DriveBackupService({BackupService? backup, GoogleSignIn? signIn})
      : _backup = backup ?? BackupService(),
        _signIn = signIn ??
            GoogleSignIn(scopes: const [drive.DriveApi.driveAppdataScope]);

  final BackupService _backup;
  final GoogleSignIn _signIn;

  GoogleSignInAccount? get currentUser => _signIn.currentUser;
  Stream<GoogleSignInAccount?> get onUserChanged => _signIn.onCurrentUserChanged;

  Future<GoogleSignInAccount?> signInSilently() async {
    return _signIn.signInSilently(suppressErrors: true);
  }

  Future<GoogleSignInAccount?> signIn() async {
    return _signIn.signIn();
  }

  Future<void> signOut() => _signIn.signOut();

  Future<drive.DriveApi> _driveApi() async {
    final account = _signIn.currentUser ?? await _signIn.signIn();
    if (account == null) {
      throw StateError('Google 계정에 로그인하지 않았습니다.');
    }
    final client = await _signIn.authenticatedClient();
    if (client == null) {
      throw StateError('Google 인증 토큰을 받을 수 없습니다.');
    }
    return drive.DriveApi(client);
  }

  /// Generates the current backup payload and uploads it as a new file.
  Future<DriveBackupFile> uploadBackup() async {
    final api = await _driveApi();
    final localFile = await _backup.exportToFile();
    final bytes = await localFile.readAsBytes();

    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final name = '$_filenamePrefix$ts.json';

    final media = drive.Media(Stream.value(bytes), bytes.length,
        contentType: _backupMimeType);
    final created = await api.files.create(
      drive.File()
        ..name = name
        ..parents = [_appDataSpace]
        ..mimeType = _backupMimeType,
      uploadMedia: media,
    );

    return DriveBackupFile(
      id: created.id ?? '',
      name: created.name ?? name,
      modifiedTime: created.modifiedTime,
      size: bytes.length,
    );
  }

  /// Lists existing backup files in the appDataFolder, newest first.
  Future<List<DriveBackupFile>> listBackups({int pageSize = 50}) async {
    final api = await _driveApi();
    final result = await api.files.list(
      spaces: _appDataSpace,
      orderBy: 'modifiedTime desc',
      pageSize: pageSize,
      $fields: 'files(id,name,modifiedTime,size)',
    );
    final files = result.files ?? const <drive.File>[];
    return files
        .where((f) => (f.name ?? '').startsWith(_filenamePrefix))
        .map((f) => DriveBackupFile(
              id: f.id ?? '',
              name: f.name ?? '',
              modifiedTime: f.modifiedTime,
              size: int.tryParse(f.size ?? ''),
            ))
        .toList();
  }

  Future<BackupResult> restoreBackup(String fileId) async {
    final api = await _driveApi();
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final bytes = await _readMedia(media);
    return _backup.importFromBytes(bytes);
  }

  Future<void> deleteBackup(String fileId) async {
    final api = await _driveApi();
    await api.files.delete(fileId);
  }

  Future<List<int>> _readMedia(drive.Media media) async {
    final bytesBuilder = BytesBuilder();
    await for (final chunk in media.stream) {
      bytesBuilder.add(chunk);
    }
    return bytesBuilder.takeBytes();
  }
}

/// Returns a human-readable description of the JSON payload (for UI).
String describeBackup(List<int> bytes) {
  try {
    final parsed = jsonDecode(utf8.decode(bytes));
    if (parsed is Map<String, dynamic>) {
      final count = parsed['count'];
      if (count is num) return '$count개 일기';
    }
  } catch (_) {}
  return '백업 파일';
}

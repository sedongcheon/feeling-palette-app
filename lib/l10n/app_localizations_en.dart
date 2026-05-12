// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Feeling Palette';

  @override
  String emotionLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'joy': 'Joy',
      'sadness': 'Sadness',
      'anger': 'Anger',
      'anxiety': 'Anxiety',
      'calm': 'Calm',
      'excitement': 'Excitement',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get backupTitle => 'Backup / Restore';

  @override
  String get backupInfoMessage =>
      'Data is stored only on this device.\nUse the options below to move or back up your data.';

  @override
  String get backupSectionFile => 'File backup / restore';

  @override
  String get backupDriveUploadTitle => 'Back up to Drive';

  @override
  String get backupDriveUploadSubtitle =>
      'Upload a new backup file to your Drive app folder.';

  @override
  String get backupDriveRestoreTitle => 'Restore from Drive';

  @override
  String get backupDriveRestoreSubtitle =>
      'Pick from your saved backups to restore.';

  @override
  String get backupFileExportTitle => 'Export as file';

  @override
  String get backupFileExportSubtitle =>
      'Use the share sheet to save to Drive, iCloud, mail, and more.';

  @override
  String get backupFileImportTitle => 'Restore from file';

  @override
  String get backupFileImportSubtitle =>
      'Pick a JSON backup file from your device, Drive, or iCloud.';

  @override
  String get backupDriveSignedOutTitle => 'Not signed in';

  @override
  String get backupDriveSignedOutSubtitle =>
      'Sign in with Google to back up to Drive.';

  @override
  String get backupDriveSignInButton => 'Sign in';

  @override
  String get backupDriveSignOutButton => 'Sign out';

  @override
  String get backupRestoreDialogTitle => 'Restore';

  @override
  String get backupRestoreDialogMessage =>
      'Diary entries from the backup will be imported.\nEntries with the same ID will be overwritten. Continue?';

  @override
  String get backupRestoreDialogConfirm => 'Restore';

  @override
  String get backupShareText => 'Feeling Palette diary backup';

  @override
  String get backupShareSubject => 'Feeling Palette backup';

  @override
  String get backupCancelledStatus => 'Backup was cancelled.';

  @override
  String get backupCompleteTitle => 'Backup complete';

  @override
  String get backupSavedMessage => 'The backup file was saved.';

  @override
  String backupFailedStatus(Object error) {
    return 'Backup failed: $error';
  }

  @override
  String get backupFileReadError => 'Cannot read the file.';

  @override
  String get backupRestoreCompleteTitle => 'Restore complete';

  @override
  String backupRestoreCompleteMessage(int inserted, int updated) {
    return 'Added $inserted, overwritten $updated';
  }

  @override
  String backupRestoreFailedStatus(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get backupDriveSignInCancelledStatus => 'Sign-in was cancelled.';

  @override
  String backupDriveSignedInStatus(String email) {
    return 'Signed in as $email.';
  }

  @override
  String backupDriveSignInFailedStatus(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get backupDriveSignedOutStatus => 'Signed out.';

  @override
  String get backupDriveUploadCompleteTitle => 'Drive backup complete';

  @override
  String backupDriveUploadCompleteMessage(String filename) {
    return 'Saved as $filename.';
  }

  @override
  String backupDriveUploadFailedStatus(Object error) {
    return 'Upload failed: $error';
  }

  @override
  String backupDriveListFailedStatus(Object error) {
    return 'Failed to load list: $error';
  }

  @override
  String get backupDriveListEmptyStatus => 'No backups saved on Drive.';

  @override
  String backupDriveListSheetTitle(int count) {
    return 'Drive backups ($count)';
  }

  @override
  String get backupDriveListNoTime => 'No timestamp';
}

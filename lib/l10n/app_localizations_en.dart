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
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppLock => 'App lock';

  @override
  String get settingsSectionPurchase => 'Purchase';

  @override
  String get settingsAutoLockTitle => 'Auto-lock';

  @override
  String get settingsAutoLockDescription =>
      'After leaving the app, the lock screen returns once this time has passed.';

  @override
  String autoLockDelayLabel(String seconds) {
    String _temp0 = intl.Intl.selectLogic(seconds, {
      '0': 'Immediately',
      '5': '5 sec',
      '30': '30 sec',
      '60': '1 min',
      '300': '5 min',
      '600': '10 min',
      'other': '$seconds sec',
    });
    return '$_temp0';
  }

  @override
  String get settingsRemoveAdsTitle => 'Remove ads';

  @override
  String get settingsRemoveAdsPurchased =>
      'Purchased — banner and interstitial ads are hidden.';

  @override
  String get settingsRemoveAdsDescription =>
      'Use the app without banner or interstitial ads.\n(Reward ads remain available for bonus analyses.)';

  @override
  String get settingsRemoveAdsPurchasedButton => 'Purchased';

  @override
  String settingsBuyAtPrice(String price) {
    return 'Buy for $price';
  }

  @override
  String get settingsStoreUnavailable => 'Cannot reach the store';

  @override
  String get settingsLoadFailedRetry => 'Failed to load purchase info · Retry';

  @override
  String get settingsLoadingPurchaseInfo => 'Loading purchase info…';

  @override
  String get settingsPurchaseStartFailed =>
      'Cannot start the purchase right now. Please try again later.';

  @override
  String get settingsRestoreButton => 'Restore purchases';

  @override
  String get settingsRestoreSuccess => 'Purchases restored.';

  @override
  String get settingsRestoreNothing => 'No purchases to restore.';

  @override
  String get todayEntryEditTooltip => 'Edit';

  @override
  String get todayEntryDeleteTooltip => 'Delete';

  @override
  String get todayEntryAnalyzing => 'AI is analyzing emotions…';

  @override
  String todayEntryMaxAnalysisHit(int max) {
    return 'AI analysis is limited to $max times per entry.';
  }

  @override
  String todayEntryDailyLimitHit(int limit) {
    return 'You\'ve used today\'s AI analysis limit ($limit).';
  }

  @override
  String todayEntryAnalysisCompleteMaxed(
    int max,
    int dailyUsed,
    int dailyLimit,
  ) {
    return 'Analysis complete! All $max/$max analyses used for this entry. (Today $dailyUsed/$dailyLimit)';
  }

  @override
  String todayEntryAnalysisComplete(
    int used,
    int max,
    int remaining,
    int dailyUsed,
    int dailyLimit,
  ) {
    return 'Analysis complete! ($used/$max used, $remaining remaining · today $dailyUsed/$dailyLimit)';
  }

  @override
  String get todayEntryAnalysisErrorTitle => 'Analysis error';

  @override
  String get todayEntryAnalysisErrorMessage => 'Please try again later.';

  @override
  String get todayEntryEmptyContent => 'Please enter your diary content.';

  @override
  String todayEntryAnalysisLocked(int max) {
    return 'All $max analyses used; the previous result is kept.';
  }

  @override
  String get todayEntryDeleteDialogTitle => 'Delete diary';

  @override
  String get todayEntryDeleteDialogMessage =>
      'Delete this diary?\nThis cannot be undone.';

  @override
  String get todayEntryAnalyzeCapHit => 'All analyses used';

  @override
  String todayEntryBonusAdButton(int bonus, int remaining) {
    return 'Watch an ad to unlock +$bonus analyses ($remaining left)';
  }

  @override
  String get todayEntryDailyLimitButton => 'Today\'s AI analysis limit reached';

  @override
  String todayEntryAnalyzeButton(int remaining, int max) {
    return 'AI emotion analysis ($remaining/$max)';
  }

  @override
  String todayEntryBonusUnlocked(int bonus) {
    return '+$bonus analyses unlocked!';
  }

  @override
  String get todayEntryBonusAdIncomplete =>
      'Watch the full ad to receive the reward.';
}

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
  String get settingsAppLockToggleTitle => 'Use app lock';

  @override
  String get settingsAppLockToggleDescriptionOff =>
      'Protect your journal with a PIN and biometrics';

  @override
  String get settingsAppLockToggleDescriptionOn =>
      'Protected with PIN and biometrics';

  @override
  String get settingsAppLockDisableTitle => 'Disable app lock?';

  @override
  String get settingsAppLockDisableBody =>
      'Your PIN and biometric settings will be removed. Journal entries remain untouched.';

  @override
  String get settingsAppLockDisableConfirm => 'Disable';

  @override
  String get settingsAppLockDisableCancel => 'Cancel';

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

  @override
  String get commonTryAgainLater => 'Please try again later.';

  @override
  String get statsTitle => 'Emotion stats';

  @override
  String get statsEmpty =>
      'No analyzed diaries yet this month.\nWrite a diary entry to see emotion stats.';

  @override
  String get statsDistributionTitle => 'Emotion distribution (daily average)';

  @override
  String get statsTop3Title => 'Top 3 emotions this month';

  @override
  String get statsTrendTitle => 'Emotion trend';

  @override
  String get statsMonthSummaryTitle => 'Monthly summary';

  @override
  String get statsMonthAiSummaryTitle => 'Monthly AI summary';

  @override
  String statsDistributionRow(int days, int percent) {
    return '$days days ($percent%)';
  }

  @override
  String statsTopRowCount(int count) {
    return '$count days';
  }

  @override
  String statsMonthSummaryText(
    int totalDays,
    int totalEntries,
    String emotion,
    int days,
    int percent,
  ) {
    return 'Across $totalDays days ($totalEntries entries total) this month, \'$emotion\' was felt most. ($days days, $percent%)';
  }

  @override
  String get statsSummaryErrorTitle => 'Summary generation failed';

  @override
  String get statsSummaryAdIncomplete =>
      'Ad viewing was not completed, so the summary couldn\'t be created.';

  @override
  String get statsSummaryQuotaHit =>
      'You\'ve used today\'s summary quota. Please try again tomorrow.';

  @override
  String get statsSummaryNotEnoughData =>
      'No analyzed diaries this month — not enough content to summarize.';

  @override
  String statsSummaryQuotaBadge(int available, int budget, int entriesToNext) {
    return '$available/$budget summaries left this month · $entriesToNext more diaries to earn +1';
  }

  @override
  String get statsSummaryFreeCreate => 'Create AI summary (free)';

  @override
  String get statsSummaryFreeRegen => 'Regenerate summary (free)';

  @override
  String get statsSummaryAdCreate => 'Watch ad to create AI summary';

  @override
  String get statsSummaryAdRegen => 'Watch ad to regenerate summary';

  @override
  String get statsSummaryAllUsed => 'This month\'s summary quota used up';

  @override
  String get weeklyInsightTitle => 'This week\'s insight';

  @override
  String get weeklyInsightCareTitle => 'Take a little extra care this week';

  @override
  String get weeklyInsightEmptyReady =>
      'We can find patterns from your recent entries.\nShall we create your first insight?';

  @override
  String get weeklyInsightEmptyNeedMore =>
      'Once a few more entries are in, we\'ll share your recent emotional flow.\nKeep writing a little more?';

  @override
  String get weeklyInsightCreateFirst => 'Create first insight';

  @override
  String get weeklyInsightRefresh => 'Refresh';

  @override
  String get weeklyInsightRefreshable => 'Ready to refresh';

  @override
  String get weeklyInsightWaitingRefresh => 'Waiting for weekly refresh';

  @override
  String weeklyInsightRefreshIn(int days) {
    return 'Refreshes in $days days';
  }

  @override
  String weeklyInsightDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String weeklyInsightTrendLabel(String trend) {
    String _temp0 = intl.Intl.selectLogic(trend, {
      'up': 'Up',
      'down': 'Down',
      'stable': 'Stable',
      'mixed': 'Mixed',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get weeklyInsightGenerating => 'Generating…';

  @override
  String weeklyInsightAdLabel(String base) {
    return 'Watch ad: $base';
  }

  @override
  String get weeklyInsightMonthlyLimit => 'Monthly quota used up';

  @override
  String get weeklyInsightCreatedToast => 'Created this week\'s insight.';

  @override
  String get weeklyInsightCooldownError => 'It\'s not time to refresh yet.';

  @override
  String get weeklyInsightQuotaError => 'You\'ve used this month\'s quota.';

  @override
  String get weeklyInsightAdError => 'Watch the full ad to generate.';

  @override
  String get weeklyInsightNotEnoughData =>
      'Not quite enough entries to find a pattern.';

  @override
  String get weeklyInsightGenericError =>
      'Something went wrong while generating.';

  @override
  String homeDateHeading(String dateLabel, String dayLabel) {
    return '$dateLabel, $dayLabel';
  }

  @override
  String get homeTodayHeading => 'How was your day?';

  @override
  String get homeEntrySavedToast => 'Today\'s diary entry was saved.';

  @override
  String get homeTodayEntries => 'Today\'s entries';

  @override
  String get homeComposerHint => 'Write freely about your day and feelings…';

  @override
  String get homeAddEntryButton => 'Add entry';

  @override
  String homeDailyQuotaBadge(int used, int max) {
    return 'AI analyses $used/$max';
  }

  @override
  String get mainTabToday => 'Today';

  @override
  String get mainTabCalendar => 'Calendar';

  @override
  String get mainTabStats => 'Stats';

  @override
  String get mainTabTimeline => 'Timeline';

  @override
  String get pinSetupTitle => 'Set new password';

  @override
  String get pinSetupRepeat => 'Please enter it once more';

  @override
  String get pinSetupHelp4Digit => 'Enter a 4-digit number';

  @override
  String get pinSetupHelpRepeat => 'Enter the same number to confirm';

  @override
  String get pinSetupMismatch => 'Passwords don\'t match. Please set it again.';

  @override
  String get pinBiometricTitle => 'Use biometric authentication?';

  @override
  String get pinBiometricDescription =>
      'Unlock more quickly with fingerprint or Face ID.\nYou can change this anytime in Settings.';

  @override
  String get pinBiometricEnable => 'Use it';

  @override
  String get pinBiometricSkip => 'Password only';

  @override
  String get lockTitle => 'Enter password';

  @override
  String get lockHelp => 'Please enter your 4-digit password';

  @override
  String get lockMismatchError => 'Passwords don\'t match';

  @override
  String get lockForgotPin => 'Forgot your password?';

  @override
  String get lockResetTitle => 'Reset data';

  @override
  String get lockResetMessage =>
      'Your password cannot be recovered, so all data will be deleted.\nReally reset?';

  @override
  String get lockResetButton => 'Reset';

  @override
  String get lockBiometricReason => 'Unlock with biometric authentication';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get timelineEmpty =>
      'No diary entries yet.\nRecord today\'s emotions.';

  @override
  String get timelineEndReached => 'Loaded all entries';

  @override
  String get calendarTitle => 'Emotion calendar';

  @override
  String get calendarTapHint => 'Tap a date to see the diary';

  @override
  String get calendarNoEntryForDate => 'No diary entries on this day';

  @override
  String get diaryDetailTitle => 'Diary detail';

  @override
  String get diaryDetailNotFound => 'Diary not found';

  @override
  String get weeklyLineChartHint =>
      'The chart appears when 2+ days of analyzed data are available';

  @override
  String dayAverageHeader(int month, int day) {
    return '$month/$day average';
  }

  @override
  String dayAverageEntryCount(int count) {
    return '$count entries';
  }

  @override
  String get donutChartDaysUnit => 'days';

  @override
  String driveBackupFileEntryCount(int count) {
    return '$count entries';
  }

  @override
  String get driveBackupDefaultName => 'Backup file';

  @override
  String datePartWithDay(String datePart, String dayPart) {
    return '$datePart $dayPart';
  }
}

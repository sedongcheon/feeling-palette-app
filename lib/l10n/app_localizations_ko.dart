// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Feeling Palette';

  @override
  String emotionLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'joy': '기쁨',
      'sadness': '슬픔',
      'anger': '분노',
      'anxiety': '불안',
      'calm': '평온',
      'excitement': '설렘',
      'other': '알 수 없음',
    });
    return '$_temp0';
  }

  @override
  String get commonOk => '확인';

  @override
  String get commonCancel => '취소';

  @override
  String get commonClose => '닫기';

  @override
  String get commonSave => '저장';

  @override
  String get commonDelete => '삭제';

  @override
  String get backupTitle => '백업 / 복원';

  @override
  String get backupInfoMessage =>
      '데이터는 기기에만 저장됩니다.\n다른 기기로 옮기거나 백업하려면 아래 기능을 사용하세요.';

  @override
  String get backupSectionFile => '파일로 백업 / 복원';

  @override
  String get backupDriveUploadTitle => 'Drive에 백업';

  @override
  String get backupDriveUploadSubtitle => '내 Drive의 앱 전용 폴더에 새 백업 파일을 업로드합니다.';

  @override
  String get backupDriveRestoreTitle => 'Drive에서 복원';

  @override
  String get backupDriveRestoreSubtitle => '저장된 백업 목록에서 골라 복원합니다.';

  @override
  String get backupFileExportTitle => '파일로 내보내기';

  @override
  String get backupFileExportSubtitle =>
      '공유 시트에서 Drive·iCloud·메일 등에 자유롭게 저장합니다.';

  @override
  String get backupFileImportTitle => '파일에서 복원';

  @override
  String get backupFileImportSubtitle =>
      '기기·Drive·iCloud의 JSON 백업 파일을 선택해서 복원합니다.';

  @override
  String get backupDriveSignedOutTitle => '로그인 안 됨';

  @override
  String get backupDriveSignedOutSubtitle =>
      'Google 계정으로 로그인하면 Drive에 백업할 수 있어요.';

  @override
  String get backupDriveSignInButton => '로그인';

  @override
  String get backupDriveSignOutButton => '로그아웃';

  @override
  String get backupRestoreDialogTitle => '복원';

  @override
  String get backupRestoreDialogMessage =>
      '백업의 일기를 가져옵니다.\n같은 ID의 일기는 덮어써집니다. 계속할까요?';

  @override
  String get backupRestoreDialogConfirm => '복원';

  @override
  String get backupShareText => 'Feeling Palette 일기 백업';

  @override
  String get backupShareSubject => 'Feeling Palette 백업';

  @override
  String get backupCancelledStatus => '백업이 취소되었습니다.';

  @override
  String get backupCompleteTitle => '백업 완료';

  @override
  String get backupSavedMessage => '백업 파일이 저장되었어요.';

  @override
  String backupFailedStatus(Object error) {
    return '백업 실패: $error';
  }

  @override
  String get backupFileReadError => '파일을 읽을 수 없습니다.';

  @override
  String get backupRestoreCompleteTitle => '복원 완료';

  @override
  String backupRestoreCompleteMessage(int inserted, int updated) {
    return '새로 추가 $inserted개, 덮어쓰기 $updated개';
  }

  @override
  String backupRestoreFailedStatus(Object error) {
    return '복원 실패: $error';
  }

  @override
  String get backupDriveSignInCancelledStatus => '로그인이 취소되었습니다.';

  @override
  String backupDriveSignedInStatus(String email) {
    return '$email(으)로 로그인되었습니다.';
  }

  @override
  String backupDriveSignInFailedStatus(Object error) {
    return '로그인 실패: $error';
  }

  @override
  String get backupDriveSignedOutStatus => '로그아웃되었습니다.';

  @override
  String get backupDriveUploadCompleteTitle => 'Drive 백업 완료';

  @override
  String backupDriveUploadCompleteMessage(String filename) {
    return '$filename 파일로 저장되었어요.';
  }

  @override
  String backupDriveUploadFailedStatus(Object error) {
    return '업로드 실패: $error';
  }

  @override
  String backupDriveListFailedStatus(Object error) {
    return '목록 조회 실패: $error';
  }

  @override
  String get backupDriveListEmptyStatus => 'Drive에 저장된 백업이 없어요.';

  @override
  String backupDriveListSheetTitle(int count) {
    return 'Drive 백업 ($count)';
  }

  @override
  String get backupDriveListNoTime => '시간 정보 없음';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionAppLock => '앱 잠금';

  @override
  String get settingsSectionPurchase => '구매';

  @override
  String get settingsAutoLockTitle => '자동 잠금';

  @override
  String get settingsAutoLockDescription => '앱을 벗어난 뒤 이 시간이 지나면 잠금 화면이 다시 뜹니다.';

  @override
  String autoLockDelayLabel(String seconds) {
    String _temp0 = intl.Intl.selectLogic(seconds, {
      '0': '즉시',
      '5': '5초',
      '30': '30초',
      '60': '1분',
      '300': '5분',
      '600': '10분',
      'other': '$seconds초',
    });
    return '$_temp0';
  }

  @override
  String get settingsRemoveAdsTitle => '광고 제거';

  @override
  String get settingsRemoveAdsPurchased => '구매 완료 — 배너와 전면 광고가 표시되지 않아요.';

  @override
  String get settingsRemoveAdsDescription =>
      '배너 · 전면 광고 없이 쾌적하게 사용할 수 있어요.\n(리워드 광고는 보너스 분석 획득에 계속 사용 가능합니다.)';

  @override
  String get settingsRemoveAdsPurchasedButton => '구매 완료';

  @override
  String settingsBuyAtPrice(String price) {
    return '$price에 구매하기';
  }

  @override
  String get settingsStoreUnavailable => '스토어에 연결할 수 없어요';

  @override
  String get settingsLoadFailedRetry => '구매 정보를 불러오지 못했어요 · 다시 시도';

  @override
  String get settingsLoadingPurchaseInfo => '구매 정보 불러오는 중…';

  @override
  String get settingsPurchaseStartFailed =>
      '지금은 구매를 시작할 수 없어요. 잠시 후 다시 시도해주세요.';

  @override
  String get settingsRestoreButton => '구매 복원';

  @override
  String get settingsRestoreSuccess => '구매 내역이 복원되었어요.';

  @override
  String get settingsRestoreNothing => '복원할 구매 내역이 없어요.';

  @override
  String get todayEntryEditTooltip => '수정';

  @override
  String get todayEntryDeleteTooltip => '삭제';

  @override
  String get todayEntryAnalyzing => 'AI가 감정을 분석하고 있어요...';

  @override
  String todayEntryMaxAnalysisHit(int max) {
    return 'AI 분석은 일기당 최대 $max회까지 가능해요.';
  }

  @override
  String todayEntryDailyLimitHit(int limit) {
    return '오늘 AI 분석 한도($limit개)를 모두 사용했어요.';
  }

  @override
  String todayEntryAnalysisCompleteMaxed(
    int max,
    int dailyUsed,
    int dailyLimit,
  ) {
    return '분석 완료! 이번 일기의 분석 횟수($max/$max)를 모두 사용했어요. (오늘 $dailyUsed/$dailyLimit)';
  }

  @override
  String todayEntryAnalysisComplete(
    int used,
    int max,
    int remaining,
    int dailyUsed,
    int dailyLimit,
  ) {
    return '분석 완료! ($used/$max회 사용, 남은 횟수 $remaining · 오늘 $dailyUsed/$dailyLimit)';
  }

  @override
  String get todayEntryAnalysisErrorTitle => '분석 오류';

  @override
  String get todayEntryAnalysisErrorMessage => '잠시 후 다시 시도해주세요.';

  @override
  String get todayEntryEmptyContent => '일기 내용을 입력해주세요.';

  @override
  String todayEntryAnalysisLocked(int max) {
    return '분석 횟수($max회)를 모두 사용해 이전 분석 결과가 유지돼요.';
  }

  @override
  String get todayEntryDeleteDialogTitle => '일기 삭제';

  @override
  String get todayEntryDeleteDialogMessage => '이 일기를 삭제할까요?\n삭제하면 되돌릴 수 없어요.';

  @override
  String get todayEntryAnalyzeCapHit => '분석 횟수를 모두 사용했어요';

  @override
  String todayEntryBonusAdButton(int bonus, int remaining) {
    return '광고 보고 AI 분석 +$bonus 언락 (남은 시청 $remaining회)';
  }

  @override
  String get todayEntryDailyLimitButton => '오늘 AI 분석 한도를 모두 사용했어요';

  @override
  String todayEntryAnalyzeButton(int remaining, int max) {
    return 'AI 감정 분석 ($remaining/$max)';
  }

  @override
  String todayEntryBonusUnlocked(int bonus) {
    return 'AI 분석 +$bonus개가 언락되었어요!';
  }

  @override
  String get todayEntryBonusAdIncomplete => '광고를 끝까지 시청해야 보상을 받을 수 있어요.';
}

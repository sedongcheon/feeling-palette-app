import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 타이틀 (MaterialApp title)
  ///
  /// In ko, this message translates to:
  /// **'Feeling Palette'**
  String get appTitle;

  /// 감정 라벨 — EmotionType enum의 name과 매칭
  ///
  /// In ko, this message translates to:
  /// **'{type, select, joy{기쁨} sadness{슬픔} anger{분노} anxiety{불안} calm{평온} excitement{설렘} other{알 수 없음}}'**
  String emotionLabel(String type);

  /// 공통: 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonOk;

  /// 공통: 취소 버튼
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// 공통: 닫기 버튼
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// 공통: 저장 버튼
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// 공통: 삭제 버튼
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @backupTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 / 복원'**
  String get backupTitle;

  /// No description provided for @backupInfoMessage.
  ///
  /// In ko, this message translates to:
  /// **'데이터는 기기에만 저장됩니다.\n다른 기기로 옮기거나 백업하려면 아래 기능을 사용하세요.'**
  String get backupInfoMessage;

  /// No description provided for @backupSectionFile.
  ///
  /// In ko, this message translates to:
  /// **'파일로 백업 / 복원'**
  String get backupSectionFile;

  /// No description provided for @backupDriveUploadTitle.
  ///
  /// In ko, this message translates to:
  /// **'Drive에 백업'**
  String get backupDriveUploadTitle;

  /// No description provided for @backupDriveUploadSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'내 Drive의 앱 전용 폴더에 새 백업 파일을 업로드합니다.'**
  String get backupDriveUploadSubtitle;

  /// No description provided for @backupDriveRestoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'Drive에서 복원'**
  String get backupDriveRestoreTitle;

  /// No description provided for @backupDriveRestoreSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'저장된 백업 목록에서 골라 복원합니다.'**
  String get backupDriveRestoreSubtitle;

  /// No description provided for @backupFileExportTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일로 내보내기'**
  String get backupFileExportTitle;

  /// No description provided for @backupFileExportSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'공유 시트에서 Drive·iCloud·메일 등에 자유롭게 저장합니다.'**
  String get backupFileExportSubtitle;

  /// No description provided for @backupFileImportTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일에서 복원'**
  String get backupFileImportTitle;

  /// No description provided for @backupFileImportSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'기기·Drive·iCloud의 JSON 백업 파일을 선택해서 복원합니다.'**
  String get backupFileImportSubtitle;

  /// No description provided for @backupDriveSignedOutTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인 안 됨'**
  String get backupDriveSignedOutTitle;

  /// No description provided for @backupDriveSignedOutSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'Google 계정으로 로그인하면 Drive에 백업할 수 있어요.'**
  String get backupDriveSignedOutSubtitle;

  /// No description provided for @backupDriveSignInButton.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get backupDriveSignInButton;

  /// No description provided for @backupDriveSignOutButton.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get backupDriveSignOutButton;

  /// No description provided for @backupRestoreDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'복원'**
  String get backupRestoreDialogTitle;

  /// No description provided for @backupRestoreDialogMessage.
  ///
  /// In ko, this message translates to:
  /// **'백업의 일기를 가져옵니다.\n같은 ID의 일기는 덮어써집니다. 계속할까요?'**
  String get backupRestoreDialogMessage;

  /// No description provided for @backupRestoreDialogConfirm.
  ///
  /// In ko, this message translates to:
  /// **'복원'**
  String get backupRestoreDialogConfirm;

  /// No description provided for @backupShareText.
  ///
  /// In ko, this message translates to:
  /// **'Feeling Palette 일기 백업'**
  String get backupShareText;

  /// No description provided for @backupShareSubject.
  ///
  /// In ko, this message translates to:
  /// **'Feeling Palette 백업'**
  String get backupShareSubject;

  /// No description provided for @backupCancelledStatus.
  ///
  /// In ko, this message translates to:
  /// **'백업이 취소되었습니다.'**
  String get backupCancelledStatus;

  /// No description provided for @backupCompleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 완료'**
  String get backupCompleteTitle;

  /// No description provided for @backupSavedMessage.
  ///
  /// In ko, this message translates to:
  /// **'백업 파일이 저장되었어요.'**
  String get backupSavedMessage;

  /// No description provided for @backupFailedStatus.
  ///
  /// In ko, this message translates to:
  /// **'백업 실패: {error}'**
  String backupFailedStatus(Object error);

  /// No description provided for @backupFileReadError.
  ///
  /// In ko, this message translates to:
  /// **'파일을 읽을 수 없습니다.'**
  String get backupFileReadError;

  /// No description provided for @backupRestoreCompleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'복원 완료'**
  String get backupRestoreCompleteTitle;

  /// No description provided for @backupRestoreCompleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'새로 추가 {inserted}개, 덮어쓰기 {updated}개'**
  String backupRestoreCompleteMessage(int inserted, int updated);

  /// No description provided for @backupRestoreFailedStatus.
  ///
  /// In ko, this message translates to:
  /// **'복원 실패: {error}'**
  String backupRestoreFailedStatus(Object error);

  /// No description provided for @backupDriveSignInCancelledStatus.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 취소되었습니다.'**
  String get backupDriveSignInCancelledStatus;

  /// No description provided for @backupDriveSignedInStatus.
  ///
  /// In ko, this message translates to:
  /// **'{email}(으)로 로그인되었습니다.'**
  String backupDriveSignedInStatus(String email);

  /// No description provided for @backupDriveSignInFailedStatus.
  ///
  /// In ko, this message translates to:
  /// **'로그인 실패: {error}'**
  String backupDriveSignInFailedStatus(Object error);

  /// No description provided for @backupDriveSignedOutStatus.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃되었습니다.'**
  String get backupDriveSignedOutStatus;

  /// No description provided for @backupDriveUploadCompleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'Drive 백업 완료'**
  String get backupDriveUploadCompleteTitle;

  /// No description provided for @backupDriveUploadCompleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{filename} 파일로 저장되었어요.'**
  String backupDriveUploadCompleteMessage(String filename);

  /// No description provided for @backupDriveUploadFailedStatus.
  ///
  /// In ko, this message translates to:
  /// **'업로드 실패: {error}'**
  String backupDriveUploadFailedStatus(Object error);

  /// No description provided for @backupDriveListFailedStatus.
  ///
  /// In ko, this message translates to:
  /// **'목록 조회 실패: {error}'**
  String backupDriveListFailedStatus(Object error);

  /// No description provided for @backupDriveListEmptyStatus.
  ///
  /// In ko, this message translates to:
  /// **'Drive에 저장된 백업이 없어요.'**
  String get backupDriveListEmptyStatus;

  /// No description provided for @backupDriveListSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'Drive 백업 ({count})'**
  String backupDriveListSheetTitle(int count);

  /// No description provided for @backupDriveListNoTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 정보 없음'**
  String get backupDriveListNoTime;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAppLock.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금'**
  String get settingsSectionAppLock;

  /// No description provided for @settingsSectionPurchase.
  ///
  /// In ko, this message translates to:
  /// **'구매'**
  String get settingsSectionPurchase;

  /// No description provided for @settingsAutoLockTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 잠금'**
  String get settingsAutoLockTitle;

  /// No description provided for @settingsAutoLockDescription.
  ///
  /// In ko, this message translates to:
  /// **'앱을 벗어난 뒤 이 시간이 지나면 잠금 화면이 다시 뜹니다.'**
  String get settingsAutoLockDescription;

  /// No description provided for @autoLockDelayLabel.
  ///
  /// In ko, this message translates to:
  /// **'{seconds, select, 0{즉시} 5{5초} 30{30초} 60{1분} 300{5분} 600{10분} other{{seconds}초}}'**
  String autoLockDelayLabel(String seconds);

  /// No description provided for @settingsRemoveAdsTitle.
  ///
  /// In ko, this message translates to:
  /// **'광고 제거'**
  String get settingsRemoveAdsTitle;

  /// No description provided for @settingsRemoveAdsPurchased.
  ///
  /// In ko, this message translates to:
  /// **'구매 완료 — 배너와 전면 광고가 표시되지 않아요.'**
  String get settingsRemoveAdsPurchased;

  /// No description provided for @settingsRemoveAdsDescription.
  ///
  /// In ko, this message translates to:
  /// **'배너 · 전면 광고 없이 쾌적하게 사용할 수 있어요.\n(리워드 광고는 보너스 분석 획득에 계속 사용 가능합니다.)'**
  String get settingsRemoveAdsDescription;

  /// No description provided for @settingsRemoveAdsPurchasedButton.
  ///
  /// In ko, this message translates to:
  /// **'구매 완료'**
  String get settingsRemoveAdsPurchasedButton;

  /// No description provided for @settingsBuyAtPrice.
  ///
  /// In ko, this message translates to:
  /// **'{price}에 구매하기'**
  String settingsBuyAtPrice(String price);

  /// No description provided for @settingsStoreUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'스토어에 연결할 수 없어요'**
  String get settingsStoreUnavailable;

  /// No description provided for @settingsLoadFailedRetry.
  ///
  /// In ko, this message translates to:
  /// **'구매 정보를 불러오지 못했어요 · 다시 시도'**
  String get settingsLoadFailedRetry;

  /// No description provided for @settingsLoadingPurchaseInfo.
  ///
  /// In ko, this message translates to:
  /// **'구매 정보 불러오는 중…'**
  String get settingsLoadingPurchaseInfo;

  /// No description provided for @settingsPurchaseStartFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 구매를 시작할 수 없어요. 잠시 후 다시 시도해주세요.'**
  String get settingsPurchaseStartFailed;

  /// No description provided for @settingsRestoreButton.
  ///
  /// In ko, this message translates to:
  /// **'구매 복원'**
  String get settingsRestoreButton;

  /// No description provided for @settingsRestoreSuccess.
  ///
  /// In ko, this message translates to:
  /// **'구매 내역이 복원되었어요.'**
  String get settingsRestoreSuccess;

  /// No description provided for @settingsRestoreNothing.
  ///
  /// In ko, this message translates to:
  /// **'복원할 구매 내역이 없어요.'**
  String get settingsRestoreNothing;

  /// No description provided for @todayEntryEditTooltip.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get todayEntryEditTooltip;

  /// No description provided for @todayEntryDeleteTooltip.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get todayEntryDeleteTooltip;

  /// No description provided for @todayEntryAnalyzing.
  ///
  /// In ko, this message translates to:
  /// **'AI가 감정을 분석하고 있어요...'**
  String get todayEntryAnalyzing;

  /// No description provided for @todayEntryMaxAnalysisHit.
  ///
  /// In ko, this message translates to:
  /// **'AI 분석은 일기당 최대 {max}회까지 가능해요.'**
  String todayEntryMaxAnalysisHit(int max);

  /// No description provided for @todayEntryDailyLimitHit.
  ///
  /// In ko, this message translates to:
  /// **'오늘 AI 분석 한도({limit}개)를 모두 사용했어요.'**
  String todayEntryDailyLimitHit(int limit);

  /// No description provided for @todayEntryAnalysisCompleteMaxed.
  ///
  /// In ko, this message translates to:
  /// **'분석 완료! 이번 일기의 분석 횟수({max}/{max})를 모두 사용했어요. (오늘 {dailyUsed}/{dailyLimit})'**
  String todayEntryAnalysisCompleteMaxed(
    int max,
    int dailyUsed,
    int dailyLimit,
  );

  /// No description provided for @todayEntryAnalysisComplete.
  ///
  /// In ko, this message translates to:
  /// **'분석 완료! ({used}/{max}회 사용, 남은 횟수 {remaining} · 오늘 {dailyUsed}/{dailyLimit})'**
  String todayEntryAnalysisComplete(
    int used,
    int max,
    int remaining,
    int dailyUsed,
    int dailyLimit,
  );

  /// No description provided for @todayEntryAnalysisErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'분석 오류'**
  String get todayEntryAnalysisErrorTitle;

  /// No description provided for @todayEntryAnalysisErrorMessage.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 시도해주세요.'**
  String get todayEntryAnalysisErrorMessage;

  /// No description provided for @todayEntryEmptyContent.
  ///
  /// In ko, this message translates to:
  /// **'일기 내용을 입력해주세요.'**
  String get todayEntryEmptyContent;

  /// No description provided for @todayEntryAnalysisLocked.
  ///
  /// In ko, this message translates to:
  /// **'분석 횟수({max}회)를 모두 사용해 이전 분석 결과가 유지돼요.'**
  String todayEntryAnalysisLocked(int max);

  /// No description provided for @todayEntryDeleteDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'일기 삭제'**
  String get todayEntryDeleteDialogTitle;

  /// No description provided for @todayEntryDeleteDialogMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 일기를 삭제할까요?\n삭제하면 되돌릴 수 없어요.'**
  String get todayEntryDeleteDialogMessage;

  /// No description provided for @todayEntryAnalyzeCapHit.
  ///
  /// In ko, this message translates to:
  /// **'분석 횟수를 모두 사용했어요'**
  String get todayEntryAnalyzeCapHit;

  /// No description provided for @todayEntryBonusAdButton.
  ///
  /// In ko, this message translates to:
  /// **'광고 보고 AI 분석 +{bonus} 언락 (남은 시청 {remaining}회)'**
  String todayEntryBonusAdButton(int bonus, int remaining);

  /// No description provided for @todayEntryDailyLimitButton.
  ///
  /// In ko, this message translates to:
  /// **'오늘 AI 분석 한도를 모두 사용했어요'**
  String get todayEntryDailyLimitButton;

  /// No description provided for @todayEntryAnalyzeButton.
  ///
  /// In ko, this message translates to:
  /// **'AI 감정 분석 ({remaining}/{max})'**
  String todayEntryAnalyzeButton(int remaining, int max);

  /// No description provided for @todayEntryBonusUnlocked.
  ///
  /// In ko, this message translates to:
  /// **'AI 분석 +{bonus}개가 언락되었어요!'**
  String todayEntryBonusUnlocked(int bonus);

  /// No description provided for @todayEntryBonusAdIncomplete.
  ///
  /// In ko, this message translates to:
  /// **'광고를 끝까지 시청해야 보상을 받을 수 있어요.'**
  String get todayEntryBonusAdIncomplete;

  /// No description provided for @commonTryAgainLater.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 시도해주세요.'**
  String get commonTryAgainLater;

  /// No description provided for @statsTitle.
  ///
  /// In ko, this message translates to:
  /// **'감정 통계'**
  String get statsTitle;

  /// No description provided for @statsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 달에는 아직 분석된 일기가 없어요\n일기를 작성하면 감정 통계를 볼 수 있어요'**
  String get statsEmpty;

  /// No description provided for @statsDistributionTitle.
  ///
  /// In ko, this message translates to:
  /// **'감정 분포 (하루 평균 기준)'**
  String get statsDistributionTitle;

  /// No description provided for @statsTop3Title.
  ///
  /// In ko, this message translates to:
  /// **'이 달의 감정 Top 3'**
  String get statsTop3Title;

  /// No description provided for @statsTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'감정 변화'**
  String get statsTrendTitle;

  /// No description provided for @statsMonthSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'월간 요약'**
  String get statsMonthSummaryTitle;

  /// No description provided for @statsMonthAiSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'월간 AI 요약'**
  String get statsMonthAiSummaryTitle;

  /// No description provided for @statsDistributionRow.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 ({percent}%)'**
  String statsDistributionRow(int days, int percent);

  /// No description provided for @statsTopRowCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String statsTopRowCount(int count);

  /// No description provided for @statsMonthSummaryText.
  ///
  /// In ko, this message translates to:
  /// **'이번 달은 {totalDays}일(총 {totalEntries}개 기록) 중 \'{emotion}\'을 가장 많이 느꼈어요. ({days}일, {percent}%)'**
  String statsMonthSummaryText(
    int totalDays,
    int totalEntries,
    String emotion,
    int days,
    int percent,
  );

  /// No description provided for @statsSummaryErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'요약 생성 실패'**
  String get statsSummaryErrorTitle;

  /// No description provided for @statsSummaryAdIncomplete.
  ///
  /// In ko, this message translates to:
  /// **'광고 시청이 완료되지 않아 요약을 만들지 못했어요.'**
  String get statsSummaryAdIncomplete;

  /// No description provided for @statsSummaryQuotaHit.
  ///
  /// In ko, this message translates to:
  /// **'오늘 요약 한도를 모두 사용했어요. 내일 다시 이용해주세요.'**
  String get statsSummaryQuotaHit;

  /// No description provided for @statsSummaryNotEnoughData.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 분석된 일기가 없어 요약할 내용이 부족해요.'**
  String get statsSummaryNotEnoughData;

  /// No description provided for @statsSummaryQuotaBadge.
  ///
  /// In ko, this message translates to:
  /// **'이 달 요약 {available}/{budget} 남음 · 일기 {entriesToNext}개 더 쓰면 +1회 충전'**
  String statsSummaryQuotaBadge(int available, int budget, int entriesToNext);

  /// No description provided for @statsSummaryFreeCreate.
  ///
  /// In ko, this message translates to:
  /// **'무료로 AI 요약 만들기'**
  String get statsSummaryFreeCreate;

  /// No description provided for @statsSummaryFreeRegen.
  ///
  /// In ko, this message translates to:
  /// **'무료로 다시 요약하기'**
  String get statsSummaryFreeRegen;

  /// No description provided for @statsSummaryAdCreate.
  ///
  /// In ko, this message translates to:
  /// **'광고 보고 AI 요약 만들기'**
  String get statsSummaryAdCreate;

  /// No description provided for @statsSummaryAdRegen.
  ///
  /// In ko, this message translates to:
  /// **'광고 보고 다시 요약하기'**
  String get statsSummaryAdRegen;

  /// No description provided for @statsSummaryAllUsed.
  ///
  /// In ko, this message translates to:
  /// **'이 달 요약 한도를 모두 사용했어요'**
  String get statsSummaryAllUsed;

  /// No description provided for @weeklyInsightTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 인사이트'**
  String get weeklyInsightTitle;

  /// No description provided for @weeklyInsightCareTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 주, 조금 더 챙겨요'**
  String get weeklyInsightCareTitle;

  /// No description provided for @weeklyInsightEmptyReady.
  ///
  /// In ko, this message translates to:
  /// **'최근 기록에서 패턴을 찾아드릴 수 있어요.\n첫 인사이트를 만들어볼까요?'**
  String get weeklyInsightEmptyReady;

  /// No description provided for @weeklyInsightEmptyNeedMore.
  ///
  /// In ko, this message translates to:
  /// **'일기가 쌓이면 요즘의 감정 흐름을 먼저 말씀드릴게요.\n일기를 조금 더 써볼까요?'**
  String get weeklyInsightEmptyNeedMore;

  /// No description provided for @weeklyInsightCreateFirst.
  ///
  /// In ko, this message translates to:
  /// **'첫 인사이트 만들기'**
  String get weeklyInsightCreateFirst;

  /// No description provided for @weeklyInsightRefresh.
  ///
  /// In ko, this message translates to:
  /// **'새로고침'**
  String get weeklyInsightRefresh;

  /// No description provided for @weeklyInsightRefreshable.
  ///
  /// In ko, this message translates to:
  /// **'새로고침 가능'**
  String get weeklyInsightRefreshable;

  /// No description provided for @weeklyInsightWaitingRefresh.
  ///
  /// In ko, this message translates to:
  /// **'주간 새로고침 대기 중'**
  String get weeklyInsightWaitingRefresh;

  /// No description provided for @weeklyInsightRefreshIn.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 후 갱신'**
  String weeklyInsightRefreshIn(int days);

  /// No description provided for @weeklyInsightDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 남음'**
  String weeklyInsightDaysLeft(int days);

  /// No description provided for @weeklyInsightTrendLabel.
  ///
  /// In ko, this message translates to:
  /// **'{trend, select, up{상승} down{하강} stable{안정} mixed{혼재} other{}}'**
  String weeklyInsightTrendLabel(String trend);

  /// No description provided for @weeklyInsightGenerating.
  ///
  /// In ko, this message translates to:
  /// **'생성 중…'**
  String get weeklyInsightGenerating;

  /// No description provided for @weeklyInsightAdLabel.
  ///
  /// In ko, this message translates to:
  /// **'광고 보고 {base}'**
  String weeklyInsightAdLabel(String base);

  /// No description provided for @weeklyInsightMonthlyLimit.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 한도 소진'**
  String get weeklyInsightMonthlyLimit;

  /// No description provided for @weeklyInsightCreatedToast.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 인사이트를 만들었어요.'**
  String get weeklyInsightCreatedToast;

  /// No description provided for @weeklyInsightCooldownError.
  ///
  /// In ko, this message translates to:
  /// **'아직 새로고침할 시기가 아니에요.'**
  String get weeklyInsightCooldownError;

  /// No description provided for @weeklyInsightQuotaError.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 한도를 모두 사용했어요.'**
  String get weeklyInsightQuotaError;

  /// No description provided for @weeklyInsightAdError.
  ///
  /// In ko, this message translates to:
  /// **'광고를 끝까지 시청해야 생성할 수 있어요.'**
  String get weeklyInsightAdError;

  /// No description provided for @weeklyInsightNotEnoughData.
  ///
  /// In ko, this message translates to:
  /// **'패턴을 찾기엔 기록이 조금 부족해요.'**
  String get weeklyInsightNotEnoughData;

  /// No description provided for @weeklyInsightGenericError.
  ///
  /// In ko, this message translates to:
  /// **'생성 중 문제가 발생했어요.'**
  String get weeklyInsightGenericError;

  /// 홈 상단 날짜 (ko 전용 요일 결합). en은 그대로 dateLabel만 사용.
  ///
  /// In ko, this message translates to:
  /// **'{dateLabel} {dayLabel}요일'**
  String homeDateHeading(String dateLabel, String dayLabel);

  /// No description provided for @homeTodayHeading.
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루는 어땠나요?'**
  String get homeTodayHeading;

  /// No description provided for @homeEntrySavedToast.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 일기가 저장되었어요.'**
  String get homeEntrySavedToast;

  /// No description provided for @homeTodayEntries.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 기록'**
  String get homeTodayEntries;

  /// No description provided for @homeComposerHint.
  ///
  /// In ko, this message translates to:
  /// **'오늘 있었던 일, 느낀 감정을 자유롭게 적어보세요...'**
  String get homeComposerHint;

  /// No description provided for @homeAddEntryButton.
  ///
  /// In ko, this message translates to:
  /// **'기록 추가'**
  String get homeAddEntryButton;

  /// No description provided for @homeDailyQuotaBadge.
  ///
  /// In ko, this message translates to:
  /// **'AI 분석 {used}/{max}'**
  String homeDailyQuotaBadge(int used, int max);

  /// No description provided for @mainTabToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get mainTabToday;

  /// No description provided for @mainTabCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get mainTabCalendar;

  /// No description provided for @mainTabStats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get mainTabStats;

  /// No description provided for @mainTabTimeline.
  ///
  /// In ko, this message translates to:
  /// **'타임라인'**
  String get mainTabTimeline;

  /// No description provided for @pinSetupTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 설정'**
  String get pinSetupTitle;

  /// No description provided for @pinSetupRepeat.
  ///
  /// In ko, this message translates to:
  /// **'다시 한 번 입력해주세요'**
  String get pinSetupRepeat;

  /// No description provided for @pinSetupHelp4Digit.
  ///
  /// In ko, this message translates to:
  /// **'4자리 숫자를 입력해주세요'**
  String get pinSetupHelp4Digit;

  /// No description provided for @pinSetupHelpRepeat.
  ///
  /// In ko, this message translates to:
  /// **'확인을 위해 같은 번호를 입력해주세요'**
  String get pinSetupHelpRepeat;

  /// No description provided for @pinSetupMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않아요. 다시 설정해주세요.'**
  String get pinSetupMismatch;

  /// No description provided for @pinBiometricTitle.
  ///
  /// In ko, this message translates to:
  /// **'생체인증을 사용할까요?'**
  String get pinBiometricTitle;

  /// No description provided for @pinBiometricDescription.
  ///
  /// In ko, this message translates to:
  /// **'지문/페이스ID로 더 빠르게 잠금을 해제할 수 있어요.\n설정에서 언제든 바꿀 수 있어요.'**
  String get pinBiometricDescription;

  /// No description provided for @pinBiometricEnable.
  ///
  /// In ko, this message translates to:
  /// **'사용할게요'**
  String get pinBiometricEnable;

  /// No description provided for @pinBiometricSkip.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호만 쓸게요'**
  String get pinBiometricSkip;

  /// No description provided for @lockTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 입력'**
  String get lockTitle;

  /// No description provided for @lockHelp.
  ///
  /// In ko, this message translates to:
  /// **'4자리 비밀번호를 입력해주세요'**
  String get lockHelp;

  /// No description provided for @lockMismatchError.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않아요'**
  String get lockMismatchError;

  /// No description provided for @lockForgotPin.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get lockForgotPin;

  /// No description provided for @lockResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 초기화'**
  String get lockResetTitle;

  /// No description provided for @lockResetMessage.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 복구할 수 없어 모든 데이터가 삭제됩니다.\n정말 초기화할까요?'**
  String get lockResetMessage;

  /// No description provided for @lockResetButton.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get lockResetButton;

  /// No description provided for @lockBiometricReason.
  ///
  /// In ko, this message translates to:
  /// **'생체인증으로 잠금을 해제합니다'**
  String get lockBiometricReason;

  /// No description provided for @timelineTitle.
  ///
  /// In ko, this message translates to:
  /// **'타임라인'**
  String get timelineTitle;

  /// No description provided for @timelineEmpty.
  ///
  /// In ko, this message translates to:
  /// **'작성한 일기가 없어요\n오늘의 감정을 기록해보세요'**
  String get timelineEmpty;

  /// No description provided for @timelineEndReached.
  ///
  /// In ko, this message translates to:
  /// **'모든 일기를 불러왔어요'**
  String get timelineEndReached;

  /// No description provided for @calendarTitle.
  ///
  /// In ko, this message translates to:
  /// **'감정 캘린더'**
  String get calendarTitle;

  /// No description provided for @calendarTapHint.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 탭하면 일기를 볼 수 있어요'**
  String get calendarTapHint;

  /// No description provided for @calendarNoEntryForDate.
  ///
  /// In ko, this message translates to:
  /// **'이 날은 일기를 작성하지 않았어요'**
  String get calendarNoEntryForDate;

  /// No description provided for @diaryDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'일기 상세'**
  String get diaryDetailTitle;

  /// No description provided for @diaryDetailNotFound.
  ///
  /// In ko, this message translates to:
  /// **'일기를 찾을 수 없어요'**
  String get diaryDetailNotFound;

  /// No description provided for @weeklyLineChartHint.
  ///
  /// In ko, this message translates to:
  /// **'2일 이상의 분석 데이터가 있으면 그래프가 표시됩니다'**
  String get weeklyLineChartHint;

  /// No description provided for @dayAverageHeader.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 평균'**
  String dayAverageHeader(int month, int day);

  /// No description provided for @dayAverageEntryCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 기록'**
  String dayAverageEntryCount(int count);

  /// No description provided for @donutChartDaysUnit.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get donutChartDaysUnit;

  /// No description provided for @driveBackupFileEntryCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 일기'**
  String driveBackupFileEntryCount(int count);

  /// No description provided for @driveBackupDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'백업 파일'**
  String get driveBackupDefaultName;

  /// ko: '5월 12일 월요일' 형태로 결합. en: 동일 포맷, 공백 결합.
  ///
  /// In ko, this message translates to:
  /// **'{datePart} {dayPart}'**
  String datePartWithDay(String datePart, String dayPart);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

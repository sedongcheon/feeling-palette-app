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
}

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
}

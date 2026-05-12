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
}

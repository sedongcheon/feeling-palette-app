import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/theme.dart';
import 'db/database.dart';
import 'providers/auth_provider.dart';
import 'providers/diary_provider.dart';
import 'services/ads_service.dart';
import 'services/premium_service.dart';
import 'widgets/app_lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  runApp(const FeelingPaletteApp());
}

class FeelingPaletteApp extends StatelessWidget {
  const FeelingPaletteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DiaryProvider>(create: (_) => DiaryProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<AdsService>.value(value: AdsService.instance),
        ChangeNotifierProvider<PremiumService>.value(
            value: PremiumService.instance),
      ],
      child: MaterialApp(
        title: 'Feeling Palette',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AppLockGate(),
      ),
    );
  }
}

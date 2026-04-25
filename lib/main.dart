import 'dart:async';
import 'dart:io' show Platform;

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
  // IAP 상품 정보 사전 로드. iOS는 Apple Paid Apps Agreement 미완성으로
  // production에서 IAP가 작동하지 않아 UI도 숨겨둔 상태(settings_screen 참고).
  // 사업자등록 후 다시 활성화 예정이므로 iOS에서는 init도 스킵해 불필요한 에러
  // 로그를 막는다. Android는 정상 동작.
  if (!Platform.isIOS) {
    unawaited(PremiumService.instance.initialize());
  }
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

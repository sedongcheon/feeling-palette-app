import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
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

  // Android 15+ SDK 35 edge-to-edge 요구사항. 시스템 바 아래까지 콘텐츠를 그리고
  // SafeArea로 인셋을 처리한다.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
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
          // Android 15+ SDK 35: setStatusBarColor/setNavigationBarColor가
          // deprecated. 색상 필드를 비워두면 Flutter가 그 메서드를 호출하지
          // 않으므로 Play Console 경고가 줄어든다. brightness만 지정한다.
          const overlay = SystemUiOverlayStyle(
            systemNavigationBarContrastEnforced: false,
          );
          final styled = isDark
              ? overlay.copyWith(
                  statusBarBrightness: Brightness.dark,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarIconBrightness: Brightness.light,
                )
              : overlay.copyWith(
                  statusBarBrightness: Brightness.light,
                  statusBarIconBrightness: Brightness.dark,
                  systemNavigationBarIconBrightness: Brightness.dark,
                );
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: styled,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AppLockGate(),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'constants/theme.dart';
import 'db/database.dart';
import 'providers/auth_provider.dart';
import 'providers/diary_provider.dart';
import 'services/ads_service.dart';
import 'services/install_marker_service.dart';
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
  // iOS Keychain의 default group이 앱 삭제 후에도 보너스 카운터를 잔존
  // 시켜 quota max가 6/9 같이 stale하게 보이는 케이스를 차단.
  // SharedPreferences marker로 신규 install을 감지해 bonus_* 키만 정리.
  // DiaryProvider.loadDailyBonus()가 잔존 데이터를 읽기 전에 끝나야
  // 하므로 await (보통 100ms 이내).
  await InstallMarkerService.cleanupOnFirstInstall();
  // IAP 상품 정보 사전 로드. iOS/Android 모두 활성화.
  unawaited(PremiumService.instance.initialize());
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
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';
import '../screens/lock_screen.dart';
import '../screens/main_tabs.dart';
import '../screens/pin_setup_screen.dart';
import '../services/ads_service.dart';
import '../services/consent_service.dart';
import '../services/premium_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  AuthStage? _previousStage;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final stage = context.watch<AuthProvider>().stage;

    if (_previousStage == AuthStage.unlocked && stage == AuthStage.needsSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<DiaryProvider>().clearCache();
      });
    }
    // Kick off consent / ATT / AdMob init the first time the user reaches the
    // main app in this session. Non-blocking: UMP and ATT sheets appear over
    // MainTabs while ads preload in the background.
    if (_previousStage != AuthStage.unlocked && stage == AuthStage.unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ConsentService.instance.gather();
        // Premium check first so ads init can skip preloading for paid users.
        await PremiumService.instance.initialize();
        await AdsService.instance.initialize();
      });
    }
    _previousStage = stage;

    switch (stage) {
      case AuthStage.loading:
        return Scaffold(
          backgroundColor: palette.background,
          body: const Center(child: CircularProgressIndicator()),
        );
      case AuthStage.needsSetup:
        return const PinSetupScreen();
      case AuthStage.locked:
        return const LockScreen();
      case AuthStage.unlocked:
        return const MainTabs();
    }
  }
}

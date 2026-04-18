import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';
import '../screens/lock_screen.dart';
import '../screens/main_tabs.dart';
import '../screens/pin_setup_screen.dart';

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

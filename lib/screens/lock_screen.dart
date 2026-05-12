import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_pad.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _current = '';
  String? _error;
  bool _checking = false;
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (_biometricAttempted) return;
    _biometricAttempted = true;
    final auth = context.read<AuthProvider>();
    if (!auth.biometricEnabled) return;
    await auth.authenticateBiometric(
      localizedReason: AppLocalizations.of(context).lockBiometricReason,
    );
  }

  Future<void> _onChanged(String value) async {
    setState(() {
      _current = value;
      _error = null;
    });
    if (value.length != 4 || _checking) return;
    setState(() => _checking = true);
    final ok = await context.read<AuthProvider>().verifyPin(value);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _current = '';
        _error = AppLocalizations.of(context).lockMismatchError;
        _checking = false;
      });
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(loc.lockResetTitle),
          content: Text(loc.lockResetMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                loc.lockResetButton,
                style: const TextStyle(color: Color(0xFFE74C3C)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().resetAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(
              Icons.lock_rounded,
              size: 48,
              color: palette.tabBarActive,
            ),
            const SizedBox(height: 16),
            Text(
              loc.lockTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.lockHelp,
              style: TextStyle(
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
            const Spacer(),
            PinPad(
              value: _current,
              onChanged: _onChanged,
              errorText: _error,
              trailingLeft: auth.biometricEnabled
                  ? Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.fingerprint_rounded,
                          size: 32,
                          color: palette.tabBarActive,
                        ),
                        onPressed: () => context
                            .read<AuthProvider>()
                            .authenticateBiometric(
                              localizedReason: loc.lockBiometricReason,
                            ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _confirmReset,
              child: Text(
                loc.lockForgotPin,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

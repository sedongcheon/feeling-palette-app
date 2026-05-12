import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/pin_pad.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _Step { enter, confirm, biometric }

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _authService = AuthService();
  _Step _step = _Step.enter;
  String _firstPin = '';
  String _current = '';
  String? _error;
  bool _biometricAvailable = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _authService.canUseBiometric().then((value) {
      if (mounted) setState(() => _biometricAvailable = value);
    });
  }

  void _onChanged(String value) {
    setState(() {
      _current = value;
      _error = null;
    });
    if (value.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _handleComplete);
    }
  }

  void _handleComplete() {
    if (_current.length != 4) return;
    if (_step == _Step.enter) {
      setState(() {
        _firstPin = _current;
        _current = '';
        _step = _Step.confirm;
      });
      return;
    }
    if (_step == _Step.confirm) {
      if (_current != _firstPin) {
        setState(() {
          _current = '';
          _firstPin = '';
          _step = _Step.enter;
          _error = AppLocalizations.of(context).pinSetupMismatch;
        });
        return;
      }
      if (_biometricAvailable) {
        setState(() => _step = _Step.biometric);
      } else {
        _finish(enableBiometric: false);
      }
    }
  }

  Future<void> _finish({required bool enableBiometric}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await context.read<AuthProvider>().completeSetup(
          pin: _firstPin,
          enableBiometric: enableBiometric,
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: _step == _Step.biometric
            ? _buildBiometricChoice(palette)
            : _buildPinEntry(palette),
      ),
    );
  }

  Widget _buildPinEntry(AppPalette palette) {
    final loc = AppLocalizations.of(context);
    final title =
        _step == _Step.enter ? loc.pinSetupTitle : loc.pinSetupRepeat;
    final subtitle = _step == _Step.enter
        ? loc.pinSetupHelp4Digit
        : loc.pinSetupHelpRepeat;

    return Column(
      children: [
        const SizedBox(height: 48),
        Icon(
          Icons.lock_outline_rounded,
          size: 48,
          color: palette.tabBarActive,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
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
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBiometricChoice(AppPalette palette) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.fingerprint_rounded,
            size: 64,
            color: palette.tabBarActive,
          ),
          const SizedBox(height: 16),
          Text(
            loc.pinBiometricTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.pinBiometricDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : () => _finish(enableBiometric: true),
              style: FilledButton.styleFrom(
                backgroundColor: palette.tabBarActive,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                loc.pinBiometricEnable,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: _submitting ? null : () => _finish(enableBiometric: false),
              child: Text(
                loc.pinBiometricSkip,
                style: TextStyle(
                  fontSize: 15,
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

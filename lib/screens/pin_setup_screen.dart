import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
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
          _error = '비밀번호가 일치하지 않아요. 다시 설정해주세요.';
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
    final title = _step == _Step.enter
        ? '새 비밀번호 설정'
        : '다시 한 번 입력해주세요';
    final subtitle = _step == _Step.enter
        ? '4자리 숫자를 입력해주세요'
        : '확인을 위해 같은 번호를 입력해주세요';

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
            '생체인증을 사용할까요?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '지문/페이스ID로 더 빠르게 잠금을 해제할 수 있어요.\n설정에서 언제든 바꿀 수 있어요.',
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
              child: const Text(
                '사용할게요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                '비밀번호만 쓸게요',
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import 'voice_edit_screen.dart';

/// 음성 일기의 첫 화면. 마이크 권한을 받고 한국어(`ko_KR`) STT를 라이브로
/// 받는다. 큰 원형 버튼이 시작/중지 토글. 최대 3분이 지나면 자동 종료한다.
///
/// 오디오 파일은 저장하지 않는다 (spec: 음성 보관 out of scope).
/// 펄스 애니메이션은 `onSoundLevelChange`의 데시벨 값을 부드럽게 보간해
/// 표시한다.
class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  static const Duration _maxDuration = Duration(minutes: 3);
  static const Duration _autoStopWarning = Duration(seconds: 4);

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _initializing = true;
  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  double _soundLevel = 0; // dB-ish, speech_to_text는 범위 보장 안 함
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_speech.isListening) {
      _speech.cancel();
    }
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (e) {
          if (!mounted) return;
          setState(() => _listening = false);
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
            _ticker?.cancel();
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _available = available;
        _initializing = false;
      });
      if (!available) {
        await _showPermissionDeniedDialog();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _available = false;
        _initializing = false;
      });
      await _showPermissionDeniedDialog();
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    final loc = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.voiceJournalPermissionDeniedTitle),
        content: Text(loc.voiceJournalPermissionDeniedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.commonOk),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleListening() async {
    if (!_available) return;
    if (_listening) {
      await _stop(reachedMax: false);
      return;
    }
    setState(() {
      _transcript = '';
      _elapsed = Duration.zero;
      _listening = true;
      _startedAt = DateTime.now();
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final start = _startedAt;
      if (start == null) return;
      final delta = DateTime.now().difference(start);
      if (!mounted) return;
      setState(() => _elapsed = delta);
      if (delta >= _maxDuration) {
        _stop(reachedMax: true);
      }
    });
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        localeId: _resolveSttLocale(),
        pauseFor: const Duration(seconds: 5),
        listenFor: _maxDuration,
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _soundLevel = level);
      },
    );
  }

  Future<void> _stop({required bool reachedMax}) async {
    _ticker?.cancel();
    if (_speech.isListening) {
      await _speech.stop();
    }
    if (!mounted) return;
    setState(() => _listening = false);
    if (_transcript.trim().isEmpty) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.voiceJournalSttFailed),
          behavior: SnackBarBehavior.floating,
        ));
      // Empty transcript도 EditScreen으로 보내서 사용자가 직접 입력할 수 있게.
    }
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VoiceEditScreen(initialText: _transcript),
      ),
    );
  }

  String _resolveSttLocale() {
    final locale = AppLocalizations.of(context).localeName;
    return locale.startsWith('ko') ? 'ko_KR' : 'en_US';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);

    if (_initializing) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: _appBar(palette, loc),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final mins =
        _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs =
        _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    final remaining = _maxDuration - _elapsed;
    final showAutoStopWarning =
        _listening && remaining <= _autoStopWarning && remaining > Duration.zero;

    return Scaffold(
      backgroundColor: palette.background,
      // 이 화면은 TextField가 없어 키보드를 띄울 일이 없다. EditScreen에서
      // TextField focus 상태로 "다시 말하기"를 눌러 push될 때 IME inset이
      // 잠시 적용되어 Column이 overflow하는 frame이 보이는 것을 막는다.
      resizeToAvoidBottomInset: false,
      appBar: _appBar(palette, loc),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                _listening
                    ? loc.voiceJournalRecordingHint
                    : loc.voiceJournalTapToStart,
                style: TextStyle(
                  fontSize: 16,
                  color: palette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loc.voiceJournalMaxDuration,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$mins:$secs',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              _PulseButton(
                listening: _listening,
                soundLevel: _soundLevel,
                color: palette.tabBarActive,
                onTap: _toggleListening,
              ),
              const SizedBox(height: 24),
              if (showAutoStopWarning)
                Text(
                  loc.voiceJournalAutoStopWarning(remaining.inSeconds + 1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE74C3C),
                  ),
                )
              else if (_transcript.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _transcript,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: palette.text,
                      height: 1.5,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: palette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.voiceJournalCancelButton,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(AppPalette palette, AppLocalizations loc) {
    return AppBar(
      backgroundColor: palette.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        loc.voiceJournalRecordingTitle,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: palette.tabBarActive,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: palette.tabBarActive),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _PulseButton extends StatelessWidget {
  final bool listening;
  final double soundLevel;
  final Color color;
  final VoidCallback onTap;

  const _PulseButton({
    required this.listening,
    required this.soundLevel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // soundLevel은 device-dependent. -2~10 정도로 들어옴. 시각 효과 목적이라
    // 거칠게 normalize.
    final normalized =
        listening ? ((soundLevel.clamp(-2.0, 10.0) + 2.0) / 12.0).clamp(0.0, 1.0) : 0.0;
    final baseSize = 160.0;
    final pulseSize = baseSize + (40.0 * normalized);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (listening)
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: pulseSize + 20,
                height: pulseSize + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(0x14),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: listening ? pulseSize : baseSize,
              height: listening ? pulseSize : baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: listening
                    ? color.withAlpha(0x22)
                    : color.withAlpha(0x14),
              ),
            ),
            Container(
              width: baseSize - 30,
              height: baseSize - 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(0x55),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                listening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/voice_journal.dart';
import '../providers/diary_provider.dart';
import '../services/voice_journal_service.dart';
import 'voice_analysis_result_screen.dart';
import 'voice_recording_screen.dart';

/// STT 결과를 사용자가 자유롭게 다듬는 화면. "다시 말하기"로 녹음 화면에
/// 재진입하거나 "이 일기로 분석받기"로 백엔드 호출 후 결과 화면으로 이동한다.
class VoiceEditScreen extends StatefulWidget {
  final String initialText;

  const VoiceEditScreen({super.key, required this.initialText});

  @override
  State<VoiceEditScreen> createState() => _VoiceEditScreenState();
}

class _VoiceEditScreenState extends State<VoiceEditScreen> {
  static const int _maxLength = 1500;

  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  final VoiceJournalService _service = VoiceJournalService();

  bool _analyzing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reRecord() async {
    // TextField에 focus가 있으면 IME가 떠 있는 상태로 다음 화면이 push되어
    // RecordingScreen의 Column이 한 frame 동안 overflow한다. 미리 내림.
    FocusScope.of(context).unfocus();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VoiceRecordingScreen()),
    );
  }

  Future<void> _analyze() async {
    final loc = AppLocalizations.of(context);
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.voiceJournalSttFailed),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    // 음성 일기도 일기 — 텍스트 일기와 동일한 daily quota를 따른다.
    // EditScreen에서 백엔드 호출 전에 차단해서 후속 화면에서 "분석 결과는
    // 받았는데 저장에서 막힘" 패턴을 방지한다.
    final store = context.read<DiaryProvider>();
    await store.loadDailyBonus();
    await store.loadTodayEntries();
    if (!mounted) return;
    if (store.dailyAnalysisLimitReached) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.voiceJournalDailyLimitReached),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    setState(() => _analyzing = true);
    try {
      final result = await _service.analyze(
        content: trimmed,
        locale: loc.localeName,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VoiceAnalysisResultScreen(
            response: result,
            // 원문은 로컬 저장용으로 그대로 (익명화 전).
            originalContent: trimmed,
          ),
        ),
      );
    } on VoiceAnalyzeException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.voiceJournalAnalyzeFailed),
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          loc.voiceJournalEditTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: palette.tabBarActive,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.voiceJournalEditHint,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLength: _maxLength,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      fontSize: 16,
                      height: 26 / 16,
                      color: palette.text,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.voiceJournalRecordingHint,
                      hintStyle:
                          TextStyle(color: palette.textSecondary),
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: palette.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      loc.voiceJournalAnonymizationNote,
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _analyzing ? null : _reRecord,
                      icon: const Icon(Icons.mic_rounded, size: 18),
                      label: Text(loc.voiceJournalReRecord),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: palette.border),
                        foregroundColor: palette.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _analyzing ||
                              _controller.text.trim().isEmpty
                          ? null
                          : _analyze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.tabBarActive,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _analyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              loc.voiceJournalAnalyzeButton,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

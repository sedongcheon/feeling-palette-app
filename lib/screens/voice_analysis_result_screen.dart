import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../models/voice_journal.dart';
import '../providers/diary_provider.dart';
import '../services/ads_service.dart';

/// 음성 일기 분석 결과 화면. dominant emotion + 색상 원 + 공감 메시지 +
/// 테마 칩을 보여주고, "기록 보관"으로 [DiaryEntry]를 저장(source: voice)
/// 후 홈으로 복귀하거나 "처음으로"로 그냥 빠져나갈 수 있다.
class VoiceAnalysisResultScreen extends StatefulWidget {
  final VoiceAnalyzeResponse response;
  final String originalContent;

  const VoiceAnalysisResultScreen({
    super.key,
    required this.response,
    required this.originalContent,
  });

  @override
  State<VoiceAnalysisResultScreen> createState() =>
      _VoiceAnalysisResultScreenState();
}

class _VoiceAnalysisResultScreenState
    extends State<VoiceAnalysisResultScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveAndExit() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);
    try {
      final store = context.read<DiaryProvider>();
      // 원문은 로컬 sqflite에 저장 (익명화 전 텍스트).
      final entry = await store.createDiary(
        widget.originalContent,
        source: DiarySource.voice,
      );
      // 분석 결과를 entry에 즉시 적용 (음성 분석은 quota 시스템 우회 —
      // 이미 백엔드 호출이 끝났고 결과까지 받았으므로).
      // EditScreen이 백엔드 호출 전에 daily quota를 이미 검증했으므로
      // 여기서 다시 차단되지 않게 bypass. 단 카운트는 정상 올라가서
      // 텍스트 일기와 동일한 일일 한도(기본 3건 + 보상광고 보너스)를
      // 공유한다.
      await store.applyAnalysis(
        id: entry.id,
        primaryEmotion: widget.response.dominantEmotion,
        emotions: _scoresFromEmotions(widget.response.emotions),
        aiComment: widget.response.empathyResponse,
        color: widget.response.suggestedColorHex,
        bypassDailyQuota: true,
      );
      // 텍스트 일기 분석과 동일하게 전면 광고 카운터를 증가시킨다
      // (3건 누적마다 90s 쿨다운으로 노출). 음성과 텍스트가 같은 풀을
      // 공유하므로 음성으로만 사용해도 광고가 정상 노출된다.
      AdsService.instance.onAnalysisCompleted();
      if (!mounted) return;
      setState(() {
        _saved = true;
        _saving = false;
      });
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).voiceJournalAnalyzeFailed),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  EmotionScores _scoresFromEmotions(List<Emotion> emotions) {
    int score(String label) {
      final hit = emotions.firstWhere(
        (e) => e.label == label,
        orElse: () => const Emotion(label: '', intensity: 0),
      );
      return (hit.intensity * 100).round().clamp(0, 100);
    }

    return EmotionScores(
      joy: score('joy'),
      sadness: score('sadness'),
      anger: score('anger'),
      anxiety: score('anxiety'),
      calm: score('calm'),
      excitement: score('excitement'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final response = widget.response;
    final color = hexToColor(response.suggestedColorHex);
    final emotionLocalized =
        emotionLabel(context, response.dominantEmotion);
    final intensityPct = (response.intensityScore * 100).round();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          loc.voiceJournalResultTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: palette.tabBarActive,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 색상 원
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(0x88),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emotionInfoOf(response.dominantEmotion).emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  emotionLocalized,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '$intensityPct%',
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    loc.voiceJournalColorReasoning(
                        response.dominantEmotion.name),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // 공감 메시지
              if (response.empathyResponse.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.voiceJournalResultEmpathy,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: palette.tabBarActive,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        response.empathyResponse,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // 테마 칩 — 기존 API는 themes를 안 주므로 비어 있을 가능성이
              // 높지만, 신규 v1 엔드포인트 swap 시 자동으로 노출.
              if (response.themes.isNotEmpty) ...[
                Text(
                  loc.voiceJournalResultThemes,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: response.themes
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: palette.tabBarActive.withAlpha(0x18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette.tabBarActive,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context)
                              .popUntil((r) => r.isFirst),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: palette.border),
                        foregroundColor: palette.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(loc.voiceJournalBackHome),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving || _saved ? null : _saveAndExit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.tabBarActive,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              loc.voiceJournalKeepAsEntry,
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

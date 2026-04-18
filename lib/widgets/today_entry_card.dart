import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../models/diary.dart';
import '../providers/diary_provider.dart';
import '../services/emotion_analyzer.dart';
import 'emotion_result_card.dart';

class TodayEntryCard extends StatefulWidget {
  final DiaryEntry entry;
  final EmotionAnalyzer analyzer;

  const TodayEntryCard({
    super.key,
    required this.entry,
    required this.analyzer,
  });

  @override
  State<TodayEntryCard> createState() => _TodayEntryCardState();
}

class _TodayEntryCardState extends State<TodayEntryCard> {
  static const int _maxLength = 1000;

  late final TextEditingController _controller =
      TextEditingController(text: widget.entry.content);
  bool _isEditing = false;
  bool _isAnalyzing = false;
  bool _isSaving = false;

  @override
  void didUpdateWidget(covariant TodayEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.entry.content != widget.entry.content) {
      _controller.text = widget.entry.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _runAnalysis() async {
    if (!widget.entry.canAnalyze) {
      _showSnack('AI 분석은 일기당 최대 $kMaxAnalysisCount회까지 가능해요.');
      return;
    }
    final store = context.read<DiaryProvider>();
    setState(() => _isAnalyzing = true);
    try {
      final result = await widget.analyzer.analyze(widget.entry.content);
      final updated = await store.applyAnalysis(
        id: widget.entry.id,
        primaryEmotion: result.primaryEmotion,
        emotions: result.emotions,
        aiComment: result.comment,
        color: result.color,
      );
      if (!mounted || updated == null) return;
      final used = updated.analysisCount;
      final remaining = updated.remainingAnalyses;
      _showSnack(
        remaining == 0
            ? '분석 완료! 이번 일기의 분석 횟수($kMaxAnalysisCount/$kMaxAnalysisCount)를 모두 사용했어요.'
            : '분석 완료! ($used/$kMaxAnalysisCount회 사용, 남은 횟수 $remaining)',
      );
    } catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('분석 오류'),
          content: const Text('잠시 후 다시 시도해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _save() async {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      _showSnack('일기 내용을 입력해주세요.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final outcome = await context
          .read<DiaryProvider>()
          .updateDiary(id: widget.entry.id, content: trimmed);
      if (!mounted) return;
      setState(() => _isEditing = false);
      if (outcome != null && outcome.analysisLocked) {
        _showSnack('분석 횟수($kMaxAnalysisCount회)를 모두 사용해 이전 분석 결과가 유지돼요.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _controller.text = widget.entry.content;
      _isEditing = false;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('이 일기를 삭제할까요?\n삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<DiaryProvider>().removeDiary(widget.entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entry = widget.entry;
    final hasAnalysis = entry.aiComment.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Text(
                  _formatTime(entry.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!_isEditing)
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: palette.textSecondary),
                    tooltip: '수정',
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFE74C3C)),
                    tooltip: '삭제',
                    onPressed: _delete,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _isEditing
                ? _buildEditor(palette)
                : _buildViewer(palette, entry.content),
          ),
          if (_isAnalyzing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF69B4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI가 감정을 분석하고 있어요...',
                    style: TextStyle(
                        fontSize: 13, color: palette.textSecondary),
                  ),
                ],
              ),
            ),
          if (hasAnalysis && !_isAnalyzing && !_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: EmotionResultCard(entry: entry),
            ),
          if (!hasAnalysis && !_isAnalyzing && !_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: entry.canAnalyze ? _runAnalysis : null,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    entry.canAnalyze
                        ? 'AI 감정 분석 (${entry.remainingAnalyses}/$kMaxAnalysisCount)'
                        : '분석 횟수를 모두 사용했어요',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.tabBarActive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final hour12 = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final period = d.hour < 12 ? '오전' : '오후';
    final mm = d.minute.toString().padLeft(2, '0');
    return '$period $hour12:$mm';
  }

  Widget _buildViewer(AppPalette palette, String content) {
    return Text(
      content,
      style: TextStyle(fontSize: 15, height: 24 / 15, color: palette.text),
    );
  }

  Widget _buildEditor(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLength: _maxLength,
          maxLines: null,
          minLines: 4,
          autofocus: true,
          style: TextStyle(fontSize: 15, height: 24 / 15, color: palette.text),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_controller.text.length}/$_maxLength',
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: palette.border),
                    foregroundColor: palette.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF69B4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: const Size(60, 36),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '저장',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../providers/diary_provider.dart';
import '../widgets/banner_ad_slot.dart';
import 'diary_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loaded = await context
          .read<DiaryProvider>()
          .loadTimelineEntries(limit: _pageSize, offset: 0);
      if (mounted) setState(() => _hasMore = loaded == _pageSize);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    final store = context.read<DiaryProvider>();
    final loaded = await store.loadTimelineEntries(
      limit: _pageSize,
      offset: store.timelineEntries.length,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (loaded < _pageSize) _hasMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final store = context.watch<DiaryProvider>();
    final entries = store.timelineEntries;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(loc.timelineTitle,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 17, color: palette.text)),
      ),
      body: Column(children: [
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 12),
                        Text(
                          loc.timelineEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              height: 22 / 14,
                              color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: entries.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == entries.length) {
                  if (_isLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.tabBarActive,
                          ),
                        ),
                      ),
                    );
                  }
                  if (!_hasMore && entries.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        loc.timelineEndReached,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: palette.textSecondary),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                    return _TimelineItem(entry: entries[index]);
                  },
                ),
        ),
        const BannerAdSlot(),
      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final DiaryEntry entry;
  const _TimelineItem({required this.entry});

  String _formatDateTime(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = loc.localeName;
    final parts = entry.date.split('-');
    final d = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final datePart = DateFormat.MMMd(locale).format(d);
    final dayPart = DateFormat.EEEE(locale).format(d);
    final t = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);
    final timePart = DateFormat.jm(locale).format(t);
    return '${loc.datePartWithDay(datePart, dayPart)} · $timePart';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasAnalysis = entry.aiComment.isNotEmpty;
    final primary = emotionInfoOf(entry.primaryEmotion);
    final entryColor = hexToColor(entry.color);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => DiaryDetailScreen(entryId: entry.id),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: hasAnalysis ? entryColor : palette.border,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _formatDateTime(context),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: palette.textSecondary),
                            ),
                          ),
                          if (hasAnalysis)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: entryColor.withAlpha(0x18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(primary.emoji,
                                      style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 3),
                                  Text(
                                    emotionLabel(context, entry.primaryEmotion),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: entryColor),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14, height: 21 / 14, color: palette.text),
                      ),
                      if (hasAnalysis) ...[
                        const SizedBox(height: 4),
                        Text(
                          'AI: ${entry.aiComment}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: palette.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/recommendation.dart';
import '../services/recommend_cache.dart';
import '../services/recommend_service.dart';

/// 음악·책 추천 화면.
///
/// 진입점(텍스트/음성 분석 결과 화면)에서 사용자가 보상 광고를 끝까지
/// 봤을 때만 push된다. 화면 자체는 광고를 다시 호출하지 않고
/// [RecommendService]만 호출한다. 재시도 버튼은 같은 service를 다시 부른다
/// (광고 재시청 요구 없음 — 이미 본 광고에 대한 보상 콘텐츠).
///
/// 진입 시점에 일기 본문과 locale을 받아 내부에서 future를 만들고
/// [FutureBuilder]로 loading / error / success 상태를 처리한다.
class RecommendScreen extends StatefulWidget {
  final String content;
  final String locale;

  /// 테스트 / DI용. 일반 호출자는 생략하면 기본 service가 만들어진다.
  final RecommendService? service;

  const RecommendScreen({
    super.key,
    required this.content,
    required this.locale,
    this.service,
  });

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  late final RecommendService _service =
      widget.service ?? RecommendService();
  late Future<RecommendResponse> _future = _load();

  Future<RecommendResponse> _load() async {
    final cached = RecommendCache.instance
        .get(content: widget.content, locale: widget.locale);
    if (cached != null) return cached;
    final response = await _service.recommend(
      content: widget.content,
      locale: widget.locale,
    );
    RecommendCache.instance.put(
      content: widget.content,
      locale: widget.locale,
      response: response,
    );
    return response;
  }

  void _retry() {
    setState(() {
      _future = _load();
    });
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
          loc.recommendTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: palette.tabBarActive,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<RecommendResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _LoadingState(message: loc.recommendLoading);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _ErrorState(onRetry: _retry);
            }
            return _SuccessBody(response: snapshot.data!);
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String message;
  const _LoadingState({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: palette.tabBarActive),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              loc.recommendFailedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.recommendFailedBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    side: BorderSide(color: palette.border),
                    foregroundColor: palette.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(loc.recommendBackHome),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.tabBarActive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.recommendRetry,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  final RecommendResponse response;
  const _SuccessBody({required this.response});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final info = emotionInfoOf(response.primaryEmotion);
    final accent = hexToColor(info.hex);
    final emotionLocalized =
        emotionLabel(context, response.primaryEmotion);
    final disclaimer = response.disclaimer.trim().isEmpty
        ? loc.recommendDisclaimerFallback
        : response.disclaimer;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 감정 뱃지
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withAlpha(0x22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(info.emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      emotionLocalized,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 위로 메시지
          if (response.comfortMessage.isNotEmpty)
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
                    loc.recommendComfortHeader,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: palette.tabBarActive,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    response.comfortMessage,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // 음악
          if (response.music.isNotEmpty) ...[
            Text(
              loc.recommendMusicHeader,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 10),
            ...response.music.map(
              (m) => _RecommendCard(
                title: m.title,
                subtitle: m.artist,
                reason: m.reason,
                accent: accent,
                searchUrl: _youtubeSearchUrl(m.title, m.artist),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 책
          if (response.books.isNotEmpty) ...[
            Text(
              loc.recommendBooksHeader,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 10),
            ...response.books.map(
              (b) => _RecommendCard(
                title: b.title,
                subtitle: b.author,
                reason: b.reason,
                accent: accent,
                searchUrl: _googleSearchUrl(b.title, b.author),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // disclaimer (필수)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              disclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: palette.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 닫기
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: palette.border),
              foregroundColor: palette.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(loc.recommendBackHome),
          ),
        ],
      ),
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String reason;
  final Color accent;
  final Uri? searchUrl;

  const _RecommendCard({
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.accent,
    this.searchUrl,
  });

  Future<void> _openSearch(BuildContext context) async {
    final url = searchUrl;
    if (url == null) return;
    final loc = AppLocalizations.of(context);
    try {
      final ok =
          await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(loc.recommendOpenLinkFailed),
            behavior: SnackBarBehavior.floating,
          ));
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.recommendOpenLinkFailed),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tappable = searchUrl != null && title.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tappable ? () => _openSearch(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                      ),
                    ),
                    if (tappable)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Icon(Icons.open_in_new_rounded,
                            size: 16, color: palette.textSecondary),
                      ),
                  ],
                ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- search URL helpers ----------

Uri? _youtubeSearchUrl(String title, String artist) {
  final q = _joinQuery([title, artist]);
  if (q.isEmpty) return null;
  return Uri.https('www.youtube.com', '/results', {'search_query': q});
}

Uri? _googleSearchUrl(String title, String author) {
  final q = _joinQuery([title, author]);
  if (q.isEmpty) return null;
  return Uri.https('www.google.com', '/search', {'q': q});
}

String _joinQuery(List<String> parts) =>
    parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' ');


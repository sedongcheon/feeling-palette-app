import 'package:flutter/material.dart';

import '../constants/emotions.dart';
import '../models/diary.dart';

class WeeklyLineChart extends StatelessWidget {
  final List<DayAggregate> days;
  final double width;
  final double height;
  final Color textColor;
  final Color gridColor;
  final Color surfaceColor;

  const WeeklyLineChart({
    super.key,
    required this.days,
    this.width = 320,
    this.height = 180,
    this.textColor = const Color(0xFF6B7280),
    this.gridColor = const Color(0xFFE5E7EB),
    this.surfaceColor = const Color(0xFFFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final sorted = days.where((d) => d.hasAnalysis).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.length > 14
        ? sorted.sublist(sorted.length - 14)
        : sorted;

    if (recent.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '2일 이상의 분석 데이터가 있으면 그래프가 표시됩니다',
          style: TextStyle(fontSize: 13, color: textColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    final dataPoints = recent
        .map((day) => _Point(
              date: day.date,
              score: day.emotions.scoreOf(day.primaryEmotion),
              emotion: day.primaryEmotion,
              color: hexToColor(day.color),
            ))
        .toList();

    final uniqueEmotions = <EmotionType>{};
    for (final p in dataPoints) {
      uniqueEmotions.add(p.emotion);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _LinePainter(
              points: dataPoints,
              gridColor: gridColor,
              surfaceColor: surfaceColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 4, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_short(dataPoints.first.date),
                  style: TextStyle(fontSize: 10, color: textColor)),
              Text(_short(dataPoints.last.date),
                  style: TextStyle(fontSize: 10, color: textColor)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: uniqueEmotions.map((type) {
            final info = emotionInfoOf(type);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 4),
                Text('${info.emoji} ${info.label}',
                    style: TextStyle(fontSize: 11, color: textColor)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _short(String dateStr) {
    final parts = dateStr.split('-');
    return '${int.parse(parts[1])}/${int.parse(parts[2])}';
  }
}

class _Point {
  final String date;
  final int score;
  final EmotionType emotion;
  final Color color;
  const _Point({
    required this.date,
    required this.score,
    required this.emotion,
    required this.color,
  });
}

class _LinePainter extends CustomPainter {
  final List<_Point> points;
  final Color gridColor;
  final Color surfaceColor;

  _LinePainter({
    required this.points,
    required this.gridColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padTop = 16.0;
    const padRight = 16.0;
    const padBottom = 28.0;
    const padLeft = 32.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;

    double getX(int i) => padLeft + (i / (points.length - 1)) * chartW;
    double getY(int score) => padTop + chartH - (score / 100) * chartH;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (final t in [0, 25, 50, 75, 100]) {
      final y = getY(t);
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFFF69B4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final pt = Offset(getX(i), getY(points[i].score));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final c = Offset(getX(i), getY(p.score));
      canvas.drawCircle(c, 4, Paint()..color = p.color);
      canvas.drawCircle(
        c,
        4,
        Paint()
          ..color = surfaceColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.points != points;
}

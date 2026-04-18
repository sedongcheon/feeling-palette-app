import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/theme.dart';

class DonutSlice {
  final String label;
  final String emoji;
  final int value;
  final Color color;

  const DonutSlice({
    required this.label,
    required this.emoji,
    required this.value,
    required this.color,
  });
}

class DonutChart extends StatelessWidget {
  final List<DonutSlice> data;
  final double size;
  final double strokeWidth;

  const DonutChart({
    super.key,
    required this.data,
    this.size = 160,
    this.strokeWidth = 24,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, s) => sum + s.value);
    if (total == 0) return const SizedBox.shrink();

    final palette = context.palette;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              data: data.where((d) => d.value > 0).toList(),
              total: total,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Text(
                  '일',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> data;
  final int total;
  final double strokeWidth;

  _DonutPainter({
    required this.data,
    required this.total,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    for (final slice in data) {
      final sweep = (slice.value / total) * 2 * math.pi;
      final adjusted = sweep < (2 * math.pi) ? sweep : (2 * math.pi - 0.001);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = slice.color;
      canvas.drawArc(rect, startAngle, adjusted, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.total != total ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

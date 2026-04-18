import 'package:flutter/material.dart';

import '../constants/theme.dart';

class PinPad extends StatelessWidget {
  final int length;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final Widget? trailingLeft;

  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 4,
    this.errorText,
    this.trailingLeft,
  });

  void _press(String digit) {
    if (value.length >= length) return;
    onChanged(value + digit);
  }

  void _backspace() {
    if (value.isEmpty) return;
    onChanged(value.substring(0, value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            final filled = i < value.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? palette.tabBarActive : Colors.transparent,
                border: Border.all(
                  color: filled ? palette.tabBarActive : palette.border,
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 20,
          child: errorText == null
              ? const SizedBox.shrink()
              : Text(
                  errorText!,
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        for (var row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var col = 0; col < 3; col++)
                _PinKey(
                  label: '${row * 3 + col + 1}',
                  onTap: () => _press('${row * 3 + col + 1}'),
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: trailingLeft ?? const SizedBox.shrink(),
            ),
            _PinKey(label: '0', onTap: () => _press('0')),
            SizedBox(
              width: 80,
              height: 80,
              child: Center(
                child: IconButton(
                  icon: Icon(
                    Icons.backspace_outlined,
                    color: palette.textSecondary,
                  ),
                  onPressed: _backspace,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PinKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 80,
      height: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: palette.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

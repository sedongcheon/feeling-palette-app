import 'package:flutter/material.dart';

class AppPalette {
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color tabBar;
  final Color tabBarInactive;
  final Color tabBarActive;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.tabBar,
    required this.tabBarInactive,
    required this.tabBarActive,
  });

  static const light = AppPalette(
    background: Color(0xFFFAFAF8),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    tabBar: Color(0xFFFFFFFF),
    tabBarInactive: Color(0xFF9CA3AF),
    tabBarActive: Color(0xFFFF69B4),
  );

  static const dark = AppPalette(
    background: Color(0xFF1A1A2E),
    surface: Color(0xFF252542),
    text: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    border: Color(0xFF374151),
    tabBar: Color(0xFF252542),
    tabBarInactive: Color(0xFF6B7280),
    tabBarActive: Color(0xFFFF69B4),
  );
}

class AppPaletteExt extends ThemeExtension<AppPaletteExt> {
  final AppPalette palette;
  final bool isDark;
  const AppPaletteExt({required this.palette, required this.isDark});

  @override
  AppPaletteExt copyWith({AppPalette? palette, bool? isDark}) =>
      AppPaletteExt(palette: palette ?? this.palette, isDark: isDark ?? this.isDark);

  @override
  AppPaletteExt lerp(ThemeExtension<AppPaletteExt>? other, double t) => this;
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPaletteExt>()!.palette;
  bool get isDark => Theme.of(this).extension<AppPaletteExt>()!.isDark;
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPalette.light.background,
    fontFamily: null,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.light.tabBarActive,
      brightness: Brightness.light,
    ),
    extensions: const [AppPaletteExt(palette: AppPalette.light, isDark: false)],
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppPalette.dark.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.dark.tabBarActive,
      brightness: Brightness.dark,
    ),
    extensions: const [AppPaletteExt(palette: AppPalette.dark, isDark: true)],
  );
}

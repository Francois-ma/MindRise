import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.emerald,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDDF6EC),
      onPrimaryContainer: Color(0xFF063D32),
      secondary: AppColors.blue,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE3ECFF),
      onSecondaryContainer: Color(0xFF102A67),
      tertiary: AppColors.amber,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFEBC1),
      onTertiaryContainer: Color(0xFF4A3000),
      error: AppColors.rose,
      onError: Colors.white,
      errorContainer: Color(0xFFFFD9DE),
      onErrorContainer: Color(0xFF5C111D),
      surface: AppColors.surfaceLight,
      onSurface: AppColors.ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFFBFEFC),
      surfaceContainer: Color(0xFFF4FAF7),
      surfaceContainerHigh: Color(0xFFEAF3EF),
      surfaceContainerHighest: Color(0xFFE2ECE8),
      onSurfaceVariant: AppColors.muted,
      outline: Color(0xFF8BA19A),
      outlineVariant: AppColors.borderLight,
      shadow: Color(0xFF163A34),
      scrim: Colors.black,
      inverseSurface: Color(0xFF263632),
      onInverseSurface: Color(0xFFEFF8F4),
      inversePrimary: Color(0xFF75D8BC),
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.teal,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF0A4A43),
      onPrimaryContainer: Color(0xFFA8F1DE),
      secondary: Color(0xFF7EA7FF),
      onSecondary: Color(0xFF061A3E),
      secondaryContainer: Color(0xFF17366D),
      onSecondaryContainer: Color(0xFFDDE7FF),
      tertiary: Color(0xFFE6B85B),
      onTertiary: Color(0xFF2D1D00),
      tertiaryContainer: Color(0xFF5A3C08),
      onTertiaryContainer: Color(0xFFFFE5AA),
      error: Color(0xFFFFA1AE),
      onError: Color(0xFF4C0713),
      errorContainer: Color(0xFF7C1D2C),
      onErrorContainer: Color(0xFFFFD9DE),
      surface: AppColors.surfaceDark,
      onSurface: Color(0xFFE8F2EE),
      surfaceContainerLowest: Color(0xFF06110F),
      surfaceContainerLow: Color(0xFF0B1A17),
      surfaceContainer: AppColors.cardDark,
      surfaceContainerHigh: Color(0xFF172B27),
      surfaceContainerHighest: Color(0xFF203A35),
      onSurfaceVariant: Color(0xFFB8C9C3),
      outline: Color(0xFF7E958E),
      outlineVariant: AppColors.borderDark,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE2ECE8),
      onInverseSurface: Color(0xFF17211E),
      inversePrimary: AppColors.emerald,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      fontFamily: 'Roboto',
      textTheme: _textTheme(isDark),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.ink,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primaryContainer.withValues(alpha: .72),
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.cardDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(scheme.outlineVariant),
        enabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme.primary, width: 1.6),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.6),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: .68),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.emerald,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? scheme.surfaceContainerHighest
            : AppColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primaryContainer,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: .12),
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final color = isDark ? Colors.white : AppColors.ink;
    final muted = isDark ? const Color(0xFFB8C9C3) : AppColors.muted;
    final base = Typography.material2021().black;

    return base
        .apply(bodyColor: color, displayColor: color)
        .copyWith(
          headlineLarge: base.headlineLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          titleLarge: base.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          titleMedium: base.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          bodyMedium: base.bodyMedium?.copyWith(color: color, letterSpacing: 0),
          bodySmall: base.bodySmall?.copyWith(color: muted, letterSpacing: 0),
          labelSmall: base.labelSmall?.copyWith(color: muted, letterSpacing: 0),
        );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

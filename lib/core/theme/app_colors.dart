import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const emerald = Color(0xFF0F9F7A);
  static const teal = Color(0xFF0F766E);
  static const cyan = Color(0xFF0891B2);
  static const amber = Color(0xFFD89A25);
  static const blue = Color(0xFF2563EB);
  static const rose = Color(0xFFE05267);
  static const lime = Color(0xFF65A30D);
  static const lavender = Color(0xFF7C3AED);
  static const ink = Color(0xFF13231F);
  static const muted = Color(0xFF64736F);
  static const surfaceLight = Color(0xFFF6FAF8);
  static const surfaceWarm = Color(0xFFFFFBF3);
  static const surfaceCool = Color(0xFFEFF8FA);
  static const surfaceDark = Color(0xFF071614);
  static const cardDark = Color(0xFF10211E);
  static const borderLight = Color(0xFFDDE9E4);
  static const borderDark = Color(0xFF203A35);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF0F9F7A), Color(0xFF0F766E), Color(0xFF0B8AA0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const appBackground = LinearGradient(
    colors: [surfaceLight, surfaceWarm, surfaceCool],
    stops: [0, .58, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const clinicalBlueGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF168AAD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warmResetGradient = LinearGradient(
    colors: [Color(0xFFD89A25), Color(0xFFE76F51)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const learningGradient = LinearGradient(
    colors: [Color(0xFF65A30D), Color(0xFF0F9F7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

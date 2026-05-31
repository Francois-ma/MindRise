import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const emerald = Color(0xFF064D3B);
  static const teal = Color(0xFF0A6B4F);
  static const cyan = Color(0xFF155A8A);
  static const amber = Color(0xFFE1B12C);
  static const blue = Color(0xFF155A8A);
  static const rose = Color(0xFFE05267);
  static const lime = Color(0xFF46A94F);
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
    colors: [Color(0xFF064D3B), Color(0xFF0A6B4F), Color(0xFF46A94F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const appBackground = LinearGradient(
    colors: [surfaceLight, Color(0xFFFFFFFF), Color(0xFFEFF7ED)],
    stops: [0, .58, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const clinicalBlueGradient = LinearGradient(
    colors: [Color(0xFF064D3B), Color(0xFF155A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warmResetGradient = LinearGradient(
    colors: [Color(0xFFE1B12C), Color(0xFF0A6B4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const learningGradient = LinearGradient(
    colors: [Color(0xFF46A94F), Color(0xFF064D3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

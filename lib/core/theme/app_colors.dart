import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand Core
  static const Color primary = Color(0xFFAEC6FF);
  static const Color onPrimary = Color(0xFF002E6A);
  static const Color primaryContainer = Color(0xFF004395);
  static const Color onPrimaryContainer = Color(0xFF91B4FF);

  // Surface Strategy (Luminance Stacking)
  static const Color background = Color(0xFF061423);
  static const Color onBackground = Color(0xFFD5E4F9);
  
  static const Color surface = Color(0xFF061423);
  static const Color surfaceBase = Color(0xFF000B1A); // Deepest
  static const Color surfaceContainerLow = Color(0xFF0E1C2C);
  static const Color surfaceContainer = Color(0xFF001A3D); // Cards
  static const Color surfaceContainerHigh = Color(0xFF1D2B3B);
  static const Color surfaceContainerHighest = Color(0xFF283646);
  
  static const Color onSurface = Color(0xFFD5E4F9);
  static const Color onSurfaceVariant = Color(0xFFC3C6D3);
  static const Color onSurfaceMuted = Color(0xFF80A1CA);

  // Accents & Functional
  static const Color accentGlow = Color(0xFF4D8EFF);
  static const Color outline = Color(0xFF8D909D);
  static const Color outlineVariant = Color(0xFF434751);
  
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Transparent Variants
  static Color outlineTransparent = primaryContainer.withOpacity(0.3);
}

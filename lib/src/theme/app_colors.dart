import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primaryLight = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF5EEAD4);
  static const Color primaryContainerLight = Color(0xFFCCFBF1);
  static const Color primaryContainerDark = Color(0xFF134E4A);

  // Secondary Palette
  static const Color secondaryLight = Color(0xFF7C3AED);
  static const Color secondaryDark = Color(0xFFA78BFA);
  static const Color secondaryContainerLight = Color(0xFFEDE9FE);
  static const Color secondaryContainerDark = Color(0xFF3B0764);

  // Surface Colors
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color surfaceVariantDark = Color(0xFF1E293B);

  // Semantic Colors
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Status Colors
  static const Color ocrQueued = Color(0xFF94A3B8);
  static const Color ocrProcessing = Color(0xFFF97316);
  static const Color ocrComplete = Color(0xFF22C55E);
  static const Color ocrFailed = Color(0xFFEF4444);

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Scanner Colors
  static const Color scannerOverlay = Color(0x80000000);
  static const Color scannerCorner = Color(0xFF0F766E);
  static const Color scannerLaser = Color(0xFF22C55E);

  // Filter Colors
  static const Map<String, Color> filterColors = {
    'auto_enhance': Color(0xFF0F766E),
    'black_white': Color(0xFF333333),
    'grayscale': Color(0xFF6B7280),
    'magic_color': Color(0xFF7C3AED),
    'sharpen': Color(0xFFF59E0B),
    'clean': Color(0xFF22C55E),
  };
}

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Theme Surface Palette (Slate / Precision Navy)
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surfaceCard = Color(0xFF192134);
  static const Color surfaceVariant = Color(0xFF1E293B); // Slate 800
  static const Color surfaceOverlay = Color(0xCC0F172A);
  static const Color border = Color(0x14FFFFFF); // 8% white border

  // Brand Primaries & Accents
  static const Color primary = Color(0xFF0284C7); // Sky 600
  static const Color primaryDark = Color(0xFF0369A1); // Sky 700
  static const Color primaryLight = Color(0xFF38BDF8); // Sky 400
  static const Color primaryContainer = Color(0xFF0C4A6E); // Sky 900

  // Status & Telemetry
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successContainer = Color(0xFF064E3B); // Emerald 900
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningContainer = Color(0xFF78350F); // Amber 900
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorContainer = Color(0xFF7F1D1D); // Red 900

  // Surface & Accent Aliases
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color secondary = Color(0xFF38BDF8); // Sky 400

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textDisabled = Color(0xFF475569); // Slate 600

  // Router Hardware LEDs
  static const Color ledAmber = Color(0xFFFFB300);
  static const Color ledBlue = Color(0xFF1E88E5);
  static const Color ledWhite = Color(0xFFEEEEEE);
}

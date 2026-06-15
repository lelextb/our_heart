// lib/core/theme/colors.dart

import 'package:flutter/material.dart';

/// Central colour palette for the "Our Heart" application.
/// All colours support the Glassmorphism design with light/dark variants.
class AppColors {
  AppColors._();

  // ---- Brand / Accent ----
  static const Color primary = Color(0xFFFF6B81);       // warm pink
  static const Color primaryVariant = Color(0xFFFF3B5C); // deeper pink for emphasis
  static const Color secondary = Color(0xFFFFC1CC);     // soft pastel pink
  static const Color accent = Color(0xFFFFD700);        // gold accent for highlights

  // ---- Backgrounds ----
  static const Color lightBackground = Color(0xFFFDF2F4); // very pale pink
  static const Color darkBackground = Color(0xFF1A1A2E);  // deep navy

  // ---- Glassmorphism ----
  static const Color glassLight = Color(0x40FFFFFF);     // 25% white
  static const Color glassDark = Color(0x40222222);      // ~25% dark overlay
  static const Color glassBorderLight = Color(0x80FFFFFF);
  static const Color glassBorderDark = Color(0x80FFFFFF);

  // ---- Text ----
  static const Color textLightPrimary = Color(0xFF2D2D2D);
  static const Color textLightSecondary = Color(0xFF6E6E6E);
  static const Color textDarkPrimary = Color(0xFFF5F5F5);
  static const Color textDarkSecondary = Color(0xFFB0B0B0);

  // ---- Surfaces / Cards ----
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2A2A3E);

  // ---- Utility ----
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
}
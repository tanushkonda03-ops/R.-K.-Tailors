import 'package:flutter/material.dart';

/// Core color palette for the Tailor app.
/// Light-themed, professional neumorphic design.
class AppColors {
  AppColors._();

  // ── Primary Palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF800000);       // Maroon
  static const Color secondary = Color(0xFFF5DEB3);     // Beige / Wheat
  static const Color accent = Color(0xFF4B2E2E);        // Dark Brown
  static const Color background = Color(0xFFFAF9F6);    // Off-white

  // ── Neumorphic Helpers ───────────────────────────────────────────
  /// Light shadow (top-left highlight)
  static const Color neumorphicLight = Color(0xFFFFFFFF);
  /// Dark shadow (bottom-right shadow)
  static const Color neumorphicDark = Color(0xFFD1CDC7);

  // ── Text Colors ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textOnPrimary = Color(0xFFFAF9F6);

  // ── Surface / Card ──────────────────────────────────────────────
  static const Color surface = Color(0xFFF2F1EE);
  static const Color surfaceElevated = Color(0xFFFAF9F6);
}

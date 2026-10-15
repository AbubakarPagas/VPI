import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// VPI Secure — complete typographic scale.
///
/// Font families:
///   - Rajdhani  : display, headings, buttons — futuristic, bold, techy
///   - Inter     : body, captions, UI labels — clean, readable, professional
///   - Source Code Pro : monospace data (IDs, codes, scores, hashes)
abstract final class AppTextStyles {
  AppTextStyles._();

  // ────────────────────────────────────────────────────────────────────────────
  // Display — hero, splash, large numbers
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get display1 => GoogleFonts.rajdhani(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: 2.0,
    height: 1.0,
  );

  static TextStyle get display2 => GoogleFonts.rajdhani(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.8,
    height: 1.05,
  );

  static TextStyle get display3 => GoogleFonts.rajdhani(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
    height: 1.1,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Headings
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get h1 => GoogleFonts.rajdhani(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
    height: 1.2,
  );

  static TextStyle get h2 => GoogleFonts.rajdhani(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
    height: 1.25,
  );

  static TextStyle get h3 => GoogleFonts.rajdhani(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
    height: 1.3,
  );

  static TextStyle get h4 => GoogleFonts.rajdhani(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.6,
    height: 1.35,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Section / overline labels (ALL-CAPS tracking)
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get overlineLarge => GoogleFonts.rajdhani(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBright,
    letterSpacing: 3.5,
    height: 1.4,
  );

  static TextStyle get overline => GoogleFonts.rajdhani(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBright,
    letterSpacing: 3.0,
    height: 1.4,
  );

  static TextStyle get overlineMuted =>
      overline.copyWith(color: AppColors.textMuted);

  // ────────────────────────────────────────────────────────────────────────────
  // Body / paragraph
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.65,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
    letterSpacing: 0.1,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.55,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyStrong => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // UI labels / captions
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.6,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Buttons
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get buttonLarge => GoogleFonts.rajdhani(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.8,
  );

  static TextStyle get buttonMedium => GoogleFonts.rajdhani(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  static TextStyle get buttonSmall => GoogleFonts.rajdhani(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBright,
    letterSpacing: 1.2,
  );

  static TextStyle get linkButton => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryBright,
    letterSpacing: 0.2,
    decoration: TextDecoration.none,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Monospace — IDs, codes, hashes, trust scores
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get monoXL => GoogleFonts.sourceCodePro(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.trusted,
    letterSpacing: 2.5,
  );

  static TextStyle get monoLarge => GoogleFonts.sourceCodePro(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBright,
    letterSpacing: 2.0,
  );

  static TextStyle get mono => GoogleFonts.sourceCodePro(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryBright,
    letterSpacing: 1.2,
  );

  static TextStyle get monoSmall => GoogleFonts.sourceCodePro(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 1.0,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Score / metric display
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get scoreHero => GoogleFonts.rajdhani(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    color: AppColors.trusted,
    letterSpacing: 2.0,
    height: 1.0,
  );

  static TextStyle get scoreLarge => GoogleFonts.rajdhani(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.trusted,
    letterSpacing: 2.0,
    height: 1.0,
  );

  static TextStyle get scoreMedium => GoogleFonts.rajdhani(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.trusted,
    letterSpacing: 1.5,
  );

  static TextStyle get scoreLabel => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 2.8,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // State-aware variants
  // ────────────────────────────────────────────────────────────────────────────

  static TextStyle get trustedText => GoogleFonts.rajdhani(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.trusted,
    letterSpacing: 1.5,
  );

  static TextStyle get warningText => GoogleFonts.rajdhani(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.warning,
    letterSpacing: 1.5,
  );

  static TextStyle get dangerText => GoogleFonts.rajdhani(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.danger,
    letterSpacing: 1.5,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Convenience helpers
  // ────────────────────────────────────────────────────────────────────────────

  /// Page / screen title — Rajdhani 28 bold, used on onboarding and main screens.
  static TextStyle get pageTitle => h1;

  /// Returns h1 coloured with the blue accent.
  static TextStyle get h1Blue => h1.copyWith(color: AppColors.primaryBright);

  /// Returns h1 coloured for a trusted / verified state.
  static TextStyle get h1Green => h1.copyWith(color: AppColors.trusted);
}

import 'package:flutter/material.dart';

/// VPI Secure — spatial and layout constants.
///
/// Use these tokens instead of magic numbers throughout the codebase
/// to keep spacing consistent and easy to adjust globally.
abstract final class AppSpacing {
  AppSpacing._();

  // ── Base spacing scale (4-pt grid) ────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xl2 = 32;
  static const double xl3 = 40;
  static const double xl4 = 48;
  static const double xl5 = 56;
  static const double xl6 = 64;

  // ── Page / screen padding ─────────────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );

  static const EdgeInsets pagePaddingH = EdgeInsets.symmetric(horizontal: 24);

  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 12,
  );

  // ── Card padding ──────────────────────────────────────────────────────────
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 18,
  );

  static const EdgeInsets cardPaddingSmall = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  // ── Border radii ──────────────────────────────────────────────────────────
  static const double radiusXS = 6;
  static const double radiusSM = 10;
  static const double radiusMD = 14;
  static const double radiusLG = 18;
  static const double radiusXL = 24;
  static const double radiusXL2 = 32;
  static const double radiusPill = 100;

  static BorderRadius get roundedXS => BorderRadius.circular(radiusXS);
  static BorderRadius get roundedSM => BorderRadius.circular(radiusSM);
  static BorderRadius get roundedMD => BorderRadius.circular(radiusMD);
  static BorderRadius get roundedLG => BorderRadius.circular(radiusLG);
  static BorderRadius get roundedXL => BorderRadius.circular(radiusXL);
  static BorderRadius get roundedXL2 => BorderRadius.circular(radiusXL2);
  static BorderRadius get pill => BorderRadius.circular(radiusPill);

  // ── Icon sizes ────────────────────────────────────────────────────────────
  static const double iconXS = 14;
  static const double iconSM = 18;
  static const double iconMD = 22;
  static const double iconLG = 28;
  static const double iconXL = 36;
  static const double iconXL2 = 48;
  static const double iconHero = 72;

  // ── Avatar / badge sizes ──────────────────────────────────────────────────
  static const double avatarSM = 32;
  static const double avatarMD = 44;
  static const double avatarLG = 56;
  static const double avatarXL = 72;

  // ── Button heights ────────────────────────────────────────────────────────
  static const double buttonHeightLG = 56;
  static const double buttonHeightMD = 48;
  static const double buttonHeightSM = 38;

  // ── Dividers ──────────────────────────────────────────────────────────────
  static const double dividerThickness = 1;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Fixed-height vertical spacer widgets
  static const Widget gapXS = SizedBox(height: xs);
  static const Widget gapSM = SizedBox(height: sm);
  static const Widget gapMD = SizedBox(height: md);
  static const Widget gapBase = SizedBox(height: base);
  static const Widget gapLG = SizedBox(height: lg);
  static const Widget gapXL = SizedBox(height: xl);
  static const Widget gapXL2 = SizedBox(height: xl2);
  static const Widget gapXL3 = SizedBox(height: xl3);

  /// Fixed-width horizontal spacer widgets
  static const Widget hGapXS = SizedBox(width: xs);
  static const Widget hGapSM = SizedBox(width: sm);
  static const Widget hGapMD = SizedBox(width: md);
  static const Widget hGapBase = SizedBox(width: base);
  static const Widget hGapLG = SizedBox(width: lg);
  static const Widget hGapXL = SizedBox(width: xl);
}

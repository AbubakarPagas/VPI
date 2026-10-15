import 'package:flutter/material.dart';

/// VPI Secure — complete color design token system.
///
/// Philosophy:
///   - Background: deep navy/black for a premium cybersecurity feel
///   - Primary accent: electric blue — action, interaction, trust
///   - Green: ONLY for verified / safe / trusted states
///   - Amber: warnings, unverified, caution
///   - Red: danger, scam, critical alerts
///   - All other UI chrome uses the neutral palette
abstract final class AppColors {
  AppColors._();

  // ────────────────────────────────────────────────────────────────────────────
  // Background hierarchy
  // ────────────────────────────────────────────────────────────────────────────

  /// Deepest background — used for the root scaffold
  static const Color bg0 = Color(0xFF040D1A);

  /// Primary surface — screens, pages
  static const Color bg1 = Color(0xFF071428);

  /// Elevated surface — cards, bottom sheets
  static const Color bg2 = Color(0xFF0B1F3A);

  /// High-elevated surface — dialogs, modals, popovers
  static const Color bg3 = Color(0xFF102542);

  /// Subtle tinted glass surface (used with BackdropFilter)
  static const Color bgGlass = Color(0x1A1E88E5);

  // ────────────────────────────────────────────────────────────────────────────
  // Primary — Electric Blue (interactions, primary actions, links)
  // ────────────────────────────────────────────────────────────────────────────

  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blue100 = Color(0xFFBBDEFB);
  static const Color blue200 = Color(0xFF90CAF9);
  static const Color blue300 = Color(0xFF64B5F6);
  static const Color blue400 = Color(0xFF42A5F5); // bright — text/icons on dark
  static const Color blue500 = Color(0xFF1E88E5); // primary
  static const Color blue600 = Color(0xFF1976D2);
  static const Color blue700 = Color(0xFF1565C0);
  static const Color blue800 = Color(0xFF0D47A1); // dim
  static const Color blue900 = Color(0xFF0A2E6E);

  // Opacity aliases for glow effects
  static const Color blueGlow10 = Color(0x1A1E88E5);
  static const Color blueGlow20 = Color(0x331E88E5);
  static const Color blueGlow40 = Color(0x661E88E5);
  static const Color blueGlow60 = Color(0x991E88E5);

  // Semantic aliases (used throughout the app)
  static const Color primary = blue500;
  static const Color primaryBright = blue400;
  static const Color primaryDim = blue800;
  static const Color primaryGlass = blueGlow20;

  // ────────────────────────────────────────────────────────────────────────────
  // Trusted / Verified — Green (ONLY for verified/safe states)
  // ────────────────────────────────────────────────────────────────────────────

  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color greenA400 = Color(0xFF00E676); // primary trusted bright
  static const Color greenA700 = Color(0xFF00C853); // trusted dim

  static const Color greenGlow20 = Color(0x3300E676);
  static const Color greenGlow40 = Color(0x5500E676);

  static const Color trusted = greenA400;
  static const Color trustedDim = greenA700;
  static const Color trustedGlow = greenGlow40;

  // ────────────────────────────────────────────────────────────────────────────
  // Warning — Amber (caution, unverified, watch)
  // ────────────────────────────────────────────────────────────────────────────

  static const Color amber300 = Color(0xFFFFD54F);
  static const Color amber400 = Color(0xFFFFCA28);
  static const Color amberA400 = Color(0xFFFFAB00); // primary warning
  static const Color amberA700 = Color(0xFFFF6F00);

  static const Color amberGlow20 = Color(0x33FFAB00);
  static const Color amberGlow40 = Color(0x55FFAB00);

  static const Color warning = amberA400;
  static const Color warningDim = amberA700;
  static const Color warningGlow = amberGlow40;

  // ────────────────────────────────────────────────────────────────────────────
  // Danger — Red (scam detected, critical, stolen device)
  // ────────────────────────────────────────────────────────────────────────────

  static const Color red400 = Color(0xFFEF5350);
  static const Color redA400 = Color(0xFFFF1744); // primary danger
  static const Color redA700 = Color(0xFFD50000);

  static const Color redGlow20 = Color(0x33FF1744);
  static const Color redGlow40 = Color(0x55FF1744);

  static const Color danger = redA400;
  static const Color dangerDim = redA700;
  static const Color dangerGlow = redGlow40;

  // ────────────────────────────────────────────────────────────────────────────
  // Neutral / Typography
  // ────────────────────────────────────────────────────────────────────────────

  static const Color textPrimary = Color(0xFFF0F4FF); // headings, primary text
  static const Color textSecondary = Color(0xFFB0BEC5); // body copy
  static const Color textMuted = Color(0xFF546E7A); // captions, hints
  static const Color textDisabled = Color(0xFF2D4A5E); // disabled state

  static const Color divider = Color(0xFF1A2E4A);
  static const Color dividerLight = Color(0xFF203A56);
  static const Color outline = Color(0xFF1E3A5F);
  static const Color outlineLight = Color(0xFF2A4E74);

  // ────────────────────────────────────────────────────────────────────────────
  // Gradients — pre-composed for common use cases
  // ────────────────────────────────────────────────────────────────────────────

  /// Full-screen background sweep
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bg0, bg1, Color(0xFF060F20)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Primary action button fill
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [blue700, blue500],
  );

  /// Subtle variation — top-left to bottom-right
  static const LinearGradient blueSweep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue800, blue500],
  );

  /// Verified / trusted state fill (never used as primary brand colour)
  static const LinearGradient trustedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00897B), greenA400],
  );

  /// Warning state fill
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amberA700, amberA400],
  );

  /// Danger / scam state fill
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [redA700, redA400],
  );

  /// Glass card surface
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueGlow20, blueGlow10],
  );

  /// Elevated card with slightly brighter top edge
  static const LinearGradient elevatedCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bg3, bg2],
  );

  // Radial glows
  static const RadialGradient glowBlue = RadialGradient(
    colors: [blueGlow40, Colors.transparent],
    radius: 0.8,
  );

  static const RadialGradient glowGreen = RadialGradient(
    colors: [greenGlow40, Colors.transparent],
    radius: 0.8,
  );

  static const RadialGradient glowAmber = RadialGradient(
    colors: [amberGlow40, Colors.transparent],
    radius: 0.8,
  );

  static const RadialGradient glowRed = RadialGradient(
    colors: [redGlow40, Colors.transparent],
    radius: 0.8,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  /// Returns the appropriate state color given a semantic status string.
  static Color stateColor(String status) {
    switch (status.toLowerCase()) {
      case 'trusted':
      case 'verified':
      case 'safe':
        return trusted;
      case 'warning':
      case 'caution':
      case 'unverified':
        return warning;
      case 'danger':
      case 'scam':
      case 'stolen':
      case 'critical':
        return danger;
      default:
        return primary;
    }
  }

  /// Returns the glow color for a given state color.
  static Color glowFor(Color stateCol) {
    if (stateCol == trusted || stateCol == trustedDim) return trustedGlow;
    if (stateCol == warning || stateCol == warningDim) return warningGlow;
    if (stateCol == danger || stateCol == dangerDim) return dangerGlow;
    return blueGlow40;
  }
}

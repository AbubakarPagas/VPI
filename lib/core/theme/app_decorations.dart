import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// VPI Secure — pre-built BoxDecoration and BoxShadow recipes.
///
/// Use these instead of building decorations inline to ensure consistency
/// and make global design changes trivial.
abstract final class AppDecorations {
  AppDecorations._();

  // ────────────────────────────────────────────────────────────────────────────
  // Cards
  // ────────────────────────────────────────────────────────────────────────────

  /// Standard elevated card — used for most content cards
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.bg2,
    borderRadius: AppSpacing.roundedLG,
    border: Border.all(color: AppColors.divider, width: 1),
  );

  /// Slightly elevated card with a top-highlight gradient
  static BoxDecoration get cardElevated => BoxDecoration(
    gradient: AppColors.elevatedCardGradient,
    borderRadius: AppSpacing.roundedLG,
    border: Border.all(color: AppColors.dividerLight, width: 1),
  );

  /// Glass card — pair with BackdropFilter for blur effect
  static BoxDecoration get cardGlass => BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: AppSpacing.roundedLG,
    border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
  );

  /// Primary-tinted highlighted card (selected / active state)
  static BoxDecoration get cardHighlighted => BoxDecoration(
    color: AppColors.bg2,
    borderRadius: AppSpacing.roundedLG,
    border: Border.all(color: AppColors.primary, width: 1.5),
    boxShadow: glowBlueSoft,
  );

  /// Trusted / verified state card
  static BoxDecoration get cardTrusted => BoxDecoration(
    color: AppColors.bg2,
    borderRadius: AppSpacing.roundedLG,
    border: Border.all(color: AppColors.trusted.withOpacity(0.4), width: 1),
    boxShadow: glowGreenSoft,
  );

  /// Warning state card
  static BoxDecoration get cardWarning => BoxDecoration(
    color: AppColors.bg2,
    borderRadius: AppSpacing.roundedLG,
    border: Border.all(color: AppColors.warning.withOpacity(0.4), width: 1),
    boxShadow: glowAmberSoft,
  );

  /// Danger / scam state card
  static BoxDecoration get cardDanger => BoxDecoration(
    color: AppColors.bg2,
    borderRadius: AppSpacing.roundedLG,
    border: Border.all(color: AppColors.danger.withOpacity(0.4), width: 1),
    boxShadow: glowRedSoft,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Buttons
  // ────────────────────────────────────────────────────────────────────────────

  /// Gradient fill for primary action buttons (used with InkWell/GestureDetector)
  static BoxDecoration get buttonPrimary => BoxDecoration(
    gradient: AppColors.blueGradient,
    borderRadius: AppSpacing.roundedMD,
    boxShadow: glowBlueMedium,
  );

  static BoxDecoration get buttonPrimaryPressed => BoxDecoration(
    gradient: AppColors.blueSweep,
    borderRadius: AppSpacing.roundedMD,
    boxShadow: glowBlueSoft,
  );

  /// Outlined/ghost button
  static BoxDecoration get buttonOutlined => BoxDecoration(
    color: Colors.transparent,
    borderRadius: AppSpacing.roundedMD,
    border: Border.all(color: AppColors.primary, width: 1.5),
  );

  /// Trusted / success action button
  static BoxDecoration get buttonTrusted => BoxDecoration(
    gradient: AppColors.trustedGradient,
    borderRadius: AppSpacing.roundedMD,
    boxShadow: glowGreenSoft,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Icon containers
  // ────────────────────────────────────────────────────────────────────────────

  static BoxDecoration iconBg(Color color, {double radius = 12}) =>
      BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withOpacity(0.2)),
      );

  static BoxDecoration get iconBgBlue => iconBg(AppColors.primary);
  static BoxDecoration get iconBgGreen => iconBg(AppColors.trusted);
  static BoxDecoration get iconBgAmber => iconBg(AppColors.warning);
  static BoxDecoration get iconBgRed => iconBg(AppColors.danger);

  static BoxDecoration iconCircle(Color color) => BoxDecoration(
    shape: BoxShape.circle,
    color: color.withOpacity(0.12),
    border: Border.all(color: color.withOpacity(0.25)),
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Status chips
  // ────────────────────────────────────────────────────────────────────────────

  static BoxDecoration chipDecoration(Color color) => BoxDecoration(
    borderRadius: AppSpacing.pill,
    color: color.withOpacity(0.12),
    border: Border.all(color: color.withOpacity(0.45), width: 1),
  );

  static BoxDecoration get chipTrusted => chipDecoration(AppColors.trusted);
  static BoxDecoration get chipWarning => chipDecoration(AppColors.warning);
  static BoxDecoration get chipDanger => chipDecoration(AppColors.danger);
  static BoxDecoration get chipBlue => chipDecoration(AppColors.primary);

  // ────────────────────────────────────────────────────────────────────────────
  // Input / text field
  // ────────────────────────────────────────────────────────────────────────────

  static BoxDecoration get inputField => BoxDecoration(
    color: AppColors.bg2,
    borderRadius: AppSpacing.roundedSM,
    border: Border.all(color: AppColors.outline, width: 1),
  );

  static BoxDecoration get inputFieldFocused => BoxDecoration(
    color: AppColors.bg2,
    borderRadius: AppSpacing.roundedSM,
    border: Border.all(color: AppColors.primary, width: 1.5),
    boxShadow: glowBlueSoft,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Bottom navigation / tab bar surface
  // ────────────────────────────────────────────────────────────────────────────

  static BoxDecoration get navBarSurface => BoxDecoration(
    color: AppColors.bg2,
    border: const Border(top: BorderSide(color: AppColors.divider, width: 1)),
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Box shadow recipes
  // ────────────────────────────────────────────────────────────────────────────

  static List<BoxShadow> get glowBlueSoft => [
    BoxShadow(
      color: AppColors.blueGlow20,
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowBlueMedium => [
    BoxShadow(
      color: AppColors.blueGlow40,
      blurRadius: 24,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get glowBlueStrong => [
    BoxShadow(
      color: AppColors.blueGlow60,
      blurRadius: 36,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowGreenSoft => [
    BoxShadow(
      color: AppColors.greenGlow20,
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowAmberSoft => [
    BoxShadow(
      color: AppColors.amberGlow20,
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowRedSoft => [
    BoxShadow(
      color: AppColors.redGlow20,
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevation1 => [
    const BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevation2 => [
    const BoxShadow(
      color: Color(0x44000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevation3 => [
    const BoxShadow(
      color: Color(0x55000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

// ────────────────────────────────────────────────────────────────────────────
// Convenience widget — glass surface with blur
// ────────────────────────────────────────────────────────────────────────────

/// Wraps a child in a glassmorphism backdrop with the VPI Secure card style.
class VpiGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final double blurSigma;

  const VpiGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = AppSpacing.radiusLG,
    this.borderColor,
    this.blurSigma = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.primary.withOpacity(0.22),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Convenience widget — status badge
// ────────────────────────────────────────────────────────────────────────────

/// A small coloured chip indicating a security state.
///
/// [status] one of: 'trusted', 'warning', 'danger', 'info'
class VpiStatusBadge extends StatelessWidget {
  final String label;
  final String status; // 'trusted' | 'warning' | 'danger' | 'info'
  final IconData? icon;

  const VpiStatusBadge({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  Color get _color => AppColors.stateColor(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: AppDecorations.chipDecoration(_color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: _color),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

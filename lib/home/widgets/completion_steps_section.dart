/// CompletionStepsSection — "Steps to Complete" dashboard section.
///
/// Displays three verification steps in a fixed order:
///   1. Device Verification
///   2. Identity Verification
///   3. Protection Activation
///
/// Status rules (enforced here, sourced from [TrustRecord]):
///   • A step is [VerificationStatus.completed] only when the repository
///     reads an authoritative 'completed' record from Firestore.
///   • Phone OTP sign-in and entering a full name do NOT qualify as identity
///     verification.
///   • Protection is not activated by merely opening a screen.
///   • Missing Firestore fields → [VerificationStatus.notStarted] (not an error).
///   • Read errors are surfaced by the parent [TrustController] and shown as
///     a separate retry banner — this widget only renders what it receives.
///
/// The [onActionTap] callback is called with the step index (0, 1, 2) so the
/// parent screen can route to the appropriate feature screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../trust/trust_record.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step metadata — immutable, declared at module level
// ─────────────────────────────────────────────────────────────────────────────

class _StepMeta {
  final String title;
  final String description;
  final String actionLabel;
  final IconData icon;

  const _StepMeta({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.icon,
  });
}

const List<_StepMeta> _kSteps = [
  _StepMeta(
    title: 'Device Verification',
    description: 'Check your device details and available records.',
    actionLabel: 'Verify Device',
    icon: Icons.security_rounded,           // smartphone + shield composite
  ),
  _StepMeta(
    title: 'Identity Verification',
    description: 'Confirm your identity through NIN verification.',
    actionLabel: 'Verify Identity',
    icon: Icons.badge_rounded,
  ),
  _StepMeta(
    title: 'Protection Activation',
    description: 'Set up supported security services.',
    actionLabel: 'Activate Protection',
    icon: Icons.shield_rounded,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// CompletionStepsSection
// ─────────────────────────────────────────────────────────────────────────────

class CompletionStepsSection extends StatelessWidget {
  /// The current trust record — drives status for each step.
  final TrustRecord record;

  /// Called when the user taps an action button.
  /// [stepIndex] is 0 = device, 1 = identity, 2 = protection.
  final ValueChanged<int> onActionTap;

  /// Whether entrance animations should be skipped.
  final bool reduceMotion;

  const CompletionStepsSection({
    super.key,
    required this.record,
    required this.onActionTap,
    this.reduceMotion = false,
  });

  VerificationStatus _statusFor(int index) {
    switch (index) {
      case 0:
        return record.deviceStatus;
      case 1:
        return record.identityStatus;
      case 2:
        return record.protectionStatus;
      default:
        return VerificationStatus.notStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section heading ─────────────────────────────────────────────
          _SectionHeading(
            completedCount: record.completedSteps,
            totalCount: _kSteps.length,
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Step rows ───────────────────────────────────────────────────
          for (int i = 0; i < _kSteps.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _maybeAnimate(
              child: _StepRow(
                index: i,
                meta: _kSteps[i],
                status: _statusFor(i),
                onActionTap: () => onActionTap(i),
              ),
              index: i,
              reduceMotion: reduceMotion,
            ),
          ],
        ],
      ),
    );
  }

  Widget _maybeAnimate({
    required Widget child,
    required int index,
    required bool reduceMotion,
  }) {
    if (reduceMotion) return child;
    return child
        .animate(delay: Duration(milliseconds: 120 + index * 80))
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideY(begin: 0.07, end: 0, duration: 380.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionHeading
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _SectionHeading({
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Steps to Complete', style: AppTextStyles.h4),
        const Spacer(),
        Text(
          '$completedCount / $totalCount',
          style: AppTextStyles.labelMedium.copyWith(
            color: completedCount == totalCount
                ? AppColors.trusted
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StepRow
// ─────────────────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final int index;
  final _StepMeta meta;
  final VerificationStatus status;
  final VoidCallback onActionTap;

  const _StepRow({
    required this.index,
    required this.meta,
    required this.status,
    required this.onActionTap,
  });

  // ── Derived visual properties ─────────────────────────────────────────────

  Color get _accentColor {
    switch (status) {
      case VerificationStatus.completed:
        return AppColors.trusted;
      case VerificationStatus.inProgress:
        return AppColors.primary;
      case VerificationStatus.needsAttention:
        return AppColors.warning;
      case VerificationStatus.unavailable:
        return AppColors.textMuted;
      case VerificationStatus.notStarted:
        return AppColors.primaryBright;
    }
  }

  BoxDecoration get _cardDecoration {
    switch (status) {
      case VerificationStatus.completed:
        return AppDecorations.cardTrusted;
      case VerificationStatus.needsAttention:
        return AppDecorations.cardWarning;
      case VerificationStatus.unavailable:
        return AppDecorations.card;
      default:
        return AppDecorations.card;
    }
  }

  Widget _buildLeadingIcon() {
    final isCompleted = status == VerificationStatus.completed;

    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: AppDecorations.iconBg(_accentColor, radius: 12),
          child: Icon(
            meta.icon,
            size: AppSpacing.iconMD,
            color: _accentColor,
          ),
        ),
        // Green checkmark overlay for completed steps
        if (isCompleted)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.trusted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg2, width: 1.5),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 10,
                color: AppColors.bg0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: AppDecorations.chipDecoration(_accentColor),
      child: Text(
        status.label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: _accentColor,
          fontSize: 9,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final isUnavailable = status == VerificationStatus.unavailable;
    final isCompleted = status == VerificationStatus.completed;

    if (isUnavailable) {
      return Semantics(
        label: '${meta.title} is unavailable',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedSM,
            color: AppColors.bg3,
            border: Border.all(color: AppColors.outline),
          ),
          child: Text(
            'Unavailable',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textDisabled,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    if (isCompleted) {
      return Semantics(
        label: '${meta.title} completed',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: AppDecorations.chipDecoration(AppColors.trusted),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 12,
                color: AppColors.trusted,
              ),
              const SizedBox(width: 4),
              Text(
                'Done',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.trusted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active action button
    return Semantics(
      button: true,
      label: meta.actionLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.roundedSM,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onActionTap,
          splashColor: AppColors.blueGlow20,
          highlightColor: AppColors.blueGlow10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 1,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.blueGradient,
              borderRadius: AppSpacing.roundedSM,
            ),
            child: Text(
              meta.actionLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${meta.title}, ${status.label}',
      child: Container(
        decoration: _cardDecoration,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Leading icon ─────────────────────────────────────────
              _buildLeadingIcon(),

              const SizedBox(width: AppSpacing.md),

              // ── Title + description + status ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status chip on same row when screen is wide enough
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final wide = constraints.maxWidth > 180;
                        if (wide) {
                          return Row(
                            children: [
                              Flexible(
                                child: Text(
                                  meta.title,
                                  style: AppTextStyles.bodyStrong,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildStatusChip(),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta.title,
                              style: AppTextStyles.bodyStrong,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            _buildStatusChip(),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      meta.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── Action button ────────────────────────────────────────
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }
}

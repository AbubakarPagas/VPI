/// TrustScoreCard — dashboard widget for displaying the user's trust score.
///
/// Visual structure:
///   ┌─────────────────────────────────────────────────┐
///   │ YOUR TRUST SCORE               [View Breakdown] │
///   │                                                 │
///   │   ╭──────────────╮                              │
///   │   │  — / 100     │  Complete your checks to     │
///   │   │  TRUST SCORE │  build your trust profile.   │
///   │   ╰──────────────╯                              │
///   │                     Last updated: —             │
///   └─────────────────────────────────────────────────┘
///
/// States:
///   • [TrustLoading]  → skeleton ring + placeholder text
///   • [TrustLoaded]   → animated ring + real score (or "— / 100")
///   • [TrustFailed]   → error message + Retry button
///
/// The ring animation runs once when a real score first arrives, and again
/// if the value changes.  It does NOT replay on every rebuild (keyed by the
/// score value so the AnimationController only restarts when data changes).
///
/// "View Breakdown" opens a [_BreakdownSheet] bottom sheet.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../trust/trust_record.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrustScoreCard
// ─────────────────────────────────────────────────────────────────────────────

class TrustScoreCard extends StatelessWidget {
  final TrustState trustState;
  final VoidCallback onRetry;
  final bool reduceMotion;

  const TrustScoreCard({
    super.key,
    required this.trustState,
    required this.onRetry,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Container(
        decoration: AppDecorations.cardElevated,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (trustState) {
      case TrustLoading():
        return const _CardSkeleton();

      case TrustFailed(:final message):
        return _CardError(message: message, onRetry: onRetry);

      case TrustLoaded(:final record):
        return _CardLoaded(record: record, reduceMotion: reduceMotion);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardLoaded — the real content once data is available
// ─────────────────────────────────────────────────────────────────────────────

class _CardLoaded extends StatelessWidget {
  final TrustRecord record;
  final bool reduceMotion;

  const _CardLoaded({required this.record, required this.reduceMotion});

  void _showBreakdown(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BreakdownSheet(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'YOUR TRUST SCORE',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 2.0,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              _ViewBreakdownButton(onTap: () => _showBreakdown(context)),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Ring + info row ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated ring
              _ScoreRing(
                score: record.score,
                reduceMotion: reduceMotion,
              ),

              const SizedBox(width: AppSpacing.lg),

              // Explanation text
              Expanded(
                child: _ScoreExplanation(record: record),
              ),
            ],
          ),

          // ── Cached / last-updated notice ────────────────────────────────
          if (record.scoreUpdatedAt != null || record.isCached) ...[
            const SizedBox(height: AppSpacing.md),
            _UpdatedNotice(
              updatedAt: record.scoreUpdatedAt,
              isCached: record.isCached,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScoreRing — animated arc drawn with CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreRing extends StatefulWidget {
  final int? score;
  final bool reduceMotion;

  const _ScoreRing({required this.score, required this.reduceMotion});

  @override
  State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  static const double _kSize = 100;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(_ScoreRing old) {
    super.didUpdateWidget(old);
    // Only restart the animation when the score value actually changes.
    if (widget.score != old.score) {
      _maybeAnimate();
    }
  }

  void _maybeAnimate() {
    if (widget.reduceMotion || widget.score == null) {
      _ctrl.value = 1.0; // snap to final value, no animation
    } else {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
    final fraction = score != null ? (score / 100.0).clamp(0.0, 1.0) : 0.0;
    final ringColor = _ringColor(score);

    return SizedBox(
      width: _kSize,
      height: _kSize,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              fraction: fraction * _progress.value,
              trackColor: AppColors.bg3,
              ringColor: ringColor,
              strokeWidth: 8.0,
            ),
            child: child,
          );
        },
        child: Center(
          child: _ScoreLabel(score: score),
        ),
      ),
    );
  }

  Color _ringColor(int? score) {
    if (score == null) return AppColors.outline;
    if (score >= 70) return AppColors.trusted;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RingPainter
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double fraction;   // 0.0 – 1.0
  final Color trackColor;
  final Color ringColor;
  final double strokeWidth;

  const _RingPainter({
    required this.fraction,
    required this.trackColor,
    required this.ringColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // 12 o'clock

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ringPaint = Paint()
      ..color = ringColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Track (full circle)
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * fraction,
        false,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScoreLabel — the number rendered inside the ring
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreLabel extends StatelessWidget {
  final int? score;
  const _ScoreLabel({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score != null ? '$score' : '—',
          style: GoogleFonts.rajdhani(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: score != null
                ? _scoreColor(score!)
                : AppColors.textMuted,
            height: 1.0,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          '/ 100',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Color _scoreColor(int s) {
    if (s >= 70) return AppColors.trusted;
    if (s >= 40) return AppColors.warning;
    return AppColors.danger;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScoreExplanation
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreExplanation extends StatelessWidget {
  final TrustRecord record;
  const _ScoreExplanation({required this.record});

  @override
  Widget build(BuildContext context) {
    final score = record.score;
    final String body;

    if (score == null) {
      body = 'Complete your checks to build your trust profile.';
    } else if (score >= 70) {
      body = 'Your trust profile looks strong. Keep your verifications up to date.';
    } else if (score >= 40) {
      body = 'Some checks are still pending. Complete them to improve your score.';
    } else {
      body = 'Your trust profile needs attention. Complete the steps below.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Trust Score',
          style: AppTextStyles.h4.copyWith(letterSpacing: 0.4),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UpdatedNotice
// ─────────────────────────────────────────────────────────────────────────────

class _UpdatedNotice extends StatelessWidget {
  final DateTime? updatedAt;
  final bool isCached;

  const _UpdatedNotice({required this.updatedAt, required this.isCached});

  String get _label {
    final prefix = isCached ? 'Previously updated' : 'Last updated';
    if (updatedAt == null) return '$prefix: —';
    final d = updatedAt!;
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inMinutes < 1) return '$prefix: just now';
    if (diff.inHours < 1) return '$prefix: ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '$prefix: ${diff.inHours}h ago';
    if (diff.inDays == 1) return '$prefix: yesterday';
    return '$prefix: ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isCached
              ? Icons.cloud_off_outlined
              : Icons.update_rounded,
          size: AppSpacing.iconXS,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          _label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ViewBreakdownButton
// ─────────────────────────────────────────────────────────────────────────────

class _ViewBreakdownButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewBreakdownButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View score breakdown',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.pill,
            border: Border.all(
              color: AppColors.primaryBright.withValues(alpha: 0.4),
            ),
            color: AppColors.primaryGlass,
          ),
          child: Text(
            'View Breakdown',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryBright,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardSkeleton — shown while TrustLoading
// ─────────────────────────────────────────────────────────────────────────────

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(width: 110, height: 10),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // Ring skeleton
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg3, width: 8),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 90, height: 14),
                    const SizedBox(height: AppSpacing.sm),
                    _Bone(width: double.infinity, height: 10),
                    const SizedBox(height: AppSpacing.xs),
                    _Bone(width: 130, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  const _Bone({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardError — shown when TrustFailed
// ─────────────────────────────────────────────────────────────────────────────

class _CardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.textMuted,
            size: AppSpacing.iconLG,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load score',
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BreakdownSheet — modal bottom sheet opened by "View Breakdown"
// ─────────────────────────────────────────────────────────────────────────────

class _BreakdownSheet extends StatelessWidget {
  final TrustRecord record;
  const _BreakdownSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXL),
            ),
            border: Border(
              top: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    // Title
                    Text('Score Breakdown', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your score reflects available verification evidence and '
                      'protection setup. It does not guarantee safety.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Score display
                    _BreakdownScoreRow(record: record),

                    const SizedBox(height: AppSpacing.xl),
                    Divider(color: AppColors.divider, thickness: 1, height: 1),
                    const SizedBox(height: AppSpacing.xl),

                    // Step breakdown rows
                    _BreakdownStepRow(
                      label: 'Device Verification',
                      status: record.deviceStatus,
                      verifiedAt: record.deviceVerifiedAt,
                      reason: record.deviceStatusReason,
                      icon: Icons.smartphone_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _BreakdownStepRow(
                      label: 'Identity Verification',
                      status: record.identityStatus,
                      verifiedAt: record.identityVerifiedAt,
                      reason: record.identityStatusReason,
                      icon: Icons.badge_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _BreakdownStepRow(
                      label: 'Protection Activation',
                      status: record.protectionStatus,
                      verifiedAt: record.protectionActivatedAt,
                      reason: record.protectionStatusReason,
                      icon: Icons.shield_rounded,
                    ),

                    const SizedBox(height: AppSpacing.xl2),

                    // Disclaimer
                    Container(
                      padding: AppSpacing.cardPaddingSmall,
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: AppSpacing.roundedMD,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: AppSpacing.iconSM,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Serious device findings remain visible '
                              'independently of the numeric score.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl3),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── _BreakdownScoreRow ────────────────────────────────────────────────────────

class _BreakdownScoreRow extends StatelessWidget {
  final TrustRecord record;
  const _BreakdownScoreRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final score = record.score;
    final color = score == null
        ? AppColors.textMuted
        : score >= 70
            ? AppColors.trusted
            : score >= 40
                ? AppColors.warning
                : AppColors.danger;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          score != null ? '$score' : '—',
          style: GoogleFonts.rajdhani(
            fontSize: 52,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '/ 100',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            Text(
              'TRUST SCORE',
              style: AppTextStyles.scoreLabel,
            ),
          ],
        ),
        const Spacer(),
        if (record.isCached)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: AppDecorations.chipDecoration(AppColors.warning),
            child: Text(
              'CACHED',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.warning,
                fontSize: 9,
              ),
            ),
          ),
      ],
    );
  }
}

// ── _BreakdownStepRow ─────────────────────────────────────────────────────────

class _BreakdownStepRow extends StatelessWidget {
  final String label;
  final VerificationStatus status;
  final DateTime? verifiedAt;
  final String? reason;
  final IconData icon;

  const _BreakdownStepRow({
    required this.label,
    required this.status,
    required this.icon,
    this.verifiedAt,
    this.reason,
  });

  Color get _statusColor {
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
        return AppColors.textMuted;
    }
  }

  String? get _timestampLabel {
    if (verifiedAt == null) return null;
    final d = verifiedAt!;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPaddingSmall,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: AppSpacing.roundedMD,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Icon chip
          Container(
            width: 36,
            height: 36,
            decoration: AppDecorations.iconBg(_statusColor, radius: 10),
            child: Icon(icon, size: 17, color: _statusColor),
          ),
          const SizedBox(width: AppSpacing.md),

          // Label + status + reason
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration:
                          AppDecorations.chipDecoration(_statusColor),
                      child: Text(
                        status.label.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _statusColor,
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    if (_timestampLabel != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '· $_timestampLabel',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
                if (reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

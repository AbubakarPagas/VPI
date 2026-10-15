/// Notification bell button for the dashboard app bar.
///
/// Shows a badge only when [unreadCount] is greater than zero.
/// Counts above 99 are displayed as "99+".
///
/// When [onTap] is null the button is still rendered but is non-interactive
/// (used when the Alerts destination is unavailable in this stage).
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class NotificationBell extends StatelessWidget {
  /// Number of unread alerts.  0 or negative → no badge shown.
  final int unreadCount;

  /// Called when the button is tapped.  Null → shows unavailable snackbar.
  final VoidCallback? onTap;

  const NotificationBell({super.key, this.unreadCount = 0, this.onTap});

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasBadge = unreadCount > 0;
    final badgeLabel = unreadCount > 99 ? '99+' : '$unreadCount';

    return Semantics(
      label: hasBadge ? 'Notifications, $badgeLabel unread' : 'Notifications',
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          onTap: onTap,
          splashColor: AppColors.blueGlow20,
          highlightColor: AppColors.blueGlow10,
          child: Container(
            // Minimum 44 × 44 touch target.
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: const EdgeInsets.all(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primaryBright,
                  size: AppSpacing.iconMD,
                ),
                if (hasBadge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: _Badge(label: badgeLabel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    // "99+" is three characters — widen the pill slightly.
    final isWide = label.length > 2;

    return Container(
      constraints: BoxConstraints(minWidth: isWide ? 26 : 18, minHeight: 18),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 4 : 3, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.bg1, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

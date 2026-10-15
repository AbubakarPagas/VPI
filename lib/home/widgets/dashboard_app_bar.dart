/// Professional three-area dashboard app bar.
///
/// Layout:
///   LEFT   — [DashboardAvatar] (photo or initials; taps to profile)
///   CENTRE — "Welcome back" + user's full name
///   RIGHT  — [NotificationBell] (badge when unreadCount > 0)
///
/// States:
///   • Loading  — skeleton placeholders for avatar and name
///   • Loaded   — real profile data
///   • Error    — muted fallback text, avatar shows "?"
///
/// [preferredSize] is set to 72 px so Scaffold's [appBar] slot measures it
/// correctly without overlapping the status bar (SafeArea is on the Scaffold).
library;

import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'dashboard_avatar.dart';
import 'notification_bell.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Current profile state from [DashboardController].
  final DashboardProfileState profileState;

  /// Called when the user taps the avatar.  Null → shows unavailable message.
  final VoidCallback? onAvatarTap;

  /// Called when the user taps the bell.  Null → shows unavailable message.
  final VoidCallback? onBellTap;

  /// Unread alert count.  0 → no badge.
  final int unreadCount;

  const DashboardAppBar({
    super.key,
    required this.profileState,
    this.onAvatarTap,
    this.onBellTap,
    this.unreadCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── LEFT: Avatar ─────────────────────────────────────────────────
          _buildAvatar(),

          const SizedBox(width: AppSpacing.md),

          // ── CENTRE: Greeting ─────────────────────────────────────────────
          Expanded(child: _buildGreeting()),

          const SizedBox(width: AppSpacing.sm),

          // ── RIGHT: Bell ──────────────────────────────────────────────────
          NotificationBell(unreadCount: unreadCount, onTap: onBellTap),
        ],
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    switch (profileState) {
      case ProfileLoading():
        return const DashboardAvatarSkeleton(size: AppSpacing.avatarMD);

      case ProfileLoaded(:final profile):
        return DashboardAvatar(
          initials: profile.initials,
          photoUrl: profile.photoUrl,
          onTap: onAvatarTap,
          size: AppSpacing.avatarMD,
        );

      case ProfileFailed():
        // Show a "?" avatar — still tappable so the user can navigate.
        return DashboardAvatar(
          initials: '?',
          onTap: onAvatarTap,
          size: AppSpacing.avatarMD,
        );
    }
  }

  // ── Greeting ──────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    switch (profileState) {
      case ProfileLoading():
        return const _GreetingSkeleton();

      case ProfileLoaded(:final profile):
        return _GreetingText(
          name: profile.hasName ? profile.displayName : null,
        );

      case ProfileFailed():
        return _GreetingText(name: null);
    }
  }
}

// ── _GreetingText ─────────────────────────────────────────────────────────────

class _GreetingText extends StatelessWidget {
  /// Null when profile is unavailable — falls back to a neutral phrase.
  final String? name;

  const _GreetingText({this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          name ?? 'VPI User',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── _GreetingSkeleton ─────────────────────────────────────────────────────────

class _GreetingSkeleton extends StatelessWidget {
  const _GreetingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonLine(width: 80, height: 10),
        const SizedBox(height: 6),
        _SkeletonLine(width: 140, height: 14),
      ],
    );
  }
}

// ── _SkeletonLine ─────────────────────────────────────────────────────────────

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, required this.height});

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

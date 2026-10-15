/// Circular profile avatar for the dashboard app bar.
///
/// Shows a network image when [photoUrl] is a valid URL, otherwise renders
/// the user's initials on a gradient background.
///
/// Visual spec:
///   • 44 × 44 dp touch target (comfortable 48 dp minimum is met by the
///     surrounding [InkWell] splash).
///   • 1.5 px [AppColors.primaryBright] border ring.
///   • Subtle static blue glow via [BoxShadow] — no animation.
///   • Press feedback via [InkWell] with a circular [InkSplash].
///   • Graceful fallback to initials when the image 404s or times out.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DashboardAvatar extends StatelessWidget {
  /// URL of the user's profile photo.  Null or empty → initials fallback.
  final String? photoUrl;

  /// Up to two uppercase initials rendered when there is no photo.
  final String initials;

  /// Called when the avatar is tapped.
  final VoidCallback? onTap;

  /// Diameter of the avatar circle, defaults to 44.
  final double size;

  const DashboardAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.onTap,
    this.size = 44,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _hasPhoto {
    final url = photoUrl;
    return url != null && url.trim().isNotEmpty;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile avatar${initials.isNotEmpty ? " for $initials" : ""}',
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          splashColor: AppColors.blueGlow20,
          highlightColor: AppColors.blueGlow10,
          child: _AvatarCircle(
            size: size,
            initials: initials,
            photoUrl: _hasPhoto ? photoUrl! : null,
          ),
        ),
      ),
    );
  }
}

// ── _AvatarCircle ─────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final double size;
  final String initials;
  final String? photoUrl;

  const _AvatarCircle({
    required this.size,
    required this.initials,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Blue border ring
        border: Border.all(color: AppColors.primaryBright, width: 1.5),
        // Restrained static glow
        boxShadow: const [
          BoxShadow(
            color: AppColors.blueGlow20,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Graceful fallback when the image fails to load.
                errorBuilder: (context, error, stackTrace) =>
                    _InitialsCircle(size: size, initials: initials),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  // Show initials while image loads.
                  return _InitialsCircle(size: size, initials: initials);
                },
              )
            : _InitialsCircle(size: size, initials: initials),
      ),
    );
  }
}

// ── _InitialsCircle ───────────────────────────────────────────────────────────

class _InitialsCircle extends StatelessWidget {
  final double size;
  final String initials;

  const _InitialsCircle({required this.size, required this.initials});

  @override
  Widget build(BuildContext context) {
    // Font size scales proportionally with avatar size.
    final fontSize = (size * 0.35).clamp(12.0, 24.0);

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: AppColors.blueSweep),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: AppTextStyles.bodyStrong.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1,
        ),
      ),
    );
  }
}

// ── Skeleton variant ──────────────────────────────────────────────────────────

/// Shimmer-free loading placeholder that matches the avatar's footprint.
class DashboardAvatarSkeleton extends StatelessWidget {
  final double size;
  const DashboardAvatarSkeleton({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg3,
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
    );
  }
}

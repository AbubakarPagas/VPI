/// VPI Secure — Profile Screen.
///
/// Displays the authenticated user's profile information and provides:
///   • Display name, phone number, and account metadata.
///   • Inline name-edit via a modal bottom sheet.
///   • Sign-out action.
///
/// Architecture:
///   • [ProfileScreen] is a [StatefulWidget] that owns its own
///     [UserProfileService] instance and loads the profile once on mount.
///   • Name changes are written via [UserProfileService.saveFullName] and
///     reflected immediately in the UI on success.
///   • The screen never receives the [UserProfile] as a constructor argument
///     — it always reads from Firestore so the data is never stale from a
///     prior dashboard load.
///   • Sign-out delegates to [FirebaseAuth] — the [SessionGate] routes back
///     to onboarding automatically.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/services/user_profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/dashboard_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final User user;

  /// When [true] this screen is rendered as a bottom-nav tab body.
  /// The back button is hidden — the user switches tabs instead.
  final bool isTab;

  const ProfileScreen({super.key, required this.user, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = UserProfileService();

  // ── Local state ───────────────────────────────────────────────────────────

  /// null  → loading
  /// UserProfile → loaded (may have empty name if incomplete)
  /// String → error message
  Object? _state; // null | UserProfile | String

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() => _state = null);
    final resolution = await _service.resolveProfile(widget.user);
    if (!mounted) return;
    switch (resolution) {
      case ProfileComplete(:final data):
        setState(() => _state = UserProfile.fromMap(data));
      case ProfileIncomplete():
        setState(() => _state = UserProfile.anonymous(widget.user.uid));
      case ProfileMissing():
        setState(() => _state = UserProfile.anonymous(widget.user.uid));
      case ProfileError(:final message):
        setState(() => _state = message);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onEditName() async {
    final profile = _state is UserProfile ? _state as UserProfile : null;
    final updated = await showModalBottomSheet<UserProfile?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditNameSheet(
        user: widget.user,
        service: _service,
        currentName: profile?.displayName ?? '',
      ),
    );
    if (updated != null && mounted) {
      setState(() => _state = updated);
    }
  }

  Future<void> _onSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          _SignOutDialog(onConfirm: () => Navigator.pop(ctx, true)),
    );
    if (confirmed == true && mounted) {
      await FirebaseAuth.instance.signOut();
      // SessionGate handles navigation back to onboarding.
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          // Background gradient
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SizedBox.expand(),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.isTab ? AppSpacing.base : AppSpacing.sm,
        widget.isTab ? AppSpacing.md : AppSpacing.xs,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          // Back button — hidden when rendered as a tab
          if (!widget.isTab) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              iconSize: 20,
              color: AppColors.primaryBright,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],

          // Section icon (shown only in tab mode for visual balance)
          if (widget.isTab) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryGlass,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                border: Border.all(color: AppColors.blueGlow20, width: 1),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primaryBright,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          Text('Profile', style: AppTextStyles.h3),
          const Spacer(),
          // Edit name shortcut
          if (_state is UserProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              iconSize: 20,
              color: AppColors.primaryBright,
              tooltip: 'Edit name',
              onPressed: _onEditName,
            ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_state == null) return const _LoadingBody();
    if (_state is String) {
      return _ErrorBody(message: _state as String, onRetry: _loadProfile);
    }
    final profile = _state as UserProfile;
    return _ProfileBody(
      profile: profile,
      onEditName: _onEditName,
      onSignOut: _onSignOut,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileBody
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditName;
  final VoidCallback onSignOut;

  const _ProfileBody({
    required this.profile,
    required this.onEditName,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // ── Avatar ──────────────────────────────────────────────────────
          DashboardAvatar(
                initials: profile.initials,
                photoUrl: profile.photoUrl,
                size: AppSpacing.avatarXL,
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 450.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: AppSpacing.lg),

          // ── Name ────────────────────────────────────────────────────────
          Text(
            profile.hasName ? profile.displayName : 'No name set',
            style: AppTextStyles.h2.copyWith(
              color: profile.hasName
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 80.ms).fadeIn(duration: 350.ms),

          const SizedBox(height: AppSpacing.xs),

          // ── Phone number ─────────────────────────────────────────────────
          Text(
            profile.phoneNumber.isNotEmpty ? profile.phoneNumber : '—',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ).animate(delay: 120.ms).fadeIn(duration: 350.ms),

          const SizedBox(height: AppSpacing.xl2),

          // ── Info cards ───────────────────────────────────────────────────
          ..._buildInfoCards(context),

          const SizedBox(height: AppSpacing.xl2),

          // ── Edit name button ─────────────────────────────────────────────
          _ActionButton(
                icon: Icons.edit_rounded,
                label: 'Edit Name',
                onTap: onEditName,
              )
              .animate(delay: 300.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.08, end: 0),

          const SizedBox(height: AppSpacing.md),

          // ── Sign out button ──────────────────────────────────────────────
          _ActionButton(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                color: AppColors.danger,
                onTap: onSignOut,
              )
              .animate(delay: 360.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.08, end: 0),

          const SizedBox(height: AppSpacing.xl3),
        ],
      ),
    );
  }

  List<Widget> _buildInfoCards(BuildContext context) {
    return [
      _InfoCard(
            label: 'Account UID',
            value: profile.uid.isNotEmpty ? profile.uid : '—',
            icon: Icons.fingerprint_rounded,
            monospace: true,
            copyable: profile.uid.isNotEmpty,
          )
          .animate(delay: 180.ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.08, end: 0),

      const SizedBox(height: AppSpacing.sm),

      _InfoCard(
            label: 'Profile Status',
            value: profile.profileCompleted ? 'Complete' : 'Incomplete',
            icon: profile.profileCompleted
                ? Icons.verified_rounded
                : Icons.pending_rounded,
            iconColor: profile.profileCompleted
                ? AppColors.trusted
                : AppColors.warning,
          )
          .animate(delay: 220.ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.08, end: 0),

      const SizedBox(height: AppSpacing.sm),

      _InfoCard(
            label: 'Authentication',
            value: 'Phone OTP',
            icon: Icons.phone_android_rounded,
          )
          .animate(delay: 260.ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.08, end: 0),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InfoCard
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final bool monospace;
  final bool copyable;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.monospace = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primaryBright;

    return Container(
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.roundedLG,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: copyable
              ? () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.bg3,
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSM,
                        ),
                      ),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                // Icon chip
                Container(
                  width: 38,
                  height: 38,
                  decoration: AppDecorations.iconBg(color, radius: 10),
                  child: Icon(icon, size: 18, color: color),
                ),

                const SizedBox(width: AppSpacing.md),

                // Label + value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: monospace
                            ? AppTextStyles.monoSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              )
                            : AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                if (copyable) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionButton
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryBright;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: AppSpacing.roundedLG,
        border: Border.all(color: c.withValues(alpha: 0.25), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.roundedLG,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: c.withValues(alpha: 0.08),
          highlightColor: c.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.base,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: c),
                const SizedBox(width: AppSpacing.md),
                Text(label, style: AppTextStyles.bodyStrong.copyWith(color: c)),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: c.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LoadingBody
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBright),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBody
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: AppSpacing.iconXL2,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditNameSheet  — modal bottom sheet for updating the full name
// ─────────────────────────────────────────────────────────────────────────────

class _EditNameSheet extends StatefulWidget {
  final User user;
  final UserProfileService service;
  final String currentName;

  const _EditNameSheet({
    required this.user,
    required this.service,
    required this.currentName,
  });

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;
  final _focus = FocusNode();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
    // Auto-focus after the sheet's enter animation completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _focus.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.service.saveFullName(widget.user, _ctrl.text);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    // Return the updated profile so the parent can update its state.
    final resolution = await widget.service.resolveProfile(widget.user);
    if (!mounted) return;

    UserProfile? updated;
    if (resolution is ProfileComplete) {
      updated = UserProfile.fromMap(resolution.data);
    }

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXL),
        ),
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: AppSpacing.xl + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: AppSpacing.lg),

          Text('Update Name', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your name is used across the app for identification.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Name field
          Form(
            key: _formKey,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: AppSpacing.roundedMD,
                border: Border.all(
                  color: _focus.hasFocus
                      ? AppColors.primary
                      : AppColors.outline,
                  width: _focus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              child: TextFormField(
                controller: _ctrl,
                focusNode: _focus,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
                onFieldSubmitted: (_) => _onSave(),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Please enter your full name.';
                  if (t.length < 2) return 'At least 2 characters required.';
                  if (t.length > 80) return 'Maximum 80 characters.';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Full name',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  contentPadding: AppSpacing.cardPaddingSmall,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),
          ),

          // Inline error
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Save button
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightMD,
            child: DecoratedBox(
              decoration: _saving
                  ? BoxDecoration(
                      color: AppColors.bg3,
                      borderRadius: AppSpacing.roundedMD,
                    )
                  : AppDecorations.buttonPrimary,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _saving ? null : _onSave,
                  borderRadius: AppSpacing.roundedMD,
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryBright,
                              ),
                            ),
                          )
                        : Text('Save', style: AppTextStyles.buttonMedium),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SignOutDialog
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _SignOutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedXL,
        side: const BorderSide(color: AppColors.divider),
      ),
      title: Text('Sign Out?', style: AppTextStyles.h3),
      content: Text(
        'You will be returned to the login screen.',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}

/// Dashboard state controller.
///
/// Owns the Firestore profile fetch for the authenticated user and exposes
/// a [DashboardProfileState] stream to the dashboard widget tree.
///
// ignore_for_file: prefer_initializing_formals
/// Lifecycle:
///   create in [State.initState] with the current [User],
///   call [dispose] in [State.dispose].
///
/// Stale-result safety:
///   [_fetchProfile] stores a generation counter so that a slow Firestore
///   round-trip started before [refresh] was called can never overwrite a
///   fresher result.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/services/user_profile_service.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({required User user, UserProfileService? profileService})
    : _user = user,
      _service = profileService ?? UserProfileService() {
    // Kick off the initial fetch immediately.
    _fetchProfile();
  }

  final User _user;
  final UserProfileService _service;

  // ── State ─────────────────────────────────────────────────────────────────

  DashboardProfileState _state = const ProfileLoading();
  int _generation = 0;

  /// Current profile-loading state consumed by the UI.
  DashboardProfileState get state => _state;

  /// Shorthand: true while the first load (or a retry) is in progress.
  bool get isLoading => _state is ProfileLoading;

  /// The successfully loaded profile, or null when loading / errored.
  UserProfile? get profile =>
      _state is ProfileLoaded ? (_state as ProfileLoaded).profile : null;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Triggers a fresh Firestore read.
  ///
  /// Called by the UI on the Retry button and can be called again after an
  /// account change. Safe to call multiple times; only the last call wins.
  void refresh() => _fetchProfile();

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _fetchProfile() async {
    final gen = ++_generation;

    _setState(const ProfileLoading());

    final resolution = await _service.resolveProfile(_user);

    // Discard stale results from a superseded fetch.
    if (gen != _generation || _isDisposed) return;

    switch (resolution) {
      case ProfileComplete(:final data):
        _setState(ProfileLoaded(UserProfile.fromMap(data)));

      case ProfileIncomplete():
        // Profile is technically readable but name is missing.
        // Reuse whatever data came back as an anonymous placeholder so the
        // UI can show the phone number at minimum; routing to the completion
        // screen is handled by SessionGate, not here.
        _setState(ProfileLoaded(UserProfile.anonymous(_user.uid)));

      case ProfileMissing():
        _setState(ProfileLoaded(UserProfile.anonymous(_user.uid)));

      case ProfileError(:final message):
        _setState(ProfileFailed(message));
    }
  }

  void _setState(DashboardProfileState s) {
    _state = s;
    notifyListeners();
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// TrustController — manages trust / verification state for the dashboard.
///
/// Lifecycle: create in [State.initState] with the authenticated [User]; call
/// [dispose] in [State.dispose].  The controller fetches once on creation and
/// exposes [refresh()] for explicit reloads (e.g. after returning from a
/// feature screen).
///
/// Stale-result safety: a generation counter (_gen) ensures that a slow fetch
/// started before [refresh] can never overwrite a newer result.
///
/// User-change safety: the controller is keyed to a single [User].  When the
/// signed-in account changes [VpiDashboardScreen] recreates the controller
/// with the new user, so stale data from a prior account is never shown.
// ignore_for_file: prefer_initializing_formals
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'trust_record.dart';
import 'trust_repository.dart';

class TrustController extends ChangeNotifier {
  TrustController({
    required User user,
    TrustRepository? repository,
  }) : _user = user,
       _repo = repository ?? TrustRepository() {
    _fetchTrust();
  }

  final User _user;
  final TrustRepository _repo;

  // ── State ─────────────────────────────────────────────────────────────────

  TrustState _state = const TrustLoading();
  int _gen = 0;
  bool _disposed = false;

  TrustState get state => _state;
  bool get isLoading => _state is TrustLoading;

  /// The loaded record, or null while loading / errored.
  TrustRecord? get record =>
      _state is TrustLoaded ? (_state as TrustLoaded).record : null;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Triggers a fresh Firestore read.  Safe to call multiple times;
  /// only the last call's result is applied.
  void refresh() => _fetchTrust();

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _fetchTrust() async {
    final gen = ++_gen;
    _set(const TrustLoading());

    final result = await _repo.fetch(_user);

    if (gen != _gen || _disposed) return;
    _set(result);
  }

  void _set(TrustState s) {
    _state = s;
    if (!_disposed) notifyListeners();
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// TrustRepository — reads trust / verification state from Firestore.
///
/// All trust data lives in the existing `users/{uid}` document in the `vpi-db`
/// Firestore database.  The repository reads that document and maps the
/// verification-related fields to a [TrustRecord].  It does not write any
/// data and does not fabricate scores.
///
/// Security notes:
///   • The client ONLY reads.  Verification status and trust score fields are
///     written exclusively by backend Cloud Functions and cannot be set by
///     this repository.
///   • The repository uses `Source.serverAndCache` so it works offline once
///     the document has been cached, and explicitly marks the returned record
///     as [TrustRecord.isCached] = true when it knows the data came only from
///     cache.
///   • Network or permission failures return a [TrustFailed] state; the caller
///     must not treat them as "no data".
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'trust_record.dart';

class TrustRepository {
  TrustRepository({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'vpi-db',
            );

  final FirebaseFirestore _db;

  static const _kCollection = 'users';
  static const _kTimeout = Duration(seconds: 10);

  // ── fetch ─────────────────────────────────────────────────────────────────

  /// Reads the `users/{uid}` document and returns a [TrustState].
  ///
  /// Returns [TrustLoaded] on success (even when trust fields are absent —
  /// that surfaces as an empty [TrustRecord]).
  /// Returns [TrustFailed] on network / permission errors.
  Future<TrustState> fetch(User user) async {
    try {
      // Attempt server + cache fetch.
      DocumentSnapshot<Map<String, dynamic>> snap;
      bool fromCache = false;

      try {
        snap = await _db
            .collection(_kCollection)
            .doc(user.uid)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(_kTimeout, onTimeout: () {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'deadline-exceeded',
            message: 'Trust data fetch timed out.',
          );
        });
        fromCache = snap.metadata.isFromCache;
      } on FirebaseException catch (e) when (e.code == 'deadline-exceeded') {
        // Fall back to cache-only to give the user something to look at.
        snap = await _db
            .collection(_kCollection)
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));
        fromCache = true;
      }

      if (!snap.exists || snap.data() == null) {
        // Document doesn't exist yet — return an empty record, not an error.
        return TrustLoaded(TrustRecord.empty());
      }

      return TrustLoaded(
        TrustRecord.fromMap(snap.data()!, isCached: fromCache),
      );
    } on FirebaseException catch (e) {
      return TrustFailed(_friendlyError(e));
    } catch (_) {
      return const TrustFailed(
        'Could not load your trust data. Please try again.',
      );
    }
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  static String _friendlyError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Access denied. Contact support if this persists.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'No internet connection. Check your network and retry.';
      default:
        return e.message ?? 'Could not reach the server. Please try again.';
    }
  }
}

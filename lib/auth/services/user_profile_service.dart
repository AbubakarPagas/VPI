/// User-profile resolution and write service.
///
/// ── Reading ───────────────────────────────────────────────────────────────
///   [resolveProfile] — reads `users/{uid}` and returns a typed
///   [ProfileResolution] so callers never make routing assumptions.
///
/// ── Writing ───────────────────────────────────────────────────────────────
///   [initProfile]   — creates the minimal profile document inside a
///   Firestore transaction that checks existence first, so a document is
///   never overwritten.  Called when [resolveProfile] returns [ProfileMissing].
///
///   [saveFullName]  — merge-updates fullName + audit fields on an existing
///   document.  Preserves all other fields including createdAt and any
///   trusted verification records.
///
/// ── Security notes ────────────────────────────────────────────────────────
///   • OTP codes, credentials, and verification IDs are never passed here.
///   • The [User.uid] is the only identifier used for Firestore lookups.
///   • [initProfile] writes only fixed bootstrap fields; it never touches
///     verification records.
///   • [saveFullName] is a merge; it cannot overwrite createdAt or any field
///     the client is not allowed to set.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// ── Result types ─────────────────────────────────────────────────────────────

/// Sealed result returned by [UserProfileService.resolveProfile].
sealed class ProfileResolution {
  const ProfileResolution();
}

/// Document found and [fullName] is a valid non-empty string.
/// Navigate to the dashboard.
final class ProfileComplete extends ProfileResolution {
  final Map<String, dynamic> data;
  const ProfileComplete(this.data);
}

/// Document found but [fullName] is missing, null, empty, or whitespace.
/// Navigate to the full-name completion screen.
final class ProfileIncomplete extends ProfileResolution {
  final List<String> missingFields;
  const ProfileIncomplete(this.missingFields);
}

/// No document found at `users/{uid}`.
/// Call [UserProfileService.initProfile], then navigate to the completion screen.
final class ProfileMissing extends ProfileResolution {
  const ProfileMissing();
}

/// Firestore read failed (network, permission, timeout, …).
/// Show a Retry — do NOT assume the document is missing.
final class ProfileError extends ProfileResolution {
  final String message;
  const ProfileError(this.message);
}

// ── Service ───────────────────────────────────────────────────────────────────

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'vpi-db',
          );

  final FirebaseFirestore _db;

  static const _collection = 'users';

  // ── resolveProfile ────────────────────────────────────────────────────────

  /// Reads `users/{user.uid}` and returns a [ProfileResolution].
  ///
  /// Uses `Source.serverAndCache` so it works offline once the document has
  /// been cached; falls back to the server on first run.
  Future<ProfileResolution> resolveProfile(User user) async {
    try {
      final doc = await _db
          .collection(_collection)
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'deadline-exceeded',
              message: 'Profile lookup timed out. Check your connection.',
            ),
          );

      if (!doc.exists || doc.data() == null) return const ProfileMissing();

      final data = doc.data()!;
      final name = data['fullName'];
      final nameOk = name is String && name.trim().isNotEmpty;
      if (!nameOk) {
        return ProfileIncomplete(const ['fullName']);
      }
      return ProfileComplete(data);
    } on FirebaseException catch (e) {
      return ProfileError(_friendlyFirestoreError(e));
    } catch (_) {
      return const ProfileError(
        'Could not load your profile. Please try again.',
      );
    }
  }

  // ── initProfile ───────────────────────────────────────────────────────────

  /// Creates a minimal profile document inside a **transaction** that
  /// re-checks existence before writing.
  ///
  /// This prevents accidental overwrites if two devices or two concurrent
  /// callbacks race to call this method simultaneously.
  ///
  /// Fields written (only on creation):
  ///   • `fullName`         — "" (intentionally empty; completion screen fills it)
  ///   • `nameSource`       — "self_declared"
  ///   • `profileCompleted` — false
  ///   • `phoneNumber`      — from [User.phoneNumber]
  ///   • `uid`              — [User.uid]
  ///   • `createdAt`        — server timestamp
  ///   • `updatedAt`        — server timestamp
  ///   • `schemaVersion`    — 1
  ///
  /// Returns `null` on success, or a user-facing error string on failure.
  Future<String?> initProfile(User user) async {
    try {
      final ref = _db.collection(_collection).doc(user.uid);
      await _db
          .runTransaction((tx) async {
            final snap = await tx.get(ref);
            // Another call already created the document — nothing to do.
            if (snap.exists) return;
            tx.set(ref, {
              'fullName': '',
              'nameSource': 'self_declared',
              'profileCompleted': false,
              'phoneNumber': user.phoneNumber ?? '',
              'uid': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'schemaVersion': 1,
            });
          })
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'deadline-exceeded',
              message: 'Profile creation timed out. Check your connection.',
            ),
          );
      return null;
    } on FirebaseException catch (e) {
      return _friendlyFirestoreError(e);
    } catch (_) {
      return 'Could not create your profile. Please try again.';
    }
  }

  // ── saveFullName ──────────────────────────────────────────────────────────

  /// Merge-updates `fullName`, `nameSource`, `profileCompleted`, and
  /// `updatedAt` on the existing document.
  ///
  /// Uses `update()` (not `set()`) so:
  ///   • `createdAt` is never touched.
  ///   • Trusted verification records are preserved.
  ///   • A missing document produces an error rather than silently creating one.
  ///
  /// Returns `null` on success, or a user-facing error string on failure.
  Future<String?> saveFullName(User user, String fullName) async {
    final trimmed = fullName.trim();
    try {
      await _db
          .collection(_collection)
          .doc(user.uid)
          .update({
            'fullName': trimmed,
            'nameSource': 'self_declared',
            'profileCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'deadline-exceeded',
              message: 'Profile update timed out. Check your connection.',
            ),
          );
      return null;
    } on FirebaseException catch (e) {
      return _friendlyFirestoreError(e);
    } catch (_) {
      return 'Could not update your profile. Please try again.';
    }
  }

  // ── Legacy alias — kept so PhoneOtpScreen still compiles ─────────────────

  /// Deprecated alias for [initProfile].  New code should call [initProfile].
  @Deprecated('Use initProfile() instead.')
  Future<String?> writeProfile(User user) => initProfile(user);

  /// Deprecated alias for [saveFullName].  New code should call [saveFullName].
  @Deprecated('Use saveFullName() instead.')
  Future<String?> updateFullName(User user, String fullName) =>
      saveFullName(user, fullName);

  // ── Error helpers ─────────────────────────────────────────────────────────

  static String _friendlyFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Access denied. Contact support if this persists.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'No internet connection. Check your network and retry.';
      case 'not-found':
        return 'Profile not found.';
      default:
        return e.message ?? 'Could not reach the server. Please try again.';
    }
  }
}

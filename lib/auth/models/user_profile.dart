/// Typed Dart model for the Firestore `users/{uid}` document.
///
/// Field names mirror those written by [UserProfileService]:
///   fullName, phoneNumber, uid, profileCompleted, nameSource,
///   schemaVersion, createdAt, updatedAt.
///
/// [fromMap] is deliberately lenient — it never throws on missing or
/// unexpected fields so that a partial document (e.g. written by an older
/// schema version) still parses cleanly.
library;

/// Immutable, value-typed representation of a VPI Secure user profile.
class UserProfile {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final bool profileCompleted;
  final String nameSource;
  final int schemaVersion;

  /// Optional URL for the user's profile photo.
  ///
  /// Not written by the current schema — reserved for a future profile-photo
  /// upload feature. Included here so the dashboard can consume it when it
  /// becomes available without a model change.
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.profileCompleted,
    this.nameSource = 'self_declared',
    this.schemaVersion = 1,
    this.photoUrl,
  });

  // ── Factory constructors ──────────────────────────────────────────────────

  /// Creates a [UserProfile] from a Firestore document map.
  ///
  /// Missing or wrongly-typed fields fall back to safe defaults rather than
  /// throwing, so the dashboard never crashes on a partial document.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: _str(map['uid']),
      fullName: _str(map['fullName']),
      phoneNumber: _str(map['phoneNumber']),
      profileCompleted: map['profileCompleted'] == true,
      nameSource: _str(map['nameSource'], fallback: 'self_declared'),
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      photoUrl: map['photoUrl'] is String
          ? (map['photoUrl'] as String).trim().isEmpty
                ? null
                : map['photoUrl'] as String
          : null,
    );
  }

  /// Creates an empty/anonymous profile for the loading-skeleton state.
  ///
  /// [uid] is required so the controller can still key on the user.
  factory UserProfile.anonymous(String uid) => UserProfile(
    uid: uid,
    fullName: '',
    phoneNumber: '',
    profileCompleted: false,
  );

  // ── Derived helpers ───────────────────────────────────────────────────────

  /// The display name trimmed and ready for the UI.
  String get displayName => fullName.trim();

  /// Whether a usable full name exists.
  bool get hasName => displayName.isNotEmpty;

  /// Derives up to two uppercase initials from [fullName].
  ///
  /// Rules:
  ///   - Split on whitespace, take first character of each part.
  ///   - Return at most two characters (first + last name initial).
  ///   - Fall back to a single '?' when the name is empty.
  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Converts back to a plain map (useful for testing / local cache).
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'profileCompleted': profileCompleted,
    'nameSource': nameSource,
    'schemaVersion': schemaVersion,
    if (photoUrl != null) 'photoUrl': photoUrl,
  };

  // ── Equality & toString ───────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.uid == uid &&
          other.fullName == fullName &&
          other.phoneNumber == phoneNumber &&
          other.profileCompleted == profileCompleted &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode =>
      Object.hash(uid, fullName, phoneNumber, profileCompleted, photoUrl);

  @override
  String toString() =>
      'UserProfile(uid: $uid, name: $fullName, completed: $profileCompleted)';

  // ── Private helpers ───────────────────────────────────────────────────────

  static String _str(dynamic value, {String fallback = ''}) {
    if (value is String) return value;
    return fallback;
  }
}

/// Sealed union for the dashboard profile-loading state.
sealed class DashboardProfileState {
  const DashboardProfileState();
}

/// Profile is being fetched from Firestore.
final class ProfileLoading extends DashboardProfileState {
  const ProfileLoading();
}

/// Profile loaded successfully.
final class ProfileLoaded extends DashboardProfileState {
  final UserProfile profile;
  const ProfileLoaded(this.profile);
}

/// Firestore read failed — [message] is user-facing.
final class ProfileFailed extends DashboardProfileState {
  final String message;
  const ProfileFailed(this.message);
}

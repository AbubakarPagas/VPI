/// VPI Secure — Trust domain models.
///
/// [VerificationStatus] is the single source of truth for how a step's
/// state is communicated to the UI.  Mapping from raw Firestore data to a
/// [VerificationStatus] is the repository's responsibility — widgets never
/// inspect raw strings.
///
/// [TrustRecord] is an immutable snapshot of everything the dashboard's
/// Trust Score card and Completion Steps need.  It is intentionally read-only
/// from the client's perspective: the only writer is a trusted backend or a
/// Firestore Cloud Function — the client never fabricates a score or marks a
/// step completed on its own.
///
/// [TrustState] is the sealed loading/loaded/failed union passed up to the
/// UI by [TrustController].
library;

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VerificationStatus
// ─────────────────────────────────────────────────────────────────────────────

/// The state of a single verification step.
///
/// Mapping contract (applied by [TrustRepository]):
///   Firestore field absent / null          → [notStarted]
///   status == 'not_started' / ''           → [notStarted]
///   status == 'in_progress'                → [inProgress]
///   status == 'completed'                  → [completed]
///   status == 'needs_attention'            → [needsAttention]
///   status == 'unavailable'                → [unavailable]
///   Firestore permission/network failure   → [error] (surfaced via TrustState)
enum VerificationStatus {
  /// No record found — the user has not started this step.
  notStarted,

  /// The verification process has been initiated but not yet concluded.
  inProgress,

  /// An authoritative backend record confirms this step is done.
  /// Phone OTP and self-declared name do NOT qualify.
  completed,

  /// The step was previously completed but now requires the user's attention
  /// (e.g. a document expired, a device was flagged).
  needsAttention,

  /// The step is temporarily blocked (e.g. service outage, region restriction).
  unavailable,
}

extension VerificationStatusX on VerificationStatus {
  /// Human-readable label shown in the UI.
  String get label {
    switch (this) {
      case VerificationStatus.notStarted:
        return 'Not started';
      case VerificationStatus.inProgress:
        return 'In progress';
      case VerificationStatus.completed:
        return 'Completed';
      case VerificationStatus.needsAttention:
        return 'Needs attention';
      case VerificationStatus.unavailable:
        return 'Unavailable';
    }
  }

  bool get isDone => this == VerificationStatus.completed;
  bool get isActionable =>
      this == VerificationStatus.notStarted ||
      this == VerificationStatus.inProgress ||
      this == VerificationStatus.needsAttention;
}

// ─────────────────────────────────────────────────────────────────────────────
// TrustRecord
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of a user's trust state as read from Firestore.
///
/// Score semantics:
///   • [score] is `null`  → no authoritative score exists yet — show "— / 100".
///   • [score] is present → a backend-computed value 0–100.
///   The client never calculates or stores a score; it only reads it.
///
/// Firestore field names (all under `users/{uid}`):
///   `trustScore`            — int?          backend-computed score 0–100
///   `trustScoreUpdatedAt`   — Timestamp?    when the score was last set
///   `deviceVerificationStatus`   — String   one of the VerificationStatus raw values
///   `identityVerificationStatus` — String
///   `protectionStatus`           — String
///   `deviceVerifiedAt`      — Timestamp?
///   `identityVerifiedAt`    — Timestamp?
///   `protectionActivatedAt` — Timestamp?
///   `deviceId`              — String?       the device this record is associated with
@immutable
class TrustRecord {
  final int? score;
  final DateTime? scoreUpdatedAt;
  final bool isCached;

  final VerificationStatus deviceStatus;
  final DateTime? deviceVerifiedAt;

  final VerificationStatus identityStatus;
  final DateTime? identityVerifiedAt;

  final VerificationStatus protectionStatus;
  final DateTime? protectionActivatedAt;

  /// The device ID this record is tied to.  Null if not yet written.
  final String? deviceId;

  /// Freeform reason strings surfaced in the breakdown sheet.
  /// The backend may write short human-readable explanations into these fields.
  final String? deviceStatusReason;
  final String? identityStatusReason;
  final String? protectionStatusReason;

  const TrustRecord({
    this.score,
    this.scoreUpdatedAt,
    this.isCached = false,
    this.deviceStatus = VerificationStatus.notStarted,
    this.deviceVerifiedAt,
    this.identityStatus = VerificationStatus.notStarted,
    this.identityVerifiedAt,
    this.protectionStatus = VerificationStatus.notStarted,
    this.protectionActivatedAt,
    this.deviceId,
    this.deviceStatusReason,
    this.identityStatusReason,
    this.protectionStatusReason,
  });

  // ── Derived helpers ───────────────────────────────────────────────────────

  /// Number of steps that have been authoritatively completed (0–3).
  int get completedSteps => [
    deviceStatus.isDone,
    identityStatus.isDone,
    protectionStatus.isDone,
  ].where((v) => v).length;

  /// True when no step has any authoritative data.
  bool get isFullyEmpty =>
      deviceStatus == VerificationStatus.notStarted &&
      identityStatus == VerificationStatus.notStarted &&
      protectionStatus == VerificationStatus.notStarted &&
      score == null;

  // ── Factory constructors ──────────────────────────────────────────────────

  /// Creates a [TrustRecord] from the `users/{uid}` Firestore document map.
  ///
  /// Lenient: any absent, null, or unrecognised field is treated as the safe
  /// default rather than throwing.
  factory TrustRecord.fromMap(Map<String, dynamic> map, {bool isCached = false}) {
    return TrustRecord(
      score: _intOrNull(map['trustScore']),
      scoreUpdatedAt: _tsToDateTime(map['trustScoreUpdatedAt']),
      isCached: isCached,
      deviceStatus: _statusFrom(map['deviceVerificationStatus']),
      deviceVerifiedAt: _tsToDateTime(map['deviceVerifiedAt']),
      identityStatus: _statusFrom(map['identityVerificationStatus']),
      identityVerifiedAt: _tsToDateTime(map['identityVerifiedAt']),
      protectionStatus: _statusFrom(map['protectionStatus']),
      protectionActivatedAt: _tsToDateTime(map['protectionActivatedAt']),
      deviceId: map['deviceId'] is String ? map['deviceId'] as String : null,
      deviceStatusReason: _strOrNull(map['deviceStatusReason']),
      identityStatusReason: _strOrNull(map['identityStatusReason']),
      protectionStatusReason: _strOrNull(map['protectionStatusReason']),
    );
  }

  /// An empty record — used as the initial state before any Firestore data.
  factory TrustRecord.empty() => const TrustRecord();

  // ── Private helpers ───────────────────────────────────────────────────────

  static VerificationStatus _statusFrom(dynamic raw) {
    if (raw is! String) return VerificationStatus.notStarted;
    switch (raw.trim().toLowerCase()) {
      case 'in_progress':
        return VerificationStatus.inProgress;
      case 'completed':
        return VerificationStatus.completed;
      case 'needs_attention':
        return VerificationStatus.needsAttention;
      case 'unavailable':
        return VerificationStatus.unavailable;
      default:
        return VerificationStatus.notStarted;
    }
  }

  static int? _intOrNull(dynamic v) {
    if (v is int) return v.clamp(0, 100);
    if (v is double) return v.clamp(0, 100).round();
    return null;
  }

  static DateTime? _tsToDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static String? _strOrNull(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrustRecord &&
          other.score == score &&
          other.deviceStatus == deviceStatus &&
          other.identityStatus == identityStatus &&
          other.protectionStatus == protectionStatus;

  @override
  int get hashCode =>
      Object.hash(score, deviceStatus, identityStatus, protectionStatus);
}

// ─────────────────────────────────────────────────────────────────────────────
// TrustState  — sealed loading / loaded / failed union
// ─────────────────────────────────────────────────────────────────────────────

sealed class TrustState {
  const TrustState();
}

/// First load is in progress.
final class TrustLoading extends TrustState {
  const TrustLoading();
}

/// Data is available — may be [TrustRecord.isCached] == true.
final class TrustLoaded extends TrustState {
  final TrustRecord record;
  const TrustLoaded(this.record);
}

/// Firestore read failed.  [message] is user-facing.
final class TrustFailed extends TrustState {
  final String message;
  const TrustFailed(this.message);
}

/// VPI Secure — phone number masking utility.
///
/// Masks a phone number for display purposes only.
/// The original unmasked value must always be kept and passed
/// internally (e.g. to Firebase Phone Auth) — never the masked form.
///
/// Masking rules:
///   • International format (+CCXXXXXXXXXX):
///       Keep country code + first 1 digit, mask middle digits, show last 2.
///       e.g. "+2348034524290" → "+234 803 •••• 90"
///
///   • Local format (0XXXXXXXXXX, 11 digits):
///       Keep first 4 digits, mask middle, show last 2.
///       e.g. "08034524290" → "0803 •••• 90"
///
///   • Anything shorter than 6 digits: returned as-is (cannot mask safely).

String maskPhoneNumber(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');

  if (digits.isEmpty) return phone;

  // ── International E.164: +<country_code><subscriber_number> ───────────────
  if (digits.startsWith('+')) {
    // Strip the leading '+'
    final raw = digits.substring(1); // e.g. "2348034524290"

    // Nigerian numbers: country code is 3 digits (234).
    // Generic fallback: treat first 1–3 digits as country code.
    // Strategy: keep country_code + first digit of subscriber, mask middle,
    // always reveal last 2 digits.
    if (raw.length < 6) return phone; // too short to mask safely

    final countryCode = _extractCountryCode(raw); // e.g. "234"
    final subscriber = raw.substring(countryCode.length); // e.g. "8034524290"

    if (subscriber.length < 4) return phone;

    final visiblePrefix = subscriber.substring(0, 3); // "803"
    final visibleSuffix = subscriber.substring(subscriber.length - 2); // "90"
    const mask = ' •••• ';

    return '+$countryCode $visiblePrefix$mask$visibleSuffix';
    // Result: "+234 803 •••• 90"
  }

  // ── Local format: starts with 0, 10–11 digits ─────────────────────────────
  if (digits.startsWith('0') && digits.length >= 8) {
    final visiblePrefix = digits.substring(0, 4); // "0803"
    final visibleSuffix = digits.substring(digits.length - 2); // "90"
    const mask = ' •••• ';
    return '$visiblePrefix$mask$visibleSuffix';
    // Result: "0803 •••• 90"
  }

  // ── Fallback: mask everything except first 2 and last 2 ──────────────────
  if (digits.length < 6) return phone;
  final head = digits.substring(0, 2);
  final tail = digits.substring(digits.length - 2);
  final mid = '•' * (digits.length - 4);
  return '$head$mid$tail';
}

/// Infers the numeric country code from the raw digits (no leading '+').
/// Covers the most common lengths; defaults to 1-digit if unknown.
String _extractCountryCode(String raw) {
  // 3-digit country codes that are common / unambiguous
  const threedigit = {
    '234', // Nigeria
    '233', // Ghana
    '254', // Kenya
    '256', // Uganda
    '255', // Tanzania
    '251', // Ethiopia
    '250', // Rwanda
    '260', // Zambia
    '263', // Zimbabwe
    '27', // South Africa (2-digit, handled below)
    '212', // Morocco
    '213', // Algeria
    '216', // Tunisia
  };

  if (raw.length >= 3 && threedigit.contains(raw.substring(0, 3))) {
    return raw.substring(0, 3);
  }
  if (raw.length >= 2 && threedigit.contains(raw.substring(0, 2))) {
    return raw.substring(0, 2);
  }
  // USA/Canada (+1), generic fallback
  return raw.substring(0, 1);
}

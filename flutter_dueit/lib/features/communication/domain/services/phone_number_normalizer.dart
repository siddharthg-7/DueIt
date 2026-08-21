/// Pure helper class for validating, sanitizing, and normalizing phone numbers
/// specifically optimized for Indian mobile numbers (+91 / 10 digits) and standard WhatsApp deep linking.
class PhoneNumberNormalizer {
  /// Normalizes a raw phone string for WhatsApp deep linking.
  ///
  /// Returns a valid phone string with country code (e.g. "919876543210")
  /// or null if the number is invalid / cannot safely be normalized.
  static String? normalize(String? rawPhone) {
    if (rawPhone == null) return null;
    final trimmed = rawPhone.trim();
    if (trimmed.isEmpty) return null;

    // Remove all whitespace, dashes, dots, parentheses, and spaces
    String cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    // Strip leading '+'
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // 1. Standard 10-digit Indian Mobile number (starts with 6, 7, 8, or 9)
    if (RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return '91$cleaned';
    }

    // 2. 11-digit number with leading 0 (e.g., 09876543210)
    if (RegExp(r'^0[6-9]\d{9}$').hasMatch(cleaned)) {
      return '91${cleaned.substring(1)}';
    }

    // 3. 12-digit number already prefixed with 91 (e.g., 919876543210)
    if (RegExp(r'^91[6-9]\d{9}$').hasMatch(cleaned)) {
      return cleaned;
    }

    // 4. Valid International E.164 without plus (10 to 15 digits)
    if (RegExp(r'^[1-9]\d{9,14}$').hasMatch(cleaned)) {
      return cleaned;
    }

    return null;
  }

  /// Returns true if the raw phone number can be normalized.
  static bool isValid(String? rawPhone) {
    return normalize(rawPhone) != null;
  }

  /// Formats the normalized or raw number for readable UI display.
  /// Example: "919876543210" -> "+91 98765 43210"
  static String formatDisplay(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return '';
    final normalized = normalize(rawPhone);
    if (normalized != null &&
        normalized.startsWith('91') &&
        normalized.length == 12) {
      final national = normalized.substring(2);
      return '+91 ${national.substring(0, 5)} ${national.substring(5)}';
    }
    return rawPhone.trim();
  }
}

class PhoneUtils {
  PhoneUtils._();

  /// Normalize phone for storage and uniqueness checks.
  /// Keeps leading + if present; strips spaces and punctuation.
  static String normalize(String phone) {
    final trimmed = phone.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return hasPlus ? '+$digits' : digits;
  }

  static String digitsOnly(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }
}

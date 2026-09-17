/// Result of evaluating an international telephone number format.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});
}

/// Validates phone numbers according to the international E.164 standard.
/// Must include a leading '+' and country dialing code (e.g. +234 for Nigeria).
class PhoneValidator {
  static final RegExp _e164Regex = RegExp(r'^\+[1-9]\d{7,14}$');

  static ValidationResult validate(String rawNumber) {
    final trimmed = rawNumber.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Phone number cannot be empty.',
      );
    }
    if (!trimmed.startsWith('+')) {
      return const ValidationResult(
        isValid: false,
        errorMessage: "Missing '+' and international country dialing code (e.g. +234...).",
      );
    }
    if (!_e164Regex.hasMatch(trimmed)) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Invalid phone format. Must be E.164 compliant (+ followed by 8 to 15 digits).',
      );
    }
    return const ValidationResult(isValid: true);
  }
}

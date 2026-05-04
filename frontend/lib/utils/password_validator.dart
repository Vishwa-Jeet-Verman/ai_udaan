/// Password Validation Utility for Flutter
/// Enforces Moodle-compatible password requirements
library;

class PasswordValidator {
  static const int minLength = 8;
  static const String specialCharacters = '*-#!@\$%^&+=_~';

  /// Validate password against Moodle requirements
  /// Returns a map with isValid and error messages
  static PasswordValidationResult validatePassword(String password) {
    final errors = <String>[];

    if (password.isEmpty) {
      return PasswordValidationResult(
        isValid: false,
        errors: ['Password is required'],
      );
    }

    // Check minimum length
    if (password.length < minLength) {
      errors.add('Passwords must be at least $minLength characters long.');
    }

    // Check for at least 1 lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Passwords must have at least 1 lower case letter(s).');
    }

    // Check for at least 1 uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Passwords must have at least 1 upper case letter(s).');
    }

    // Check for at least 1 special character
    if (!specialCharacters.split('').any((char) => password.contains(char))) {
      errors.add(
        'The password must have at least 1 special character(s) such as *, -, #, !, @, \$, %, ^, &, +, =, _, ~.',
      );
    }

    return PasswordValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Get a single requirement check status
  /// Returns null if requirement is met, otherwise error message
  static String? validateRequirement(String password, String requirement) {
    if (password.isEmpty) return null;

    switch (requirement) {
      case 'minLength':
        return password.length >= minLength ? null : 'At least 8 characters';
      case 'lowercase':
        return password.contains(RegExp(r'[a-z]'))
            ? null
            : 'At least 1 lower case letter';
      case 'uppercase':
        return password.contains(RegExp(r'[A-Z]'))
            ? null
            : 'At least 1 upper case letter';
      case 'special':
        return specialCharacters
                .split('')
                .any((char) => password.contains(char))
            ? null
            : 'At least 1 special character';
      default:
        return null;
    }
  }

  /// Get all password requirements text
  static List<String> getRequirements() => [
    'At least 8 characters',
    'At least 1 lower case letter',
    'At least 1 upper case letter',
    'At least 1 special character (*, -, #, !, @, \$, %, ^, &, +, =, _, ~)',
  ];
}

/// Result object for password validation
class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;

  PasswordValidationResult({required this.isValid, required this.errors});
}

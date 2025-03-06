// lib/core/utils/validation_utils.dart

class ValidationUtils {
  // Validation d'email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(email);
  }

  // Validation de mot de passe
  static bool isValidPassword(String password, {
    int minLength = 8,
    bool requireSpecialChar = true,
    bool requireNumber = true,
    bool requireUppercase = true,
  }) {
    if (password.length < minLength) return false;

    if (requireSpecialChar && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return false;
    }

    if (requireNumber && !password.contains(RegExp(r'\d'))) {
      return false;
    }

    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      return false;
    }

    return true;
  }

  // Validation de nom
  static bool isValidName(String name, {
    int minLength = 2,
    int maxLength = 50,
  }) {
    if (name.length < minLength || name.length > maxLength) return false;
    return RegExp(r'^[a-zA-ZÀ-ÿ\s-]+$').hasMatch(name);
  }

  // Validation numérique
  static bool isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  // Validation d'URL
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(url);
  }

  // Validation de téléphone (format français)
  static bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^(0|\+33)[1-9]([-. ]?[0-9]{2}){4}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  // Validation de code postal français
  static bool isValidPostalCode(String postalCode) {
    final postalCodeRegex = RegExp(r'^(0[1-9]|[1-9][0-9])\d{3}$');
    return postalCodeRegex.hasMatch(postalCode);
  }

  // Validation de date
  static bool isValidDate(String dateString) {
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Validation de plage de valeurs
  static bool isInRange(num value, {num? min, num? max}) {
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    return true;
  }

  // Sanitisation de texte
  static String sanitizeText(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Remplace multiples espaces
        .replaceAll(RegExp(r'[<>]'), ''); // Supprime certains caractères HTML
  }

  // Méthode générique de validation
  static bool validate(
      String value, {
        bool Function(String)? customValidator,
        int? minLength,
        int? maxLength,
        bool allowEmpty = false,
      }) {
    if (value.isEmpty) return allowEmpty;

    if (minLength != null && value.length < minLength) return false;
    if (maxLength != null && value.length > maxLength) return false;

    return customValidator?.call(value) ?? true;
  }
}
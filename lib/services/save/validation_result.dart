// lib/services/save/validation_result.dart

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic>? validatedData;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.validatedData,
  });
}
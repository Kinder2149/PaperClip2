// lib/services/save_system/save_error.dart

/// Exception personnalisée pour les erreurs de sauvegarde
class SaveError extends Error {
  final String code;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  SaveError(this.code, this.message, {this.originalError, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('SaveError[$code]: $message');
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    if (stackTrace != null) {
      buffer.write('\nStack trace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

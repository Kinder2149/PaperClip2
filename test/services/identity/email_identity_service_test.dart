import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/identity/email_identity_service.dart';

void main() {
  group('EmailIdentityService (DI légère)', () {
    test('linkEmailForCurrentUser ne jette pas sans initialisation Supabase', () async {
      final service = EmailIdentityService(
        initializeOverride: () async {},
      );

      await service.linkEmailForCurrentUser('user@example.com');
    });
  });
}

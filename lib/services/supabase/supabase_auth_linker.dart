import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthLinker {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Tente d'établir une session OAuth Google Supabase (cross-device).
  /// Sur mobile, nécessite un intent-filter pour le schéma:
  ///   io.supabase.flutter://login-callback
  static Future<void> ensureGoogleSession({bool force = false}) async {
    final hasSession = _client.auth.currentSession != null;
    if (hasSession && !force) return;

    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback',
      queryParams: {
        // 'prompt': 'consent', // optionnel: forcer l'écran de consentement
      },
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'identity_manager.dart';

class EmailIdentityService {
  final Future<void> Function()? _initializeOverride;
  final SupabaseClient Function()? _clientProvider;

  SupabaseClient get _client => (_clientProvider != null) ? _clientProvider!() : Supabase.instance.client;

  EmailIdentityService({Future<void> Function()? initializeOverride, SupabaseClient Function()? clientProvider})
      : _initializeOverride = initializeOverride,
        _clientProvider = clientProvider;

  Future<void> _ensureInitialized() async {
    if (_initializeOverride != null) {
      await _initializeOverride!();
      return;
    }
    if (!Supabase.instance.isInitialized) {
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (url == null || anonKey == null) {
        throw StateError('SUPABASE_URL / SUPABASE_ANON_KEY manquantes');
      }
      await Supabase.initialize(url: url, anonKey: anonKey);
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      return _client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<AuthResponse> signUpWithEmail({required String email, required String password}) async {
    await _ensureInitialized();
    final res = await _client.auth.signUp(email: email, password: password);
    try {
      await IdentityManager().syncLinkedProviders(email: email);
    } catch (_) {}
    return res;
  }

  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    await _ensureInitialized();
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    try {
      await IdentityManager().syncLinkedProviders(email: email);
    } catch (_) {}
    return res;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _client.auth.signOut();
  }

  Future<void> linkEmailForCurrentUser(String email) async {
    await IdentityManager().syncLinkedProviders(email: email);
  }
}

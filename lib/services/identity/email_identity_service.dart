class EmailIdentityService {
  EmailIdentityService();

  Future<String?> getCurrentUserId() async => null;

  Future<void> signUpWithEmail({required String email, required String password}) async {
    throw UnsupportedError('Email auth désactivée (Supabase retiré)');
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    throw UnsupportedError('Email auth désactivée (Supabase retiré)');
  }

  Future<void> signOut() async {}

  Future<void> linkEmailForCurrentUser(String email) async {}
}

import 'package:shared_preferences/shared_preferences.dart';

class SyncOptIn {
  static const String _key = 'paperclip.sync.enabled';
  SyncOptIn._();
  static final SyncOptIn instance = SyncOptIn._();

  Future<bool> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
    
  }

  Future<void> set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

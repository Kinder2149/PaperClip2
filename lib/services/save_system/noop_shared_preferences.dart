// lib/services/save_system/noop_shared_preferences.dart
// Implémentation minimaliste de SharedPreferences pour la récupération en cas d'erreur

import 'package:shared_preferences/shared_preferences.dart';

/// Classe de secours pour SharedPreferences qui ne fait rien mais permet à l'app de continuer
class NoopSharedPreferences implements SharedPreferences {
  final Map<String, Object> _data = {};
  
  @override
  Set<String> getKeys() => _data.keys.toSet();
  
  @override
  Object? get(String key) => _data[key];
  
  @override
  bool? getBool(String key) => _data[key] as bool?;
  
  @override
  double? getDouble(String key) => _data[key] as double?;
  
  @override
  int? getInt(String key) => _data[key] as int?;
  
  @override
  String? getString(String key) => _data[key] as String?;
  
  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;
  
  @override
  bool containsKey(String key) => _data.containsKey(key);
  
  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }
  
  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }
  
  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }
  
  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }
  
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }
  
  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }
  
  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }
  
  @override
  Future<void> reload() async {}
  
  @override
  Future<bool> commit() async => true;
}

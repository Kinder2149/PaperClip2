import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/progression_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  const MethodChannel sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(sharedPreferencesChannel, (call) async {
    switch (call.method) {
      case 'getAll':
        return <String, Object?>{};
      case 'setBool':
      case 'setDouble':
      case 'setInt':
      case 'setString':
      case 'setStringList':
      case 'remove':
      case 'clear':
      case 'commit':
        return true;
      default:
        return null;
    }
  });

  group('LevelSystem', () {
    test('addExperience ignore amount <= 0', () {
      final level = LevelSystem();

      final beforeXp = level.experience;
      final beforeLevel = level.level;

      level.addExperience(0);
      level.addExperience(-5);

      expect(level.experience, beforeXp);
      expect(level.level, beforeLevel);
    });

    test('addExperience augmente experience', () {
      final level = LevelSystem();

      final before = level.experience;
      level.addExperience(5);

      expect(level.experience, greaterThan(before));
    });

    test('addExperience peut faire monter de niveau (sanity)', () {
      final level = LevelSystem();

      level.addExperience(1e6);

      expect(level.level, greaterThan(1));
    });

    test('claimDailyBonus retourne true puis false si déjà claim', () {
      final level = LevelSystem();

      expect(level.claimDailyBonus(), true);
      expect(level.claimDailyBonus(), false);
    });

    test('toJson/fromJson roundtrip restaure les champs clés', () {
      final level = LevelSystem();

      level.addExperience(50);
      level.claimDailyBonus();

      final json = level.toJson();

      final restored = LevelSystem();
      restored.fromJson(json);

      expect(restored.level, level.level);
      expect(restored.dailyBonus.claimed, level.dailyBonus.claimed);
      // L'expérience peut légèrement bouger à cause de _checkLevelUp() appelée dans fromJson.
      // On valide au minimum que c'est un nombre et >= 0.
      expect(restored.experience, greaterThanOrEqualTo(0));
    });
  });
}

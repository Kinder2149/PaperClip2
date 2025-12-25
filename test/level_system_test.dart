import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/progression_system.dart';

void main() {
  group('LevelSystem basics', () {
    test('starts at level 1 with zero experience and gains XP', () {
      final lvl = LevelSystem();
      expect(lvl.currentLevel, 1);
      expect(lvl.currentXP, 0);

      final beforeNext = lvl.experienceForNextLevel;
      lvl.addExperience(10.0);
      expect(lvl.currentXP, greaterThan(0));
      expect(lvl.experienceForNextLevel, beforeNext); // requirement constant for given next level
    });

    test('levels up when enough experience is added', () {
      final lvl = LevelSystem();
      final target = lvl.calculateExperienceRequirement(1);
      // Add slightly more than required (accounting for internal adjustments)
      lvl.addExperience(target * 2);
      expect(lvl.currentLevel, greaterThanOrEqualTo(2));
    });

    test('addAutomaticProduction grants XP scaled by amount', () {
      final lvl = LevelSystem();
      final xp0 = lvl.currentXP;
      lvl.addAutomaticProduction(10);
      expect(lvl.currentXP, greaterThan(xp0));
    });
  });
}

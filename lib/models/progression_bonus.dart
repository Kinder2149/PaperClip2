class ProgressionBonus {
  static double calculateLevelBonus(int level) {
    if (level < 35) {
      return 1.0 + (level * 0.02);
    } else {
      return 1.7 + ((level - 35) * 0.01);
    }
  }

  static double getMilestoneBonus(int level) {
    Map<int, double> milestones = {
      10: 1.2,
      20: 1.3,
      30: 1.4,
    };
    return milestones[level] ?? 1.0;
  }

  static double getTotalBonus(int level) {
    return calculateLevelBonus(level) * getMilestoneBonus(level);
  }
}
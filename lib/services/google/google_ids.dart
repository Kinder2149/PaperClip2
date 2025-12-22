import 'achievements/achievements_keys.dart';
import 'leaderboards/leaderboards_keys.dart';

class GoogleIds {
  // IDs réels fournis par la Play Console (captures fournies)
  static const Map<String, String> achievementsAndroid = {
    // 1) Gain d'exp
    AchievementKeys.level5: 'CgkI-lCryvIBEAIQAQ',
    // 2) Score Compétitif 10K
    AchievementKeys.totalClips10k: 'CgkI-lCryvIBEAIQBQ',
    // 3) Score Compétitif 50K
    AchievementKeys.totalClips50k: 'CgkI-lCryvIBEAIQBg',
    // 4) Score Compétitif 100K
    AchievementKeys.totalClips100k: 'CgkI-lCryvIBEAIQBw',
    // 5) Speed Run
    AchievementKeys.speedrunLvl7Under20m: 'CgkI-lCryvIBEAIQCA',
    // 6) Maître de l'Efficacité
    AchievementKeys.efficiencyMaster: 'CgkI-lCryvIBEAIQCQ',

    // Non visibles dans la capture: laissons vides jusqu'à fourniture d'IDs
    AchievementKeys.firstAutoclipper: '',
    AchievementKeys.marketSavvy: '',
    AchievementKeys.marketEngineer: '',
    AchievementKeys.banker10k: '',
  };

  static const Map<String, String> leaderboardsAndroid = {
    // 1) Classement Général
    LeaderboardsKeys.general: 'CgkI-lCryvIBEAIQAg',
    // 2) Machine de Production
    LeaderboardsKeys.productionTotalClips: 'CgkI-lCryvIBEAIQAw',
    // 3) Banquier hors-pair
    LeaderboardsKeys.netProfit: 'CgkI-lCryvIBEAIQBA',
  };
}

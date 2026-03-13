import 'achievements/achievements_keys.dart';
import 'leaderboards/leaderboards_keys.dart';

class GoogleIds {
  // IDs réels fournis par la Play Console (captures fournies)
  static const Map<String, String> achievementsAndroid = {
    // 1) Gain d'exp (progressif jusqu'au niveau 50)
    AchievementKeys.expLevel50: 'CgkI-ICryvIBEAIQAQ',
    // 2) Score Compétitif 10K
    AchievementKeys.totalClips10k: 'CgkI-ICryvIBEAIQBQ',
    // 3) Score Compétitif 50K
    AchievementKeys.totalClips50k: 'CgkI-ICryvIBEAIQBg',
    // 4) Score Compétitif 100K
    AchievementKeys.totalClips100k: 'CgkI-ICryvIBEAIQBw',
    // 5) Speed Run
    AchievementKeys.speedrunLvl7Under20m: 'CgkI-ICryvIBEAIQCA',
    // 6) Maître de l'Efficacité
    AchievementKeys.efficiencyMaster: 'CgkI-ICryvIBEAIQCQ',

    // Non visibles dans la capture: laissons vides jusqu'à fourniture d'IDs
    AchievementKeys.firstAutoclipper: '',
    AchievementKeys.marketSavvy: '',
    AchievementKeys.marketEngineer: '',
    AchievementKeys.banker10k: '',
  };

  static const Map<String, String> leaderboardsAndroid = {
    // 1) Classement Général
    LeaderboardsKeys.general: 'CgkI-ICryvIBEAIQAg',
    // 2) Machine de Production
    LeaderboardsKeys.productionTotalClips: 'CgkI-ICryvIBEAIQAw',
    // 3) Banquier hors-pair
    LeaderboardsKeys.netProfit: 'CgkI-ICryvIBEAIQBA',
  };
}

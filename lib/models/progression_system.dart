// lib/models/progression_system.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';

/// Système de bonus de progression
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

/// Système de combo XP
class XPComboSystem {
  int _comboCount = 0;
  Timer? _comboTimer;

  int get comboCount => _comboCount;

  void setComboCount(int count) {
    _comboCount = count;
  }

  double getComboMultiplier() {
    return 1.0 + (_comboCount * 0.1);
  }

  void incrementCombo() {
    _comboCount = _comboCount.clamp(0, 5);
    _resetComboTimer();
  }

  void _resetComboTimer() {
    _comboTimer?.cancel();
    _comboTimer = Timer(const Duration(seconds: 5), () {
      _comboCount = 0;
    });
  }

  void dispose() {
    _comboTimer?.cancel();
  }
}

/// Système de bonus quotidien
class DailyXPBonus {
  bool _claimed = false;
  final double _bonusAmount = 10.0;
  Timer? _resetTimer;

  bool get claimed => _claimed;

  void setClaimed(bool value) {
    _claimed = value;
    if (value) {
      _scheduleReset();
    }
  }

  bool claimDailyBonus(LevelSystem levelSystem) {
    if (!_claimed) {
      levelSystem.gainExperience(_bonusAmount);
      _claimed = true;
      _scheduleReset();
      return true;
    }
    return false;
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _resetTimer = Timer(timeUntilMidnight, () {
      _claimed = false;
    });
  }

  void dispose() {
    _resetTimer?.cancel();
  }
}

/// Système de missions
class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final double target;
  final double experienceReward;
  double progress = 0;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.experienceReward,
  });

  bool get isCompleted => progress >= target;

  void updateProgress(double amount) {
    progress = (progress + amount).clamp(0, target);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
  };

  factory Mission.fromJson(Map<String, dynamic> json) {
    return getMissionTemplate(json['id'])..progress = json['progress'];
  }

  static Mission getMissionTemplate(String id) {
    switch (id) {
      case 'daily_production':
        return Mission(
          id: 'daily_production',
          title: 'Production journalière',
          description: 'Produire 1000 trombones',
          type: MissionType.PRODUCE_PAPERCLIPS,
          target: 1000,
          experienceReward: 500,
        );
      case 'daily_sales':
        return Mission(
          id: 'daily_sales',
          title: 'Ventes journalières',
          description: 'Vendre 500 trombones',
          type: MissionType.SELL_PAPERCLIPS,
          target: 500,
          experienceReward: 300,
        );
      case 'weekly_autoclippers':
        return Mission(
          id: 'weekly_autoclippers',
          title: 'Expansion automatique',
          description: 'Acheter 10 autoclippeuses',
          type: MissionType.BUY_AUTOCLIPPERS,
          target: 10,
          experienceReward: 750,
        );
      default:
        throw Exception('Mission template not found');
    }
  }
}

/// Gestionnaire de missions
class MissionSystem {
  List<Mission> dailyMissions = [];
  List<Mission> weeklyMissions = [];
  List<Mission> achievements = [];
  Timer? missionRefreshTimer;
  Function(Mission mission)? onMissionCompleted;
  Function()? onMissionSystemRefresh;

  void initialize() {
    generateDailyMissions();
    generateWeeklyMissions();
    startMissionRefreshTimer();
  }

  void generateDailyMissions() {
    dailyMissions = [
      Mission.getMissionTemplate('daily_production'),
      Mission.getMissionTemplate('daily_sales'),
    ];
  }

  void generateWeeklyMissions() {
    weeklyMissions = [
      Mission.getMissionTemplate('weekly_autoclippers'),
    ];
  }

  void startMissionRefreshTimer() {
    missionRefreshTimer?.cancel();
    missionRefreshTimer = Timer.periodic(
      const Duration(hours: 24),
          (_) {
        generateDailyMissions();
        onMissionSystemRefresh?.call();
      },
    );
  }

  void updateMissions(MissionType type, double amount) {
    for (var mission in [...dailyMissions, ...weeklyMissions]) {
      if (mission.type == type && !mission.isCompleted) {
        mission.updateProgress(amount);
        if (mission.isCompleted) {
          onMissionCompleted?.call(mission);
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'dailyMissions': dailyMissions.map((m) => m.toJson()).toList(),
    'weeklyMissions': weeklyMissions.map((m) => m.toJson()).toList(),
  };

  void fromJson(Map<String, dynamic> json) {
    if (json['dailyMissions'] != null) {
      dailyMissions = (json['dailyMissions'] as List)
          .map((missionJson) => Mission.fromJson(missionJson))
          .toList();
    }

    if (json['weeklyMissions'] != null) {
      weeklyMissions = (json['weeklyMissions'] as List)
          .map((missionJson) => Mission.fromJson(missionJson))
          .toList();
    }
  }

  void dispose() {
    missionRefreshTimer?.cancel();
  }
}

/// Système de niveaux
class LevelSystem extends ChangeNotifier {
  double _experience = 0;
  int _level = 1;
  ProgressionPath _currentPath = ProgressionPath.PRODUCTION;
  final GameFeatureUnlocker _featureUnlocker = GameFeatureUnlocker();
  final XPComboSystem comboSystem = XPComboSystem();
  final DailyXPBonus dailyBonus = DailyXPBonus();
  double _xpMultiplier = 1.0;

  Function(int level, List<UnlockableFeature> newFeatures)? onLevelUp;

  // Getters
  double get experience => _experience;
  int get level => _level;
  ProgressionPath get currentPath => _currentPath;
  double get currentComboMultiplier => comboSystem.getComboMultiplier();
  double get totalXpMultiplier => _xpMultiplier * currentComboMultiplier;
  bool get isDailyBonusAvailable => !dailyBonus.claimed;
  double get productionMultiplier => 1.0 + (level * 0.05);
  double get salesMultiplier => 1.0 + (level * 0.03);

  double get experienceForNextLevel => calculateExperienceRequirement(_level + 1);
  double get experienceProgress => _experience / experienceForNextLevel;
  final Map<int, LevelUnlock> _levelUnlocks = {
    1: LevelUnlock(
        description: "Production manuelle débloquée",
        unlockedFeatures: ['manual_production'],
        initialExperienceRequirement: 10
    ),
    3: LevelUnlock(
        description: "Première autoclippeuse",
        unlockedFeatures: ['first_autoclipper'],
        pathOptions: [
          PathOption(ProgressionPath.PRODUCTION, 0.2),
          PathOption(ProgressionPath.EFFICIENCY, 0.1)
        ],
        initialExperienceRequirement: 150
    ),
    5: LevelUnlock(
        description: "Accès aux améliorations basiques",
        unlockedFeatures: ['basic_upgrades'],
        initialExperienceRequirement: 500
    ),
    8: LevelUnlock(
        description: "Marché débloqué",
        unlockedFeatures: ['market_access'],
        pathOptions: [
          PathOption(ProgressionPath.MARKETING, 0.3),
          PathOption(ProgressionPath.EFFICIENCY, 0.2)
        ],
        initialExperienceRequirement: 1000
    ),
    12: LevelUnlock(
        description: "Améliorations avancées",
        unlockedFeatures: ['advanced_upgrades'],
        initialExperienceRequirement: 2000
    ),
    15: LevelUnlock(
        description: "Marketing optimisé",
        unlockedFeatures: ['marketing_boost'],
        initialExperienceRequirement: 3000
    ),
    20: LevelUnlock(
        description: "Production de masse",
        unlockedFeatures: ['mass_production'],
        pathOptions: [
          PathOption(ProgressionPath.PRODUCTION, 0.4),
          PathOption(ProgressionPath.INNOVATION, 0.3)
        ],
        initialExperienceRequirement: 5000
    ),
    25: LevelUnlock(
        description: "Expertise commerciale",
        unlockedFeatures: ['trade_mastery'],
        initialExperienceRequirement: 8000
    ),
    30: LevelUnlock(
        description: "Optimisation ultime",
        unlockedFeatures: ['ultimate_optimization'],
        initialExperienceRequirement: 12000
    ),
    35: LevelUnlock(
        description: "Maîtrise totale",
        unlockedFeatures: ['complete_mastery'],
        pathOptions: [
          PathOption(ProgressionPath.INNOVATION, 0.5),
          PathOption(ProgressionPath.MARKETING, 0.4)
        ],
        initialExperienceRequirement: 20000
    )
  };

  Map<int, String> get levelUnlocks {
    return _levelUnlocks.map((key, value) => MapEntry(key, value.description));
  }


  String _getLevelDescription(UnlockableFeature feature) {
    switch (feature) {
      case UnlockableFeature.MANUAL_PRODUCTION:
        return "Production manuelle débloquée";
      case UnlockableFeature.METAL_PURCHASE:
        return "Achat de métal disponible";
      case UnlockableFeature.MARKET_SALES:
        return "Vente sur le marché activée";
      case UnlockableFeature.MARKET_SCREEN:
        return "Écran du marché accessible";
      case UnlockableFeature.AUTOCLIPPERS:
        return "Autoclippeuses disponibles";
      case UnlockableFeature.UPGRADES:
        return "Système d'améliorations débloqué";
      default:
        return "Nouvelle fonctionnalité disponible";
    }
  }
  void _handleLevelUp(int newLevel) {
    final List<UnlockableFeature> newFeatures =
    _featureUnlocker.getNewlyUnlockedFeatures(_level, newLevel);
    _level = newLevel;

    for (var feature in newFeatures) {
      final unlockDetails = getUnlockDetails(feature);

      EventManager.instance.addEvent(
          EventType.LEVEL_UP,
          'Nouvelle Fonctionnalité !',
          description: unlockDetails.name,
          detailedDescription: _formatUnlockDescription(unlockDetails),
          importance: EventImportance.HIGH,
          additionalData: {
            'unlockedFeature': feature,
            'level': newLevel,
          }
      );
    }
  }
  String _formatUnlockDescription(UnlockDetails details) {
    return '''
${details.description}

📋 Comment utiliser :
${details.howToUse}

✨ Avantages :
${details.benefits.map((b) => '• $b').join('\n')}

💡 Conseils :
${details.tips.map((t) => '• $t').join('\n')}
''';
  }
  void handleFeatureUnlock(UnlockableFeature feature, int level) {
    final details = getUnlockDetails(feature);
    if (details != null) {
      EventManager.instance.addEvent(
          EventType.LEVEL_UP,
          'Nouvelle Fonctionnalité Débloquée !',
          description: details.description,
          detailedDescription: _formatUnlockDescription(details),
          importance: EventImportance.HIGH,
          additionalData: {
            'unlockedFeature': feature,
            'level': level,
            'featureName': details.name,
            'howToUse': details.howToUse,
            'benefits': details.benefits.join('\n'),
            'tips': details.tips.join('\n'),
          }
      );
    }
  }

  static UnlockDetails getUnlockDetails(UnlockableFeature feature) {
    switch (feature) {
      case UnlockableFeature.MANUAL_PRODUCTION:
        return UnlockDetails(
          name: 'Production Manuelle',
          description: 'Démarrez votre empire de trombones en produisant manuellement !',
          howToUse: '''
1. Cliquez sur le bouton de production dans l'écran principal
2. Chaque clic transforme du métal en trombone
3. Surveillez votre stock de métal pour une production continue''',
          benefits: [
            'Production immédiate de trombones',
            'Gain d\'expérience à chaque production',
            'Contrôle total sur la production',
            'Apprentissage des mécaniques de base'
          ],
          tips: [
            'Maintenez un stock de métal suffisant',
            'Produisez régulièrement pour gagner de l\'expérience',
            'Observez l\'évolution de votre efficacité'
          ],
          icon: Icons.touch_app,
        );

      case UnlockableFeature.METAL_PURCHASE:
        return UnlockDetails(
          name: 'Achat de Métal',
          description: 'Accédez au marché des matières premières pour acheter du métal !',
          howToUse: '''
1. Ouvrez l'onglet Marché
2. Consultez les prix actuels du métal
3. Achetez quand les prix sont avantageux''',
          benefits: [
            'Approvisionnement constant en matières premières',
            'Possibilité de stocker pour les moments opportuns',
            'Gestion stratégique des ressources',
            'Optimisation des coûts de production'
          ],
          tips: [
            'Achetez en grande quantité quand les prix sont bas',
            'Surveillez les tendances du marché',
            'Maintenez une réserve de sécurité',
            'Calculez votre retour sur investissement'
          ],
          icon: Icons.shopping_cart,
        );

      case UnlockableFeature.MARKET_SALES:
        return UnlockDetails(
          name: 'Ventes sur le Marché',
          description: 'Vendez vos trombones sur le marché mondial !',
          howToUse: '''
1. Accédez à l'interface de vente dans l'onglet Marché
2. Définissez votre prix de vente
3. Suivez vos statistiques de vente''',
          benefits: [
            'Génération de revenus passifs',
            'Accès aux statistiques de vente',
            'Influence sur les prix du marché',
            'Optimisation des profits'
          ],
          tips: [
            'Adaptez vos prix à la demande',
            'Surveillez la satisfaction client',
            'Équilibrez production et ventes',
            'Analysez les tendances du marché'
          ],
          icon: Icons.store,
        );

      case UnlockableFeature.MARKET_SCREEN:
        return UnlockDetails(
          name: 'Écran de Marché',
          description: 'Accédez à des outils avancés d\'analyse de marché !',
          howToUse: '''
1. Naviguez vers l'onglet Marché
2. Explorez les différents graphiques et statistiques
3. Utilisez les données pour optimiser vos stratégies''',
          benefits: [
            'Visualisation détaillée des tendances',
            'Analyse approfondie du marché',
            'Prévisions de demande',
            'Optimisation des stratégies de prix'
          ],
          tips: [
            'Consultez régulièrement les rapports',
            'Utilisez les graphiques pour anticiper',
            'Ajustez votre stratégie selon les données',
            'Surveillez la concurrence'
          ],
          icon: Icons.analytics,
        );

      case UnlockableFeature.AUTOCLIPPERS:
        return UnlockDetails(
          name: 'Autoclippeuses',
          description: 'Automatisez votre production avec des machines intelligentes !',
          howToUse: '''
1. Achetez des autoclippeuses dans la section Améliorations
2. Gérez leur maintenance et leur efficacité
3. Surveillez leur consommation de ressources''',
          benefits: [
            'Production automatique continue',
            'Augmentation significative de la production',
            'Libération de temps pour la stratégie',
            'Production même hors ligne'
          ],
          tips: [
            'Équilibrez le nombre avec vos ressources',
            'Maintenez-les régulièrement',
            'Surveillez leur consommation de métal',
            'Optimisez leur placement'
          ],
          icon: Icons.precision_manufacturing,
        );

      case UnlockableFeature.UPGRADES:
        return UnlockDetails(
          name: 'Système d\'Améliorations',
          description: 'Accédez à un vaste système d\'améliorations pour optimiser votre production !',
          howToUse: '''
1. Explorez l'onglet Améliorations
2. Choisissez les améliorations stratégiques
3. Combinez les effets pour maximiser les bénéfices''',
          benefits: [
            'Personnalisation de votre stratégie',
            'Améliorations permanentes',
            'Déblocage de nouvelles fonctionnalités',
            'Optimisation globale de la production'
          ],
          tips: [
            'Planifiez vos achats d\'amélioration',
            'Lisez attentivement les effets',
            'Privilégiez les synergies',
            'Gardez des ressources pour les urgences'
          ],
          icon: Icons.upgrade,
        );

      default:
        throw ArgumentError('Détails de déverrouillage non trouvés pour $feature');
    }
  }


  double calculateExperienceRequirement(int level) {
    if (level <= 15) {
      return 50 * pow(1.2, level) + (level * level * 3);
    } else if (level <= 25) {
      return 50 * pow(1.3, level) + (level * level * 5);
    } else if (level <= 35) {
      return 50 * pow(1.5, level) + (level * level * 7);
    } else {
      return 50 * pow(1.7, level) + (level * level * 8);
    }
  }

  void gainExperience(double amount) {
    double baseAmount = amount * totalXpMultiplier;
    double levelPenalty = _level * 0.02;
    double adjustedAmount = baseAmount * (1 - levelPenalty);

    if (_level < 35) {
      adjustedAmount *= 1.1;
    }

    _experience += max(adjustedAmount, 0.2);
    comboSystem.incrementCombo();
    _checkLevelUp();
    notifyListeners();
  }
  void reset() {
    // Réinitialisation des valeurs de base
    _experience = 0;
    _level = 1;
    _currentPath = ProgressionPath.PRODUCTION;
    _xpMultiplier = 1.0;

    // Réinitialisation des systèmes
    comboSystem.setComboCount(0);
    dailyBonus.setClaimed(false);
    _featureUnlocker.reset();  // Utilisez _featureUnlocker au lieu de featureUnlocker

    // Réinitialisation des callbacks
    onLevelUp = null;

    // Notification des changements
    notifyListeners();
  }



  void addManualProduction() {
    double baseXP = 2.0;
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    gainExperience(baseXP * bonusXP);
  }

  void addAutomaticProduction(int amount) {
    double baseXP = 0.1 * amount;
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    gainExperience(baseXP * bonusXP);
  }

  void addSale(int quantity, double price) {
    double baseXP = 0.3 * quantity * (1 + (price - 0.25) * 2);
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    gainExperience(baseXP * bonusXP);
  }

  void addAutoclipperPurchase() {
    gainExperience(3);
  }

  void addUpgradePurchase(int upgradeLevel) {
    gainExperience(2.0 * upgradeLevel);
  }

  void applyXPBoost(double multiplier, Duration duration) {
    _xpMultiplier = multiplier;
    EventManager.instance.addEvent(
        EventType.XP_BOOST,
        "Bonus d'XP activé !",
        description: "Multiplicateur x$multiplier pendant ${duration.inMinutes} minutes",
        importance: EventImportance.MEDIUM
    );

    Future.delayed(duration, () {
      _xpMultiplier = 1.0;
      notifyListeners();
    });
  }

  bool claimDailyBonus() {
    return dailyBonus.claimDailyBonus(this);
  }

  void _checkLevelUp() {
    double requiredExperience = calculateExperienceRequirement(_level);

    while (_experience >= requiredExperience) {
      _handleLevelUp(_level);

      List<UnlockableFeature> newFeatures =
      _featureUnlocker.getNewlyUnlockedFeatures(_level - 1, _level);

      _triggerLevelUpEvent(_level, newFeatures);

      if (onLevelUp != null) {
        onLevelUp!(_level, newFeatures);
      }

      requiredExperience = calculateExperienceRequirement(_level);
      notifyListeners();
    }
  }

  void _triggerLevelUpEvent(int newLevel, List<UnlockableFeature> newFeatures) {
    String featuresDescription = newFeatures.isEmpty
        ? "Continuez votre progression !"
        : "Nouvelles fonctionnalités débloquées !";

    EventManager.instance.addEvent(
        EventType.LEVEL_UP,
        "Niveau $newLevel atteint !",
        description: featuresDescription,
        importance: EventImportance.HIGH
    );
  }

  Map<String, dynamic> toJson() => {
    'experience': _experience,
    'level': _level,
    'currentPath': _currentPath.index,
    'xpMultiplier': _xpMultiplier,
    'comboCount': comboSystem.comboCount,
    'dailyBonusClaimed': dailyBonus.claimed,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _experience = (json['experience'] as num?)?.toDouble() ?? 0;
    _level = (json['level'] as num?)?.toInt() ?? 1;
    _currentPath = ProgressionPath.values[json['currentPath'] ?? 0];
    _xpMultiplier = (json['xpMultiplier'] as num?)?.toDouble() ?? 1.0;
    comboSystem.setComboCount(json['comboCount'] ?? 0);
    dailyBonus.setClaimed(json['dailyBonusClaimed'] ?? false);
    _checkLevelUp();
  }

  @override
  void dispose() {
    comboSystem.dispose();
    dailyBonus.dispose();
    super.dispose();
  }
}

/// Gestionnaire des fonctionnalités débloquables
class GameFeatureUnlocker {
  // Map pour stocker l'état des fonctionnalités
  final Map<UnlockableFeature, bool> _featureStates = {};

  // Map des niveaux requis pour chaque fonctionnalité
  final Map<UnlockableFeature, int> _featureLevelRequirements = {
    UnlockableFeature.MANUAL_PRODUCTION: 1,
    UnlockableFeature.METAL_PURCHASE: 1,
    UnlockableFeature.AUTOCLIPPERS: 3,
    UnlockableFeature.UPGRADES: 5,
    UnlockableFeature.MARKET_SCREEN: 7,
    UnlockableFeature.MARKET_SALES: 9,
  };
  List<UnlockableFeature> getNewlyUnlockedFeatures(int previousLevel, int newLevel) {
    return _featureLevelRequirements.entries
        .where((entry) =>
    entry.value > previousLevel &&
        entry.value <= newLevel)
        .map((entry) => entry.key)
        .toList();
  }

  // Méthode pour vérifier si une fonctionnalité est débloquée
  bool isFeatureUnlocked(UnlockableFeature feature, int currentLevel) {
    return currentLevel >= (_featureLevelRequirements[feature] ?? 100);
  }



  void reset() {
    // Réinitialiser tous les états des fonctionnalités
    for (var feature in UnlockableFeature.values) {
      _featureStates[feature] = false;
    }
  }






  Map<String, bool> getVisibleScreenElements(int currentLevel) {
    return {
      'metalStock': true,
      'paperclipStock': true,
      'manualProductionButton': true,
      'metalPurchaseButton': isFeatureUnlocked(
          UnlockableFeature.METAL_PURCHASE, currentLevel),
      'marketPrice': isFeatureUnlocked(
          UnlockableFeature.MARKET_SALES, currentLevel),
      'sellButton': isFeatureUnlocked(
          UnlockableFeature.MARKET_SALES, currentLevel),
      'autoclippersSection': isFeatureUnlocked(
          UnlockableFeature.AUTOCLIPPERS, currentLevel),
      'upgradesSection': isFeatureUnlocked(
          UnlockableFeature.UPGRADES, currentLevel),
    };
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/services/event_manager.dart';
import 'event_system.dart';
import 'game_config.dart';



// lib/models/progression_system.dart

/// SystÃ¨me de bonus de progression
class ProgressionBonus {
  static double calculateLevelBonus(int level) {
    if (level < 15) {
      return 1.0 + (level * 0.03);  // Bonus plus progressif
    } else if (level < 25) {
      return 1.45 + ((level - 15) * 0.04);
    } else if (level < 35) {
      return 1.85 + ((level - 25) * 0.05);
    } else {
      return 2.35 + ((level - 35) * 0.03);
    }
  }

  static double getMilestoneBonus(int level) {
    Map<int, double> milestones = {
      5: 1.1,   // Premier palier important
      10: 1.2,  // AccÃ¨s au marchÃ©
      15: 1.3,  // MaÃ®trise de la production
      25: 1.4,  // MaÃ®trise commerciale
      35: 1.5,  // Excellence industrielle
    };
    return milestones[level] ?? 1.0;
  }

  static double getTotalBonus(int level) {
    return calculateLevelBonus(level) * getMilestoneBonus(level);
  }
}

/// SystÃ¨me de combo XP
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

/// SystÃ¨me de bonus quotidien
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

/// SystÃ¨me de missions
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
          title: 'Production journaliÃ¨re',
          description: 'Produire 1000 trombones',
          type: MissionType.PRODUCE_PAPERCLIPS,
          target: 1000,
          experienceReward: 500,
        );
      case 'daily_sales':
        return Mission(
          id: 'daily_sales',
          title: 'Ventes journaliÃ¨res',
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

/// SystÃ¨me de niveaux
class LevelSystem extends ChangeNotifier {
  double _experience = 0;
  int _level = 1;
  ProgressionPath _currentPath = ProgressionPath.PRODUCTION;
  final GameFeatureUnlocker _featureUnlocker = GameFeatureUnlocker();
  final XPComboSystem comboSystem = XPComboSystem();
  final DailyXPBonus dailyBonus = DailyXPBonus();
  double _xpMultiplier = 1.0;
  Map<ProgressionPath, double> _pathProgress = {};
  Map<String, bool> _unlockedMilestones = {};

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
    // Phase d'Introduction
    1: LevelUnlock(
        description: "DÃ©but de l'aventure - Production manuelle",
        unlockedFeatures: ['manual_production'],
        initialExperienceRequirement: 155
    ),
    2: LevelUnlock(
        description: "Gestion des ressources - Achat de mÃ©tal",
        unlockedFeatures: ['metal_purchase'],
        pathOptions: [
          PathOption(ProgressionPath.PRODUCTION, 0.3),
          PathOption(ProgressionPath.EFFICIENCY, 0.2)
        ],
        initialExperienceRequirement: 205
    ),
    3: LevelUnlock(
        description: "Automatisation - Premier autoclippeur",
        unlockedFeatures: ['first_autoclipper'],
        pathOptions: [
          PathOption(ProgressionPath.PRODUCTION, 0.4),
          PathOption(ProgressionPath.EFFICIENCY, 0.3)
        ],
        initialExperienceRequirement: 260
    ),
    5: LevelUnlock(
        description: "SystÃ¨me d'amÃ©liorations dÃ©bloquÃ©",
        unlockedFeatures: ['upgrades'],
        pathOptions: [
          PathOption(ProgressionPath.EFFICIENCY, 0.4),
          PathOption(ProgressionPath.INNOVATION, 0.3)
        ],
        initialExperienceRequirement: 366
    ),
    8: LevelUnlock(
        description: "Interface du marchÃ© dÃ©bloquÃ©e",
        unlockedFeatures: ['market_screen'],
        pathOptions: [
          PathOption(ProgressionPath.MARKETING, 0.5),
          PathOption(ProgressionPath.EFFICIENCY, 0.3)
        ],
        initialExperienceRequirement: 580
    ),
    10: LevelUnlock(
        description: "AccÃ¨s aux ventes sur le marchÃ©",
        unlockedFeatures: ['market_sales'],
        pathOptions: [
          PathOption(ProgressionPath.MARKETING, 0.6),
          PathOption(ProgressionPath.INNOVATION, 0.4)
        ],
        initialExperienceRequirement: 666
    ),
    15: LevelUnlock(
        description: "Optimisation de la production",
        unlockedFeatures: ['production_mastery'],
        pathOptions: [
          PathOption(ProgressionPath.PRODUCTION, 0.5),
          PathOption(ProgressionPath.EFFICIENCY, 0.5)
        ],
        initialExperienceRequirement: 1050
    ),
    25: LevelUnlock(
        description: "MaÃ®trise commerciale",
        unlockedFeatures: ['market_mastery'],
        pathOptions: [
          PathOption(ProgressionPath.MARKETING, 0.7),
          PathOption(ProgressionPath.INNOVATION, 0.6)
        ],
        initialExperienceRequirement: 1892
    ),
    35: LevelUnlock(
        description: "Excellence industrielle",
        unlockedFeatures: ['industry_mastery'],
        pathOptions: [
          PathOption(ProgressionPath.INNOVATION, 0.8),
          PathOption(ProgressionPath.EFFICIENCY, 0.7)
        ],
        initialExperienceRequirement: 3751
    )
  };

  Map<int, String> get levelUnlocks {
    return _levelUnlocks.map((key, value) => MapEntry(key, value.description));
  }


  String _getLevelDescription(UnlockableFeature feature) {
    switch (feature) {
      case UnlockableFeature.MANUAL_PRODUCTION:
        return "Production manuelle dÃ©bloquÃ©e";
      case UnlockableFeature.METAL_PURCHASE:
        return "Achat de mÃ©tal disponible";
      case UnlockableFeature.MARKET_SALES:
        return "Vente sur le marchÃ© activÃ©e";
      case UnlockableFeature.MARKET_SCREEN:
        return "Ã‰cran du marchÃ© accessible";
      case UnlockableFeature.AUTOCLIPPERS:
        return "Autoclippeuses disponibles";
      case UnlockableFeature.UPGRADES:
        return "SystÃ¨me d'amÃ©liorations dÃ©bloquÃ©";
      default:
        return "Nouvelle fonctionnalitÃ© disponible";
    }
  }
  void _handleLevelUp(int newLevel) {
    final unlocks = _levelUnlocks[newLevel];
    if (unlocks != null) {
      EventManager().addEvent(
          EventType.LEVEL_UP,
          "Niveau $newLevel Atteint !",
          description: unlocks.description,
          importance: EventImportance.HIGH,
          additionalData: {
            'level': newLevel,
            'unlockedFeatures': unlocks.unlockedFeatures,
          }
      );
    }
    notifyListeners();
  }
  String _formatUnlockDescription(UnlockDetails details) {
    return '''
${details.description}

ðŸ“‹ Comment utiliser :
${details.howToUse}

âœ¨ Avantages :
${details.benefits.map((b) => 'â€¢ $b').join('\n')}

ðŸ’¡ Conseils :
${details.tips.map((t) => 'â€¢ $t').join('\n')}
''';
  }
  void handleFeatureUnlock(UnlockableFeature feature, int level) {
    final details = getUnlockDetails(feature);
    if (details != null) {
      EventManager().addEvent(
          EventType.LEVEL_UP,
          'Nouvelle FonctionnalitÃ© DÃ©bloquÃ©e !',
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
          description: 'DÃ©marrez votre empire de trombones en produisant manuellement !',
          howToUse: '''
1. Cliquez sur le bouton de production dans l'Ã©cran principal
2. Chaque clic transforme du mÃ©tal en trombone
3. Surveillez votre stock de mÃ©tal pour une production continue''',
          benefits: [
            'Production immÃ©diate de trombones',
            'Gain d\'expÃ©rience Ã  chaque production',
            'ContrÃ´le total sur la production',
            'Apprentissage des mÃ©caniques de base'
          ],
          tips: [
            'Maintenez un stock de mÃ©tal suffisant',
            'Produisez rÃ©guliÃ¨rement pour gagner de l\'expÃ©rience',
            'Observez l\'Ã©volution de votre efficacitÃ©'
          ],
          icon: Icons.touch_app,
        );

      case UnlockableFeature.METAL_PURCHASE:
        return UnlockDetails(
          name: 'Achat de MÃ©tal',
          description: 'AccÃ©dez au marchÃ© des matiÃ¨res premiÃ¨res pour acheter du mÃ©tal !',
          howToUse: '''
1. Ouvrez l'onglet MarchÃ©
2. Consultez les prix actuels du mÃ©tal
3. Achetez quand les prix sont avantageux''',
          benefits: [
            'Approvisionnement constant en matiÃ¨res premiÃ¨res',
            'PossibilitÃ© de stocker pour les moments opportuns',
            'Gestion stratÃ©gique des ressources',
            'Optimisation des coÃ»ts de production'
          ],
          tips: [
            'Achetez en grande quantitÃ© quand les prix sont bas',
            'Surveillez les tendances du marchÃ©',
            'Maintenez une rÃ©serve de sÃ©curitÃ©',
            'Calculez votre retour sur investissement'
          ],
          icon: Icons.shopping_cart,
        );

      case UnlockableFeature.MARKET_SALES:
        return UnlockDetails(
          name: 'Ventes sur le MarchÃ©',
          description: 'Vendez vos trombones sur le marchÃ© mondial !',
          howToUse: '''
1. AccÃ©dez Ã  l'interface de vente dans l'onglet MarchÃ©
2. DÃ©finissez votre prix de vente
3. Suivez vos statistiques de vente''',
          benefits: [
            'GÃ©nÃ©ration de revenus passifs',
            'AccÃ¨s aux statistiques de vente',
            'Influence sur les prix du marchÃ©',
            'Optimisation des profits'
          ],
          tips: [
            'Adaptez vos prix Ã  la demande',
            'Surveillez la satisfaction client',
            'Ã‰quilibrez production et ventes',
            'Analysez les tendances du marchÃ©'
          ],
          icon: Icons.store,
        );

      case UnlockableFeature.MARKET_SCREEN:
        return UnlockDetails(
          name: 'Ã‰cran de MarchÃ©',
          description: 'AccÃ©dez Ã  des outils avancÃ©s d\'analyse de marchÃ© !',
          howToUse: '''
1. Naviguez vers l'onglet MarchÃ©
2. Explorez les diffÃ©rents graphiques et statistiques
3. Utilisez les donnÃ©es pour optimiser vos stratÃ©gies''',
          benefits: [
            'Visualisation dÃ©taillÃ©e des tendances',
            'Analyse approfondie du marchÃ©',
            'PrÃ©visions de demande',
            'Optimisation des stratÃ©gies de prix'
          ],
          tips: [
            'Consultez rÃ©guliÃ¨rement les rapports',
            'Utilisez les graphiques pour anticiper',
            'Ajustez votre stratÃ©gie selon les donnÃ©es',
            'Surveillez la concurrence'
          ],
          icon: Icons.analytics,
        );

      case UnlockableFeature.AUTOCLIPPERS:
        return UnlockDetails(
          name: 'Autoclippeuses',
          description: 'Automatisez votre production avec des machines intelligentes !',
          howToUse: '''
1. Achetez des autoclippeuses dans la section AmÃ©liorations
2. GÃ©rez leur maintenance et leur efficacitÃ©
3. Surveillez leur consommation de ressources''',
          benefits: [
            'Production automatique continue',
            'Augmentation significative de la production',
            'LibÃ©ration de temps pour la stratÃ©gie',
            'Production mÃªme hors ligne'
          ],
          tips: [
            'Ã‰quilibrez le nombre avec vos ressources',
            'Maintenez-les rÃ©guliÃ¨rement',
            'Surveillez leur consommation de mÃ©tal',
            'Optimisez leur placement'
          ],
          icon: Icons.precision_manufacturing,
        );

      case UnlockableFeature.UPGRADES:
        return UnlockDetails(
          name: 'SystÃ¨me d\'AmÃ©liorations',
          description: 'AccÃ©dez Ã  un vaste systÃ¨me d\'amÃ©liorations pour optimiser votre production !',
          howToUse: '''
1. Explorez l'onglet AmÃ©liorations
2. Choisissez les amÃ©liorations stratÃ©giques
3. Combinez les effets pour maximiser les bÃ©nÃ©fices''',
          benefits: [
            'Personnalisation de votre stratÃ©gie',
            'AmÃ©liorations permanentes',
            'DÃ©blocage de nouvelles fonctionnalitÃ©s',
            'Optimisation globale de la production'
          ],
          tips: [
            'Planifiez vos achats d\'amÃ©lioration',
            'Lisez attentivement les effets',
            'PrivilÃ©giez les synergies',
            'Gardez des ressources pour les urgences'
          ],
          icon: Icons.upgrade,
        );

      default:
        throw ArgumentError('DÃ©tails de dÃ©verrouillage non trouvÃ©s pour $feature');
    }
  }




  double calculateExperienceRequirement(int level) {
    double baseXP = 100.0;
    double linearIncrease = level * 50.0;  // Composante linÃ©aire plus douce
    double smallExponential = pow(1.05, level).toDouble();  // Conversion explicite en double

    // Facteur de palier pour diffÃ©rentes phases du jeu
    double tierMultiplier = 1.0;

    // Paliers progressifs
    if (level > 25) tierMultiplier = 1.2;
    if (level > 35) tierMultiplier = 1.5;

    // Protection contre les valeurs trop grandes
    double totalXP = (baseXP + linearIncrease + smallExponential) * tierMultiplier;

    // Arrondi Ã  1 dÃ©cimale pour plus de clartÃ©
    return double.parse(totalXP.toStringAsFixed(1));
  }

  void gainExperience(double amount) {
    print('Gaining experience: $amount'); // Log initial amount
    double baseAmount = amount * totalXpMultiplier;
    double levelPenalty = _level * 0.02;
    double adjustedAmount = baseAmount * (1 - levelPenalty);


    if (_level < 35) {
      adjustedAmount *= 1.1;
    }

    print('Adjusted experience: $adjustedAmount'); // Log adjusted amount
    _experience += max(adjustedAmount, 0.2);

    print('Current experience: $_experience'); // Log current experience
    print('Experience for next level: ${calculateExperienceRequirement(_level + 1)}'); // Log required experience

    comboSystem.incrementCombo();
    _checkLevelUp();
    notifyListeners();
  }
  void reset() {
    // RÃ©initialisation des valeurs de base
    _experience = 0;
    _level = 1;
    _currentPath = ProgressionPath.PRODUCTION;
    _xpMultiplier = 1.0;

    // RÃ©initialisation des systÃ¨mes
    comboSystem.setComboCount(0);
    dailyBonus.setClaimed(false);
    _featureUnlocker.reset();  // Utilisez _featureUnlocker au lieu de featureUnlocker

    // RÃ©initialisation des callbacks
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
    double baseXP = 0.15 * amount;
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    gainExperience(baseXP * bonusXP);
  }

  void addSale(int quantity, double price) {
    double baseXP = 0.4 * quantity * (1 + (price - 0.25) * 2);
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    gainExperience(baseXP * bonusXP);
  }

  void addAutoclipperPurchase() {
    gainExperience(4);
  }

  void addUpgradePurchase(int upgradeLevel) {
    gainExperience(2.5 * upgradeLevel);
  }

  void applyXPBoost(double multiplier, Duration duration) {
    _xpMultiplier = multiplier;
    EventManager().addEvent(
        EventType.XP_BOOST,
        "Bonus d'XP activÃ© !",
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
    while (_experience >= calculateExperienceRequirement(_level)) {
      double requiredExperience = calculateExperienceRequirement(_level);

      // Subtract required experience before incrementing level
      _experience -= requiredExperience;
      _level++;

      List<UnlockableFeature> newFeatures =
      _featureUnlocker.getNewlyUnlockedFeatures(_level - 1, _level);

      _handleLevelUp(_level);
      _triggerLevelUpEvent(_level, newFeatures);

      if (onLevelUp != null) {
        onLevelUp!(_level, newFeatures);
      }
    }

    notifyListeners();
  }

  void _triggerLevelUpEvent(int newLevel, List<UnlockableFeature> newFeatures) {
    if (newFeatures.isEmpty) {
      EventManager().addEvent(
          EventType.LEVEL_UP,
          "Niveau $newLevel atteint !",
          description: "Continuez votre progression !",
          importance: EventImportance.HIGH
      );
    } else {
      for (var feature in newFeatures) {
        final details = LevelSystem.getUnlockDetails(feature);
        EventManager().addEvent(
            EventType.LEVEL_UP,
            "Niveau $newLevel atteint !",
            description: details.name,
            detailedDescription: '''
${details.description}

ðŸ“‹ Comment utiliser :
${details.howToUse}

âœ¨ Avantages :
${details.benefits.map((b) => 'â€¢ $b').join('\n')}

ðŸ’¡ Conseils :
${details.tips.map((t) => 'â€¢ $t').join('\n')}
''',
            importance: EventImportance.HIGH,
            additionalData: {
              'unlockedFeature': feature,
              'level': newLevel,
            }
        );
      }
    }
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

/// Gestionnaire des fonctionnalitÃ©s dÃ©bloquables
class GameFeatureUnlocker {
  // Map pour stocker l'Ã©tat des fonctionnalitÃ©s
  final Map<UnlockableFeature, bool> _featureStates = {};

  // Map des niveaux requis pour chaque fonctionnalitÃ©
  final Map<UnlockableFeature, int> _featureLevelRequirements = {
    // Phase d'Introduction (1-5)
    UnlockableFeature.MANUAL_PRODUCTION: 1,    // Production de base
    UnlockableFeature.METAL_PURCHASE: 2,       // DÃ©placÃ© du niveau 1 au 2
    UnlockableFeature.AUTOCLIPPERS: 3,         // Reste au niveau 3
    UnlockableFeature.UPGRADES: 5,             // Reste au niveau 5

    // Phase de DÃ©veloppement (6-15)
    UnlockableFeature.MARKET_SCREEN: 8,        // DÃ©placÃ© du niveau 7 au 8
    UnlockableFeature.MARKET_SALES: 10,        // DÃ©placÃ© du niveau 9 au 10
  };
  List<UnlockableFeature> getNewlyUnlockedFeatures(int previousLevel, int newLevel) {
    return _featureLevelRequirements.entries
        .where((entry) =>
    entry.value > previousLevel &&
        entry.value <= newLevel)
        .map((entry) => entry.key)
        .toList();
  }

  // MÃ©thode pour vÃ©rifier si une fonctionnalitÃ© est dÃ©bloquÃ©e
  bool isFeatureUnlocked(UnlockableFeature feature, int currentLevel) {
    return currentLevel >= (_featureLevelRequirements[feature] ?? 100);
  }



  void reset() {
    // RÃ©initialiser tous les Ã©tats des fonctionnalitÃ©s
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








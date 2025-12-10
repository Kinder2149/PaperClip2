// lib/models/progression_system.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../constants/game_config.dart';
import 'event_system.dart';
import 'dart:math' show pow;
import 'json_loadable.dart';

/// Système de bonus de progression
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
      10: 1.2,  // Accès au marché
      15: 1.3,  // Maîtrise de la production
      25: 1.4,  // Maîtrise commerciale
      35: 1.5,  // Excellence industrielle
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
  DateTime _lastComboTime = DateTime.now();

  int get comboCount => _comboCount;
  int get currentCombo => _comboCount;
  set currentCombo(int value) => _comboCount = value;
  
  double _comboMultiplierValue = 1.0;
  double get comboMultiplier => _comboMultiplierValue;
  set comboMultiplier(double value) => _comboMultiplierValue = value;
  
  Timer? get comboTimer => _comboTimer;
  DateTime get lastComboTime => _lastComboTime;

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
    _lastComboTime = DateTime.now();
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
  DateTime? _lastClaimDate;
  int _streakDays = 0;

  bool get claimed => _claimed;
  bool get hasClaimedToday => _claimed;
  set hasClaimedToday(bool value) => _claimed = value;
  
  DateTime? get lastClaimDate => _lastClaimDate;
  set lastClaimDate(DateTime? date) => _lastClaimDate = date;
  
  int get streakDays => _streakDays;
  set streakDays(int days) => _streakDays = days;
  
  Timer? get resetTimer => _resetTimer;

  void setClaimed(bool value) {
    _claimed = value;
    if (value) {
      _scheduleReset();
    }
  }

  bool claimDailyBonus(LevelSystem levelSystem) {
    if (!_claimed) {
      levelSystem.addExperience(_bonusAmount, ExperienceType.DAILY_BONUS);
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
  bool _rewardClaimed = false;
  bool get rewardClaimed => _rewardClaimed;
  set rewardClaimed(bool value) => _rewardClaimed = value;
  double get targetAmount => target;

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
class MissionSystem implements JsonLoadable {
  List<Mission> dailyMissions = [];
  List<Mission> weeklyMissions = [];
  List<Mission> achievements = [];
  Timer? missionRefreshTimer;
  DateTime? lastMissionRefreshTime;
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
    // Enregistrer le moment du dernier rafraîchissement des missions
    lastMissionRefreshTime = DateTime.now();
    missionRefreshTimer = Timer.periodic(
      const Duration(hours: 24),
          (_) {
        generateDailyMissions();
        lastMissionRefreshTime = DateTime.now();
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

  @override
  void fromJson(Map<String, dynamic> json) {
    try {
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
      
      // Charger la date du dernier rafraîchissement des missions
      if (json['lastMissionRefreshTime'] != null) {
        lastMissionRefreshTime = DateTime.parse(json['lastMissionRefreshTime'] as String);
      } else if (json['lastRefresh'] != null) {
        lastMissionRefreshTime = DateTime.parse(json['lastRefresh'] as String);
      } else {
        // Si aucune date n'est disponible, utiliser la date actuelle
        lastMissionRefreshTime = DateTime.now();
      }
    } catch (e, stack) {
      print('Error loading mission system: $e');
      print('Stack trace: $stack');
      _resetToDefaults();
    }
  }
  
  /// Réinitialise les valeurs par défaut
  void _resetToDefaults() {
    dailyMissions = [];
    weeklyMissions = [];
    achievements = [];
    // Regénérer les missions par défaut
    generateDailyMissions();
    generateWeeklyMissions();
  }

  /// Renvoie des informations détaillées sur la progression des missions
  Map<String, dynamic> getDetailedMissionProgress() {
    return {
      'daily': dailyMissions.map((mission) => {
        'id': mission.id,
        'progress': mission.progress,
        'target': mission.targetAmount,
        'isCompleted': mission.isCompleted,
        'rewardClaimed': mission.rewardClaimed,
      }).toList(),
      'weekly': weeklyMissions.map((mission) => {
        'id': mission.id,
        'progress': mission.progress,
        'target': mission.targetAmount,
        'isCompleted': mission.isCompleted,
        'rewardClaimed': mission.rewardClaimed,
      }).toList(),
      'lastRefresh': lastMissionRefreshTime?.toIso8601String(),
    };
  }

  void dispose() {
    missionRefreshTimer?.cancel();
  }
}

/// Système de niveaux
class LevelSystem with ChangeNotifier implements JsonLoadable {
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
  // Alias pour être compatible avec le code de sauvegarde
  double get currentXP => _experience;
  int get currentLevel => _level;
  double get xpToNextLevel => calculateExperienceRequirement(_level + 1);
  
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
        description: "Début de l'aventure - Production manuelle",
        unlockedFeatures: ['manual_production'],
        initialExperienceRequirement: 155
    ),
    2: LevelUnlock(
        description: "Gestion des ressources - Achat de métal",
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
        description: "Système d'améliorations débloqué",
        unlockedFeatures: ['upgrades'],
        pathOptions: [
          PathOption(ProgressionPath.EFFICIENCY, 0.4),
          PathOption(ProgressionPath.INNOVATION, 0.3)
        ],
        initialExperienceRequirement: 366
    ),
    8: LevelUnlock(
        description: "Interface du marché débloquée",
        unlockedFeatures: ['market_screen'],
        pathOptions: [
          PathOption(ProgressionPath.MARKETING, 0.5),
          PathOption(ProgressionPath.EFFICIENCY, 0.3)
        ],
        initialExperienceRequirement: 580
    ),
    10: LevelUnlock(
        description: "Accès aux ventes sur le marché",
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
        description: "Maîtrise commerciale",
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
  
  // Ajoute de l'expérience au joueur - méthode principale
  void addExperience(double amount, [ExperienceType type = ExperienceType.GENERAL]) {
    // Vérifie que le montant est positif
    if (amount <= 0) return;
    
    print('Gaining experience: $amount (type: $type)'); // Log initial amount
    
    // Applique les multiplicateurs
    double baseAmount = amount * totalXpMultiplier;
    double levelPenalty = _level * 0.02;
    double adjustedAmount = baseAmount * (1 - levelPenalty);
    
    // Bonus pour les bas niveaux
    if (_level < 35) {
      adjustedAmount *= 1.1;
    }
    
    // Ajout d'un bonus supplémentaire si l'activité correspond au chemin de progression actuel
    if (_experienceTypeMatchesPath(type, _currentPath)) {
      adjustedAmount *= 1.2;  // 20% de bonus pour les activités sur le chemin choisi
    }
    
    print('Adjusted experience: $adjustedAmount'); // Log adjusted amount
    
    // Ajout de l'expérience avec un minimum garanti
    _experience += max(adjustedAmount, 0.2);
    
    print('Current experience: $_experience'); // Log current experience
    print('Experience for next level: ${calculateExperienceRequirement(_level + 1)}'); // Log required experience
    
    // Met à jour le combo si applicable
    if (type != ExperienceType.DAILY_BONUS && type != ExperienceType.COMBO_BONUS) {
      comboSystem.incrementCombo();
    }
    
    // Vérifie si le joueur peut monter de niveau
    _checkLevelUp();
    
    // Notifie les écouteurs
    notifyListeners();
  }
  
  // Méthode alias pour la compatibilité avec le code existant
  void gainExperience(double amount) {
    addExperience(amount, ExperienceType.PRODUCTION);
  }
  
  // Vérifie si le type d'expérience correspond au chemin de progression
  bool _experienceTypeMatchesPath(ExperienceType type, ProgressionPath path) {
    switch (path) {
      case ProgressionPath.PRODUCTION:
        return type == ExperienceType.PRODUCTION;
      case ProgressionPath.MARKETING:
        return type == ExperienceType.SALE;
      case ProgressionPath.EFFICIENCY:
        return type == ExperienceType.GENERAL || type == ExperienceType.DAILY_BONUS;
      case ProgressionPath.INNOVATION:
        return type == ExperienceType.UPGRADE || type == ExperienceType.COMBO_BONUS;
      default:
        return false;
    }
  }
  void _handleLevelUp(int newLevel) {
    final unlocks = _levelUnlocks[newLevel];
    if (unlocks != null) {
      EventManager.instance.addEvent(
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
    double baseXP = 100.0;
    double linearIncrease = level * 50.0;  // Composante linéaire plus douce
    double smallExponential = pow(1.05, level).toDouble();  // Conversion explicite en double

    // Facteur de palier pour différentes phases du jeu
    double tierMultiplier = 1.0;

    // Paliers progressifs
    if (level > 25) tierMultiplier = 1.2;
    if (level > 35) tierMultiplier = 1.5;

    // Protection contre les valeurs trop grandes
    double totalXP = (baseXP + linearIncrease + smallExponential) * tierMultiplier;

    // Arrondi à 1 décimale pour plus de clarté
    return double.parse(totalXP.toStringAsFixed(1));
  }

  // La définition de gainExperience a été déplacée en haut de la classe pour éviter les duplications
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
    double baseXP = 2.0;
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    addExperience(baseXP * bonusXP, ExperienceType.PRODUCTION);
  }

  void addAutomaticProduction(int amount) {
    double baseXP = 0.15 * amount;
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    addExperience(baseXP * bonusXP, ExperienceType.PRODUCTION);
  }

  /// Ajoute de l'expérience pour la production manuelle de trombones
  void addManualProduction() {
    // Production manuelle = 1 trombone, mais avec un bonus XP plus élevé
    double baseXP = 0.25; // Un peu plus élevé que la production automatique
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    // Incrémenter le compteur de combo
    comboSystem.incrementCombo();
    // Appliquer le multiplicateur de combo
    double comboMultiplier = comboSystem.getComboMultiplier();
    addExperience(baseXP * bonusXP * comboMultiplier, ExperienceType.PRODUCTION);
  }

  void addSale(int quantity, double price) {
    double baseXP = 0.4 * quantity * (1 + (price - 0.25) * 2);
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    addExperience(baseXP * bonusXP, ExperienceType.SALE);
  }

  void addAutoclipperPurchase() {
    addExperience(4, ExperienceType.UPGRADE);
  }

  void addUpgradePurchase(int upgradeLevel) {
    addExperience(2.5 * upgradeLevel, ExperienceType.UPGRADE);
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
      EventManager.instance.addEvent(
          EventType.LEVEL_UP,
          "Niveau $newLevel atteint !",
          description: "Continuez votre progression !",
          importance: EventImportance.HIGH
      );
    } else {
      for (var feature in newFeatures) {
        final details = LevelSystem.getUnlockDetails(feature);
        EventManager.instance.addEvent(
            EventType.LEVEL_UP,
            "Niveau $newLevel atteint !",
            description: details.name,
            detailedDescription: '''
${details.description}

📋 Comment utiliser :
${details.howToUse}

✨ Avantages :
${details.benefits.map((b) => '• $b').join('\n')}

💡 Conseils :
${details.tips.map((t) => '• $t').join('\n')}
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

  @override
  void fromJson(Map<String, dynamic> json) {
    try {
      _experience = (json['experience'] as num?)?.toDouble() ?? 0;
      _level = (json['level'] as num?)?.toInt() ?? 1;
      _currentPath = ProgressionPath.values[json['currentPath'] ?? 0];
      _xpMultiplier = (json['xpMultiplier'] as num?)?.toDouble() ?? 1.0;
      comboSystem.setComboCount(json['comboCount'] ?? 0);
      dailyBonus.setClaimed(json['dailyBonusClaimed'] ?? false);
      _checkLevelUp();
    } catch (e, stack) {
      print('Error loading level system: $e');
      print('Stack trace: $stack');
      _resetToDefaults();
    }
    notifyListeners();
  }
  
  /// Méthode de compatibilité temporaire
  void loadFromJson(Map<String, dynamic> json) {
    fromJson(json);
  }
  
  /// Réinitialise les valeurs par défaut
  void _resetToDefaults() {
    _experience = 0;
    _level = 1;
    _currentPath = ProgressionPath.values[0];
    _xpMultiplier = 1.0;
    comboSystem.setComboCount(0);
    dailyBonus.setClaimed(false);
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
    // Phase d'Introduction (1-5)
    UnlockableFeature.MANUAL_PRODUCTION: 1,    // Production de base
    UnlockableFeature.METAL_PURCHASE: 2,       // Déplacé du niveau 1 au 2
    UnlockableFeature.AUTOCLIPPERS: 3,         // Reste au niveau 3
    UnlockableFeature.UPGRADES: 5,             // Reste au niveau 5

    // Phase de Développement (6-15)
    UnlockableFeature.MARKET_SCREEN: 8,        // Déplacé du niveau 7 au 8
    UnlockableFeature.MARKET_SALES: 10,        // Déplacé du niveau 9 au 10
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

// lib/managers/crisis_manager.dart
// Améliorer la gestion du mode crise

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/event_system.dart';
import '../models/game_config.dart';
import '../dialogs/metal_crisis_dialog.dart';
import 'dart:async';

/// Manager responsable de la gestion des états de crise dans le jeu
class CrisisManager extends ChangeNotifier {
  // === ÉTAT ===
  bool _isInCrisisMode = false;
  bool _crisisTransitionComplete = false;
  DateTime? _crisisStartTime;
  bool _showingCrisisView = false;
  final Set<String> _sentCrisisNotifications = {};
  bool _isInitialized = false;
  BuildContext? _context;

  // Ajout d'un drapeau pour éviter les déclenchements multiples
  bool _isDialogCurrentlyDisplayed = false;
  bool _crisisTriggeredButNotProcessed = false;

  // Ajout d'un timer pour les opérations différées
  Timer? _transitionTimer;

  // === CALLBACKS ===
  final VoidCallback? onCrisisTriggered;
  final VoidCallback? onCrisisTransitionComplete;
  final void Function(int score)? onCompetitiveGameEnd;

  // === DÉPENDANCES ===
  final GameMode Function() getGameMode;
  final int Function() calculateCompetitiveScore;
  final Function() saveOnImportantEvent;

  /// Constructeur avec injection de dépendances
  CrisisManager({
    this.onCrisisTriggered,
    this.onCrisisTransitionComplete,
    this.onCompetitiveGameEnd,
    required this.getGameMode,
    required this.calculateCompetitiveScore,
    required this.saveOnImportantEvent,
  });

  // === GETTERS ===
  bool get isInCrisisMode => _isInCrisisMode;
  bool get crisisTransitionComplete => _crisisTransitionComplete;
  DateTime? get crisisStartTime => _crisisStartTime;
  bool get showingCrisisView => _showingCrisisView;
  bool get isInitialized => _isInitialized;
  // Ajout d'un getter pour vérifier si une tentative est en cours
  bool get isCrisisProcessInProgress => _isDialogCurrentlyDisplayed || _crisisTriggeredButNotProcessed;

  // === MÉTHODES PUBLIQUES ===

  /// Définit le contexte pour afficher les dialogues
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Déclenche le mode crise
  Future<void> enterCrisisMode() async {
    // Vérification pour empêcher les déclenchements multiples
    if (_isInCrisisMode || _isDialogCurrentlyDisplayed || _crisisTriggeredButNotProcessed) {
      debugPrint("Mode crise déjà actif ou en cours de traitement - ignoré");
      return;
    }

    debugPrint("⚠️ DÉCLENCHEMENT MODE CRISE");

    // Mettre le drapeau à true pour éviter les déclenchements multiples
    _crisisTriggeredButNotProcessed = true;

    // Pour le mode infini, nous devons nous assurer que le dialogue s'affiche correctement
    if (_context != null && _context!.mounted) {
      _isDialogCurrentlyDisplayed = true;

      try {
        // Afficher le dialogue avec un délai pour éviter les problèmes de rebuild
        await Future.delayed(const Duration(milliseconds: 100));

        if (!_context!.mounted) {
          debugPrint("Contexte perdu avant affichage du dialogue");
          _activateCrisisMode();
          return;
        }

        bool? result = await showDialog<bool>(
          context: _context!,
          barrierDismissible: false,
          builder: (context) => MetalCrisisDialog(
            onTransitionComplete: () {
              // Activer explicitement le mode crise avec un léger délai
              Future.delayed(const Duration(milliseconds: 300), () {
                _activateCrisisMode();
              });
            },
          ),
        );

        // Si le dialogue a été fermé sans résultat (ex: par back button)
        if (result != true) {
          // Activer quand même le mode crise pour éviter un état incohérent
          debugPrint("Dialogue fermé sans action - activation différée du mode crise");
          // Utilisez un délai pour éviter les problèmes de transition
          _transitionTimer = Timer(const Duration(milliseconds: 500), () {
            _activateCrisisMode();
          });
        }
      } catch (e) {
        debugPrint("Erreur lors de l'affichage du dialogue: $e");
        // En cas d'erreur, activer quand même le mode crise avec un délai
        _transitionTimer = Timer(const Duration(milliseconds: 500), () {
          _activateCrisisMode();
        });
      } finally {
        _isDialogCurrentlyDisplayed = false;
      }
    } else {
      // Activation directe si pas de contexte, avec un léger délai
      debugPrint("Pas de contexte disponible - activation différée du mode crise");
      _transitionTimer = Timer(const Duration(milliseconds: 500), () {
        _activateCrisisMode();
      });
    }
  }

  // Méthode privée pour activer réellement le mode crise
  void _activateCrisisMode() {
    // Protection supplémentaire contre les activations multiples
    if (_isInCrisisMode) return;

    _isInCrisisMode = true;
    _crisisStartTime = DateTime.now();
    _crisisTriggeredButNotProcessed = false;

    debugPrint("Mode crise activé avec succès");

    // Notifier le changement de mode
    EventManager.instance.addEvent(
        EventType.CRISIS_MODE,
        "Mode Crise Activé",
        description: "Adaptation nécessaire : plus de métal disponible !",
        importance: EventImportance.CRITICAL,
        additionalData: {
          'timestamp': _crisisStartTime!.toIso8601String(),
          'marketMetalStock': 0,
        }
    );

    // Activer les nouvelles fonctionnalités après un court délai
    Future.delayed(const Duration(milliseconds: 300), () {
      _unlockCrisisFeatures();
    });

    // Sauvegarder l'état avec un délai pour éviter les problèmes de transition
    Future.delayed(const Duration(milliseconds: 500), () {
      saveOnImportantEvent();
    });

    // Notifier pour la gestion externe
    onCrisisTriggered?.call();

    notifyListeners();
  }

  /// Gère la fin d'une partie compétitive
  void handleCompetitiveGameEnd() {
    if (getGameMode() != GameMode.COMPETITIVE || !_isInCrisisMode) return;

    // Calculer les métriques de la partie compétitive
    final competitiveScore = calculateCompetitiveScore();

    // Appeler le callback de fin de partie compétitive
    onCompetitiveGameEnd?.call(competitiveScore);
  }

  /// Bascule entre l'interface normale et l'interface de crise
  void toggleCrisisInterface() {
    if (!isInCrisisMode || !crisisTransitionComplete) return;

    _showingCrisisView = !_showingCrisisView;

    EventManager.instance.addEvent(
      EventType.UI_CHANGE,
      "Changement de vue",
      description: _showingCrisisView
          ? "Mode Production activé"
          : "Mode Normal activé",
      importance: EventImportance.LOW,
    );

    notifyListeners();
  }

  /// Vérifie si la transition en mode crise est valide
  bool validateCrisisTransition() {
    if (!_isInCrisisMode) {
      debugPrint("Erreur: Mode crise non activé");
      return false;
    }

    if (!_crisisTransitionComplete) {
      debugPrint("Erreur: Transition non terminée");
      return false;
    }

    saveOnImportantEvent();
    return true;
  }

  // === MÉTHODES PRIVÉES ===

  /// Débloque les fonctionnalités du mode crise
  void _unlockCrisisFeatures() {
    // Supprimer les références au recyclage
    _crisisTransitionComplete = true;

    // Notifier le changement de mode
    EventManager.instance.addEvent(
        EventType.CRISIS_MODE,
        "Mode Production Activé",
        description: "Vous pouvez maintenant produire votre propre métal !",
        importance: EventImportance.CRITICAL
    );

    // Callback pour la gestion externe
    onCrisisTransitionComplete?.call();

    notifyListeners();
  }

  // === IMPLÉMENTATION DE BASEMANAGER ===

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('CrisisManager initialisé');
  }

  @override
  void start() {
    // Rien à démarrer pour ce manager
  }

  @override
  void pause() {
    // Rien à mettre en pause pour ce manager
  }

  @override
  void resume() {
    // Rien à reprendre pour ce manager
  }

  @override
  void dispose() {
    // Nettoyer les ressources
    _transitionTimer?.cancel();
    _isInitialized = false;
    super.dispose();
  }

  @override
  Map<String, dynamic> toJson() => {
    'isInCrisisMode': _isInCrisisMode,
    'crisisTransitionComplete': _crisisTransitionComplete,
    'crisisStartTime': _crisisStartTime?.toIso8601String(),
    'showingCrisisView': _showingCrisisView,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    // Charger l'état à partir du JSON
    _isInCrisisMode = json['isInCrisisMode'] as bool? ?? false;
    _crisisTransitionComplete = json['crisisTransitionComplete'] as bool? ?? false;
    _showingCrisisView = json['showingCrisisView'] as bool? ?? false;

    // Réinitialiser les drapeaux de contrôle
    _isDialogCurrentlyDisplayed = false;
    _crisisTriggeredButNotProcessed = false;

    if (json['crisisStartTime'] != null) {
      try {
        _crisisStartTime = DateTime.parse(json['crisisStartTime'] as String);
      } catch (e) {
        debugPrint('Erreur de parsing de la date de crise: $e');
        _crisisStartTime = _isInCrisisMode ? DateTime.now() : null;
      }
    }

    notifyListeners();
  }
}
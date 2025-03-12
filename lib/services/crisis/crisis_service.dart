import 'package:flutter/material.dart';
import 'package:paperclip2/models/game_config.dart';
import 'package:paperclip2/models/event_system.dart';
import 'package:paperclip2/dialogs/metal_crisis_dialog.dart';
import 'package:paperclip2/screens/competitive_result_screen.dart';
import 'crisis_interface.dart';

/// Implémentation du service de gestion de crise
class CrisisService extends ChangeNotifier implements CrisisInterface {
  bool _isInCrisisMode = false;
  DateTime? _crisisStartTime;
  bool _crisisTransitionComplete = false;
  
  // Fonction de sauvegarde à appeler lors d'événements importants
  final Future<void> Function() _saveCallback;
  
  // Fonction pour naviguer vers l'écran de résultats compétitifs
  final void Function() _navigateToCompetitiveResults;
  
  /// Constructeur
  CrisisService({
    required Future<void> Function() saveCallback,
    required void Function() navigateToCompetitiveResults,
    bool isInCrisisMode = false,
    DateTime? crisisStartTime,
    bool crisisTransitionComplete = false,
  }) : 
    _saveCallback = saveCallback,
    _navigateToCompetitiveResults = navigateToCompetitiveResults,
    _isInCrisisMode = isInCrisisMode,
    _crisisStartTime = crisisStartTime,
    _crisisTransitionComplete = crisisTransitionComplete;
  
  @override
  bool get isInCrisisMode => _isInCrisisMode;
  
  @override
  DateTime? get crisisStartTime => _crisisStartTime;
  
  @override
  bool get isCrisisTransitionComplete => _crisisTransitionComplete;
  
  @override
  Future<void> enterCrisisMode(BuildContext? context) async {
    if (_isInCrisisMode) return;
    
    debugPrint("Début de la transition vers le mode crise");
    
    // Gérer spécifiquement le mode compétitif
    if (context != null && context.findAncestorWidgetOfExactType<CompetitiveResultScreen>() != null) {
      // Enregistrer que la crise est active
      _isInCrisisMode = true;
      _crisisStartTime = DateTime.now();
      
      // Notifier le changement de mode
      EventManager.instance.addEvent(
        EventType.CRISIS_MODE,
        "Mode Crise Activé",
        description: "Fin de partie compétitive : plus de métal disponible !",
        importance: EventImportance.CRITICAL,
        additionalData: {
          'timestamp': _crisisStartTime!.toIso8601String(),
          'competitiveMode': true,
        }
      );
      
      // Sauvegarder l'état avant d'afficher les résultats
      await _saveCallback();
      
      // Gérer la fin de partie compétitive
      await handleCompetitiveGameEnd();
      return;
    }
    
    // Code pour le mode infini
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MetalCrisisDialog(
          onTransitionComplete: () {
            // Activer le mode crise après la fermeture du dialogue
            _isInCrisisMode = true;
            _crisisStartTime = DateTime.now();
            
            // Notifier le changement de mode
            EventManager.instance.addEvent(
              EventType.CRISIS_MODE,
              "Mode Crise Activé",
              description: "Adaptation nécessaire : plus de métal disponible !",
              importance: EventImportance.CRITICAL,
              additionalData: {
                'timestamp': _crisisStartTime!.toIso8601String(),
              }
            );
            
            // Activer les nouvelles fonctionnalités
            unlockCrisisFeatures();
            
            _saveCallback(); // Sauvegarder l'état après la transition
            notifyListeners();
          },
        ),
      );
    } else {
      // Si pas de contexte, activer directement le mode crise
      _isInCrisisMode = true;
      _crisisStartTime = DateTime.now();
      
      EventManager.instance.addEvent(
        EventType.CRISIS_MODE,
        "Mode Crise Activé",
        description: "Adaptation nécessaire : plus de métal disponible !",
        importance: EventImportance.CRITICAL,
        additionalData: {
          'timestamp': _crisisStartTime!.toIso8601String(),
        }
      );
      
      unlockCrisisFeatures();
      _saveCallback();
      notifyListeners();
    }
  }
  
  @override
  Future<void> handleCompetitiveGameEnd() async {
    // Naviguer vers l'écran de résultats compétitifs
    _navigateToCompetitiveResults();
  }
  
  @override
  void unlockCrisisFeatures() {
    // Marquer la transition comme terminée
    _crisisTransitionComplete = true;
    
    // Notifier le changement de mode
    EventManager.instance.addEvent(
      EventType.CRISIS_MODE,
      "Mode Production Activé",
      description: "Vous pouvez maintenant produire votre propre métal !",
      importance: EventImportance.CRITICAL
    );
    
    notifyListeners();
  }
  
  @override
  bool shouldTriggerCrisis(double marketMetalStock, GameMode gameMode) {
    // Vérifier si une crise doit être déclenchée
    if (marketMetalStock <= 0 && !_isInCrisisMode) {
      return true;
    }
    return false;
  }
  
  @override
  Duration getCrisisDuration() {
    if (_crisisStartTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_crisisStartTime!);
  }
  
  @override
  Duration? getRemainingCrisisTime() {
    if (_crisisStartTime == null) {
      return null;
    }
    
    // Dans cet exemple, nous supposons que la crise dure 24 heures
    final crisisEndTime = _crisisStartTime!.add(const Duration(hours: 24));
    final now = DateTime.now();
    
    if (now.isAfter(crisisEndTime)) {
      return Duration.zero;
    }
    
    return crisisEndTime.difference(now);
  }
  
  @override
  bool isCrisisOver() {
    final remainingTime = getRemainingCrisisTime();
    return remainingTime != null && remainingTime == Duration.zero;
  }
  
  @override
  void endCrisis() {
    _isInCrisisMode = false;
    _crisisTransitionComplete = false;
    _crisisStartTime = null;
    
    EventManager.instance.addEvent(
      EventType.CRISIS_MODE,
      "Mode Crise Terminé",
      description: "Le marché du métal s'est stabilisé.",
      importance: EventImportance.HIGH
    );
    
    notifyListeners();
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'isInCrisisMode': _isInCrisisMode,
      'crisisStartTime': _crisisStartTime?.toIso8601String(),
      'crisisTransitionComplete': _crisisTransitionComplete,
    };
  }
  
  @override
  void fromJson(Map<String, dynamic> json) {
    _isInCrisisMode = json['isInCrisisMode'] as bool? ?? false;
    _crisisTransitionComplete = json['crisisTransitionComplete'] as bool? ?? false;
    
    final crisisStartTimeStr = json['crisisStartTime'] as String?;
    if (crisisStartTimeStr != null) {
      _crisisStartTime = DateTime.parse(crisisStartTimeStr);
    } else {
      _crisisStartTime = null;
    }
    
    notifyListeners();
  }
} 
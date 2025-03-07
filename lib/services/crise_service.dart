import 'dart:async';
import 'dart:math';
import '../utils/constantes/jeu_constantes.dart';

class CriseService {
  bool _criseMetalActive = false;
  Timer? _timerCrise;
  final Random _random = Random();
  final Function(String, String, String) onNotification;
  final Function(double) onPrixMetalChange;

  CriseService({
    required this.onNotification,
    required this.onPrixMetalChange,
  });

  bool get criseMetalActive => _criseMetalActive;
  
  void demarrer() {
    _timerCrise = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _verifierDeclenchementCrise(),
    );
  }

  void arreter() {
    _timerCrise?.cancel();
    _timerCrise = null;
  }

  void _verifierDeclenchementCrise() {
    if (!_criseMetalActive && _random.nextDouble() < 0.1) { // 10% de chance
      _declencherCriseMetal();
    }
  }

  void _declencherCriseMetal() {
    _criseMetalActive = true;
    final multiplicateurPrix = 2 + _random.nextDouble() * 3; // Entre 2x et 5x
    
    onNotification(
      'Crise du Métal !',
      'Une pénurie mondiale de métal fait grimper les prix !',
      'crise',
    );
    
    onPrixMetalChange(JeuConstantes.METAL_PAR_TROMBONE * multiplicateurPrix);

    // La crise dure entre 2 et 5 minutes
    Future.delayed(
      Duration(minutes: 2 + _random.nextInt(3)),
      _terminerCriseMetal,
    );
  }

  void _terminerCriseMetal() {
    _criseMetalActive = false;
    onNotification(
      'Fin de la Crise',
      'Les prix du métal reviennent à la normale',
      'info',
    );
    onPrixMetalChange(JeuConstantes.METAL_PAR_TROMBONE);
  }

  // Effets de la crise
  double ajusterCoutMetal(double cout) {
    if (_criseMetalActive) {
      return cout * (2 + _random.nextDouble() * 3);
    }
    return cout;
  }
} 
import 'package:flutter/material.dart';

// Import des écrans
import '../ecrans/production/ecran_production.dart';
import '../ecrans/marche/ecran_marche.dart';
import '../ecrans/ameliorations/ecran_ameliorations.dart';
import '../ecrans/statistiques/ecran_statistiques.dart';

class Routes {
  static const String production = '/production';
  static const String marche = '/marche';
  static const String ameliorations = '/ameliorations';
  static const String statistiques = '/statistiques';

  static Map<String, WidgetBuilder> get routes => {
    production: (context) => const EcranProduction(),
    marche: (context) => const EcranMarche(),
    ameliorations: (context) => const EcranAmeliorations(),
    statistiques: (context) => const EcranStatistiques(),
  };
} 
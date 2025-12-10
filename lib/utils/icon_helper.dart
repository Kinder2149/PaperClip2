// lib/utilities/icon_helper.dart
import 'package:flutter/material.dart';

/// Une classe utilitaire pour gérer les icônes de manière constante.
/// Résout le problème de secouage d'arborescence d'icônes lors de la compilation en mode release.
class IconHelper {
  /// Retourne une IconData constante pour un code d'icône donné.
  /// Cela résout l'erreur "non-constant invocation of IconData" pendant la compilation release.
  static IconData getIconForCode(int iconCode) {
    // Nous utilisons une correspondance entre codes et icônes constantes prédéfinies
    switch (iconCode) {
      case 0xe3e7: // notification
        return Icons.notifications;
      case 0xe5ca: // check
        return Icons.check;
      case 0xe88e: // info
        return Icons.info;
      case 0xe002: // warning
        return Icons.warning;
      case 0xe888: // error
        return Icons.error;
      case 0xe8b6: // search
        return Icons.search;
      case 0xe037: // play_arrow
        return Icons.play_arrow;
      case 0xe8f4: // settings
        return Icons.settings;
      case 0xe8f8: // star
        return Icons.star;
      case 0xe873: // home
        return Icons.home;
      case 0xe8b8: // security
        return Icons.security;
      case 0xe89c: // level_up
        return Icons.upgrade;
      case 0xe9e4: // emoji_events
        return Icons.emoji_events;
      case 0xe161: // save
        return Icons.save;
      case 0xe872: // delete
        return Icons.delete;
      case 0xe94b: // money
        return Icons.attach_money;
      case 0xe0e0: // paperclip
        return Icons.push_pin;
      case 0xe14d: // refresh
        return Icons.refresh;
      case 0xe7fd: // person
        return Icons.person;
      case 0xe9ba: // folder
        return Icons.folder;
      case 0xe99b: // analytics
        return Icons.analytics;
      // Si l'icône n'est pas trouvée, retourner une icône par défaut
      default:
        return Icons.circle;
    }
  }
}

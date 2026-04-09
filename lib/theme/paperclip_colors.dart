// lib/theme/paperclip_colors.dart
import 'package:flutter/material.dart';

/// Palette de couleurs "Paperclip" inspirée de l'univers du jeu
/// 
/// Thème : Métal, production industrielle, innovation technologique
class PaperclipColors {
  PaperclipColors._();
  
  // ==================== COULEURS PRIMAIRES ====================
  
  /// Bleu acier - Métal, solidité, structure
  /// Utilisé pour : AppBar, boutons primaires, éléments structurels
  static const Color steelBlue = Color(0xFF2C3E50);
  static const Color steelBlueLight = Color(0xFF34495E);
  static const Color steelBlueDark = Color(0xFF1A252F);
  
  /// Orange cuivré - Production, énergie, chaleur
  /// Utilisé pour : Boutons secondaires, accents, production
  static const Color copperOrange = Color(0xFFE67E22);
  static const Color copperOrangeLight = Color(0xFFE59866);
  static const Color copperOrangeDark = Color(0xFFCA6F1E);
  
  /// Cyan électrique - Innovation, technologie, futur
  /// Utilisé pour : Recherche, agents IA, éléments tech
  static const Color electricCyan = Color(0xFF00BCD4);
  static const Color electricCyanLight = Color(0xFF4DD0E1);
  static const Color electricCyanDark = Color(0xFF00838F);
  
  // ==================== COULEURS SÉMANTIQUES ====================
  
  /// Vert - Succès, argent, gains
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFF52BE80);
  static const Color successDark = Color(0xFF1E8449);
  
  /// Rouge - Erreur, danger, alerte
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFEC7063);
  static const Color errorDark = Color(0xFFC0392B);
  
  /// Jaune - Avertissement, attention
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFF5B041);
  static const Color warningDark = Color(0xFFD68910);
  
  /// Bleu info - Information, neutre
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFF5DADE2);
  static const Color infoDark = Color(0xFF2874A6);
  
  // ==================== COULEURS RESSOURCES (Contextuelles) ====================
  
  /// Argent - Vert monétaire
  static const Color money = Color(0xFF27AE60);
  static const Color moneyLight = Color(0xFF52BE80);
  
  /// Trombones - Bleu ciel
  static const Color paperclips = Color(0xFF3498DB);
  static const Color paperclipsLight = Color(0xFF5DADE2);
  
  /// Métal - Gris métallique
  static const Color metal = Color(0xFF95A5A6);
  static const Color metalLight = Color(0xFFBDC3C7);
  static const Color metalDark = Color(0xFF7F8C8D);
  
  /// Quantum - Violet mystique
  static const Color quantum = Color(0xFF9B59B6);
  static const Color quantumLight = Color(0xFFAF7AC5);
  static const Color quantumDark = Color(0xFF7D3C98);
  
  /// Points Innovation - Orange énergique
  static const Color innovation = Color(0xFFE67E22);
  static const Color innovationLight = Color(0xFFE59866);
  static const Color innovationDark = Color(0xFFCA6F1E);
  
  // ==================== COULEURS NEUTRES ====================
  
  /// Noir profond - Backgrounds dark mode
  static const Color neutral900 = Color(0xFF1A1A1A);
  static const Color neutral800 = Color(0xFF2D2D2D);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral600 = Color(0xFF666666);
  static const Color neutral500 = Color(0xFF808080);
  static const Color neutral400 = Color(0xFF999999);
  static const Color neutral300 = Color(0xFFB3B3B3);
  static const Color neutral200 = Color(0xFFCCCCCC);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral50 = Color(0xFFFAFAFA);
  
  // ==================== COULEURS SPÉCIALES ====================
  
  /// Overlay pour dialogs et modals
  static const Color overlay = Color(0x80000000); // 50% noir
  
  /// Divider - Séparateurs
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);
  
  /// Shadow - Ombres
  static const Color shadow = Color(0x1A000000); // 10% noir
  static const Color shadowDark = Color(0x33000000); // 20% noir
  
  // ==================== HELPERS ====================
  
  /// Retourne la couleur pour une ressource donnée
  static Color getResourceColor(String resourceType) {
    switch (resourceType.toLowerCase()) {
      case 'money':
      case 'argent':
        return money;
      case 'paperclips':
      case 'trombones':
        return paperclips;
      case 'metal':
      case 'métal':
        return metal;
      case 'quantum':
        return quantum;
      case 'innovation':
      case 'points innovation':
        return innovation;
      default:
        return neutral500;
    }
  }
  
  /// Retourne la couleur sémantique
  static Color getSemanticColor(String type) {
    switch (type.toLowerCase()) {
      case 'success':
      case 'succès':
        return success;
      case 'error':
      case 'erreur':
        return error;
      case 'warning':
      case 'avertissement':
        return warning;
      case 'info':
      case 'information':
        return info;
      default:
        return neutral500;
    }
  }
  
  /// Retourne une couleur avec opacité
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}

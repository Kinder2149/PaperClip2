// lib/theme/paperclip_typography.dart
import 'package:flutter/material.dart';

/// Typographie "Paperclip" - Roboto avec scales cohérentes
/// 
/// Utilise Roboto pour sa lisibilité et son aspect moderne/industriel
class PaperclipTypography {
  PaperclipTypography._();
  
  /// Famille de police principale
  static const String fontFamily = 'Roboto';
  
  // ==================== HEADINGS ====================
  
  /// H1 - Titres principaux (32px, bold)
  /// Usage : Titres de pages, headers importants
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  /// H2 - Sous-titres (24px, bold)
  /// Usage : Titres de sections, panels
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  /// H3 - Titres tertiaires (20px, semibold)
  /// Usage : Sous-sections, cards importantes
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
  );
  
  /// H4 - Petits titres (18px, semibold)
  /// Usage : Headers de cards, groupes
  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // ==================== BODY TEXT ====================
  
  /// Body Large - Texte principal large (16px)
  /// Usage : Texte principal, descriptions importantes
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  /// Body Medium - Texte principal (14px)
  /// Usage : Texte standard, la plupart du contenu
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  /// Body Small - Petit texte (12px)
  /// Usage : Texte secondaire, notes
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  // ==================== SPECIAL ====================
  
  /// Button - Texte de boutons (16px, semibold)
  /// Usage : Tous les boutons
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  /// Button Small - Petits boutons (14px, semibold)
  /// Usage : Boutons compacts, actions secondaires
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  /// Caption - Légendes (12px, regular)
  /// Usage : Labels, légendes, timestamps
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
  
  /// Overline - Surtitre (10px, semibold, uppercase)
  /// Usage : Catégories, tags, labels supérieurs
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.2,
  );
  
  /// Label - Labels de formulaires (14px, medium)
  /// Usage : Labels d'inputs, checkboxes
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  // ==================== NUMERIC ====================
  
  /// Display Large - Grands nombres (48px, bold)
  /// Usage : Statistiques principales, grands chiffres
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.1,
    letterSpacing: -1.0,
  );
  
  /// Display Medium - Nombres moyens (36px, bold)
  /// Usage : Stats importantes, compteurs
  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  /// Display Small - Petits nombres (24px, semibold)
  /// Usage : Valeurs, métriques
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  // ==================== HELPERS ====================
  
  /// Retourne un TextTheme complet pour Material
  static TextTheme getTextTheme({bool isDark = false}) {
    final baseColor = isDark ? Colors.white : Colors.black87;
    
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: baseColor),
      displayMedium: displayMedium.copyWith(color: baseColor),
      displaySmall: displaySmall.copyWith(color: baseColor),
      headlineLarge: h1.copyWith(color: baseColor),
      headlineMedium: h2.copyWith(color: baseColor),
      headlineSmall: h3.copyWith(color: baseColor),
      titleLarge: h4.copyWith(color: baseColor),
      titleMedium: bodyLarge.copyWith(color: baseColor, fontWeight: FontWeight.w500),
      titleSmall: bodyMedium.copyWith(color: baseColor, fontWeight: FontWeight.w500),
      bodyLarge: bodyLarge.copyWith(color: baseColor),
      bodyMedium: bodyMedium.copyWith(color: baseColor),
      bodySmall: bodySmall.copyWith(color: baseColor),
      labelLarge: button.copyWith(color: baseColor),
      labelMedium: buttonSmall.copyWith(color: baseColor),
      labelSmall: caption.copyWith(color: baseColor),
    );
  }
}

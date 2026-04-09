import 'package:flutter/material.dart';

/// Constantes de design réutilisables pour l'application PaperClip2
/// 
/// Ce fichier centralise tous les tokens de design (espacements, tailles, opacités, etc.)
/// pour assurer une cohérence visuelle à travers toute l'application.
class DesignTokens {
  // Empêcher l'instanciation
  DesignTokens._();

  // ==================== ESPACEMENTS ====================
  
  /// Espacement petit (8px) - Entre éléments proches
  static const double kSpacingSmall = 8.0;
  
  /// Espacement moyen (12px) - Entre éléments dans une section
  static const double kSpacingMedium = 12.0;
  
  /// Espacement large (16px) - Padding de cards
  static const double kSpacingLarge = 16.0;
  
  /// Espacement entre sections (20px)
  static const double kSpacingSectionGap = 20.0;

  // ==================== TAILLES EMOJI ====================
  
  /// Emoji petit (20px) - Pour chips et petits éléments
  static const double kEmojiSizeSmall = 20.0;
  
  /// Emoji moyen (24px) - Pour cards et boutons
  static const double kEmojiSizeMedium = 24.0;
  
  /// Emoji large (32px) - Pour headers de panels
  static const double kEmojiSizeLarge = 32.0;

  // ==================== OPACITÉS ====================
  
  /// Opacité légère (0.1) - Pour backgrounds colorés
  static const double kColorOpacityLight = 0.1;
  
  /// Opacité moyenne (0.3) - Pour bordures colorées
  static const double kColorOpacityMedium = 0.3;

  // ==================== BORDER RADIUS ====================
  
  /// Border radius petit (8px)
  static const double kBorderRadiusSmall = 8.0;
  
  /// Border radius moyen (12px) - Standard pour cards
  static const double kBorderRadiusMedium = 12.0;

  // ==================== TAILLES DE TEXTE ====================
  
  /// Taille texte pour labels (12px)
  static const double kTextSizeLabel = 12.0;
  
  /// Taille texte pour valeurs (18px)
  static const double kTextSizeValue = 18.0;
  
  /// Taille texte pour boutons (16px)
  static const double kTextSizeButton = 16.0;
  
  /// Taille texte pour petits labels (14px)
  static const double kTextSizeSmallLabel = 14.0;

  // ==================== LARGEURS DE BORDURE ====================
  
  /// Largeur bordure standard (1.5px)
  static const double kBorderWidthStandard = 1.5;
  
  /// Largeur bordure fine (1px)
  static const double kBorderWidthThin = 1.0;

  // ==================== HAUTEURS ====================
  
  /// Hauteur séparateur vertical (50px)
  static const double kSeparatorHeight = 50.0;
  
  /// Padding bouton standard (20px)
  static const double kButtonPaddingStandard = 20.0;
  
  /// Padding bouton compact (16px)
  static const double kButtonPaddingCompact = 16.0;

  // ==================== HELPERS ====================
  
  /// Retourne un EdgeInsets avec padding standard pour cards
  static EdgeInsets get cardPadding => const EdgeInsets.all(kSpacingLarge);
  
  /// Retourne un SizedBox avec espacement entre sections
  static SizedBox get sectionGap => const SizedBox(height: kSpacingSectionGap);
  
  /// Retourne un SizedBox avec espacement moyen
  static SizedBox get mediumGap => const SizedBox(height: kSpacingMedium);
  
  /// Retourne un SizedBox avec espacement petit
  static SizedBox get smallGap => const SizedBox(height: kSpacingSmall);
  
  /// Retourne un BorderRadius standard
  static BorderRadius get standardBorderRadius => BorderRadius.circular(kBorderRadiusMedium);
}

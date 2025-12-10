// lib/services/save_system/data_sanitizer.dart
// Service pour la sanitisation des données de sauvegarde

import 'package:flutter/foundation.dart';

/// Service responsable de la sanitisation des données de sauvegarde.
///
/// Cette classe fournit des méthodes pour garantir que les données
/// sont correctement typées avant d'être sauvegardées ou après leur chargement,
/// afin d'éviter les erreurs de typage lors des opérations de sauvegarde/chargement.
class DataSanitizer {
  /// Sanitise récursivement une structure de données pour garantir la compatibilité avec JSON.
  ///
  /// Cette méthode convertit les structures complexes en types simples compatibles JSON :
  /// - Map => Map<String, dynamic>
  /// - Convertit les nombres en double ou int selon leur type réel
  /// - Gère les listes récursivement
  /// - Filtre les valeurs null selon le paramètre [removeNulls]
  ///
  /// Retourne une structure de données garantie compatible JSON ou null en cas d'erreur.
  static dynamic sanitizeData(dynamic data, {bool removeNulls = false}) {
    try {
      if (data == null) {
        return null;
      } else if (data is num) {
        // Préserver le type numérique exact (int ou double)
        return data;
      } else if (data is String) {
        return data;
      } else if (data is bool) {
        return data;
      } else if (data is DateTime) {
        // Convertir DateTime en String ISO8601
        return data.toIso8601String();
      } else if (data is List) {
        // Traitement récursif des listes
        final sanitizedList = <dynamic>[];
        for (var item in data) {
          final sanitizedItem = sanitizeData(item, removeNulls: removeNulls);
          if (!removeNulls || sanitizedItem != null) {
            sanitizedList.add(sanitizedItem);
          }
        }
        return sanitizedList;
      } else if (data is Map) {
        // Conversion en Map<String, dynamic> avec traitement récursif
        final sanitizedMap = <String, dynamic>{};
        // Utiliser une conversion de type explicite pour éviter les erreurs Never?
        final Map safeMap = data;
        // Utiliser un for-in avec entries au lieu de forEach
        for (var entry in safeMap.entries) {
          // Convertir la clé en String si nécessaire
          final String stringKey = entry.key.toString();
          final sanitizedValue = sanitizeData(entry.value, removeNulls: removeNulls);
          if (!removeNulls || sanitizedValue != null) {
            sanitizedMap[stringKey] = sanitizedValue;
          }
        }
        return sanitizedMap;
      } else {
        // Pour les autres types, tenter une conversion en String
        if (kDebugMode) {
          print('DataSanitizer: Conversion de type non standard (${data.runtimeType}) en String');
        }
        return data.toString();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sanitisation des données: $e');
      }
      return null;
    }
  }

  /// Sanitise spécifiquement une Map pour garantir qu'elle est de type Map<String, dynamic>
  ///
  /// Cette méthode est particulièrement utile pour sanitiser les données de jeu
  /// avant la sauvegarde.
  static Map<String, dynamic>? sanitizeMap(Map<dynamic, dynamic> map, {bool removeNulls = false}) {
    try {
      return sanitizeData(map, removeNulls: removeNulls) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sanitisation de Map: $e');
      }
      return null;
    }
  }

  /// Sanitise les valeurs numériques pour éviter les problèmes d'arrondi et les NaN/Infinity
  ///
  /// Cette méthode traite les cas spéciaux comme NaN, Infinity et vérifie les dépassements.
  static num sanitizeNumber(num value, {num defaultValue = 0}) {
    if (value.isNaN || value.isInfinite) {
      return defaultValue;
    }
    
    // Si c'est un double avec partie fractionnaire nulle, convertir en int
    if (value is double && value == value.toInt()) {
      return value.toInt();
    }
    
    return value;
  }

  /// Nettoie une chaîne de caractères des valeurs potentiellement problématiques
  static String sanitizeString(String value, {String defaultValue = ""}) {
    if (value.isEmpty) {
      return defaultValue;
    }
    
    // Enlever les caractères de contrôle et les espaces en début/fin
    return value.trim();
  }
}

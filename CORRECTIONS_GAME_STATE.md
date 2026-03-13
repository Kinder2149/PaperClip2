# 🔧 Corrections à Appliquer dans game_state.dart

## ⚠️ PROBLÈME : Le fichier contient des null bytes qui empêchent l'édition automatique

Vous devez appliquer manuellement les corrections suivantes dans `lib/models/game_state.dart` :

---

## **CORRECTION #1 : Renforcer `setPartieId()` avec logs et exceptions**

### 📍 Localisation : Ligne ~88-96

### ❌ Code actuel :
```dart
void setPartieId(String id) {
  // Enforce UUID v4 format (cloud-first invariant: identité technique stricte)
  final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$');
  if (uuidV4.hasMatch(id)) {
    _partieId = id;
  } else {
    // Ignorer les identifiants non conformes (aucune création implicite ici)
  }
}
```

### ✅ Code corrigé :
```dart
void setPartieId(String id) {
  // Enforce UUID v4 format (cloud-first invariant: identité technique stricte)
  final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$');
  if (uuidV4.hasMatch(id)) {
    // CORRECTION: Logger le changement d'identité pour traçabilité
    if (kDebugMode && _partieId != null && _partieId != id) {
      print('[GameState] ⚠️ Changement de partieId détecté: $_partieId → $id');
    }
    _partieId = id;
  } else {
    // CORRECTION: Logger l'erreur au lieu d'ignorer silencieusement
    if (kDebugMode) {
      print('[GameState] ❌ Tentative d\'assignation d\'un partieId invalide (non UUID v4): "$id"');
      print('[GameState] Stack trace:');
      print(StackTrace.current);
    }
    // CORRECTION: Lever une exception en mode debug pour détecter les bugs
    throw ArgumentError('[GameState] partieId doit être un UUID v4 valide, reçu: "$id"');
  }
}
```

---

## **CORRECTION #2 : Corriger `applySnapshot()` pour utiliser `setPartieId()`**

### 📍 Localisation : Rechercher "void applySnapshot(GameSnapshot snapshot)" (vers la fin du fichier)

### ❌ Code actuel :
```dart
// ID technique (UUID) si présent dans les métadonnées du snapshot
final metaPartieId = metadata['partieId'] as String?;
if (_partieId == null && metaPartieId != null && metaPartieId.isNotEmpty) {
  _partieId = metaPartieId;
}
```

### ✅ Code corrigé :
```dart
// CORRECTION CRITIQUE: Toujours écraser le partieId lors du chargement d'un snapshot
// et utiliser setPartieId() pour validation UUID v4
final metaPartieId = metadata['partieId'] as String?;
if (metaPartieId != null && metaPartieId.isNotEmpty) {
  // CORRECTION: Utiliser setPartieId() au lieu d'assignation directe
  // Cela garantit la validation UUID v4 et la traçabilité
  try {
    setPartieId(metaPartieId);
  } catch (e) {
    // Si le partieId du snapshot est invalide, logger et continuer
    if (kDebugMode) {
      print('[GameState] ⚠️ Snapshot contient un partieId invalide: "$metaPartieId"');
      print('[GameState] Erreur: $e');
    }
    // Ne pas bloquer le chargement, mais signaler le problème
  }
}
```

---

## **CORRECTION #3 : Ajouter vérification d'intégrité dans `loadGameById()`**

### 📍 Localisation : `lib/services/persistence/game_persistence_orchestrator.dart` ligne ~1237

### Ajouter après le chargement complet (ligne ~1485) :

```dart
// CORRECTION: Vérification d'intégrité post-chargement
final loadedId = state.partieId;
if (loadedId != id) {
  _logger.error('[LOAD] ⚠️ INCOHÉRENCE CRITIQUE: partieId ne correspond pas', 
    code: 'load_id_mismatch', ctx: {
      'expected': id,
      'actual': loadedId,
    });
  throw StateError(
    'LOAD_ID_MISMATCH: L\'identité de la partie chargée ne correspond pas.\n'
    'Attendu: $id\n'
    'Obtenu: $loadedId\n'
    'Cela indique une corruption des données ou un bug dans le système de sauvegarde.'
  );
}

_logger.info('[LOAD] ✅ Vérification d\'intégrité réussie', code: 'load_integrity_ok', ctx: {
  'partieId': id,
  'gameName': state.gameName,
});
```

---

## 📋 Instructions d'Application

1. **Ouvrir** `lib/models/game_state.dart`
2. **Appliquer CORRECTION #1** : Remplacer la méthode `setPartieId()` complète
3. **Appliquer CORRECTION #2** : Modifier le bloc d'assignation de `partieId` dans `applySnapshot()`
4. **Ouvrir** `lib/services/persistence/game_persistence_orchestrator.dart`
5. **Appliquer CORRECTION #3** : Ajouter la vérification d'intégrité à la fin de `loadGameById()`

---

## ✅ Tests de Validation

Après avoir appliqué les corrections, tester le scénario suivant :

1. Connexion + création partie 1
2. Jouer partie 1 jusqu'au niveau 3, sauvegarder
3. Retour page mondes → vérifier affichage correct
4. Charger partie 2
5. **Vérifier les logs dans la console** : Doit afficher "Changement de partieId détecté"
6. Retour page mondes → **VÉRIFIER : Les deux parties doivent être distinctes**
7. Jouer partie 2, sauvegarder
8. Retour page mondes → **VÉRIFIER : Aucune perte de données**

---

## 🎯 Résultat Attendu

- ✅ Les changements de `partieId` sont tracés dans les logs
- ✅ Les tentatives d'assignation d'ID invalides lèvent des exceptions
- ✅ Le chargement d'un snapshot met toujours à jour le `partieId` correctement
- ✅ Une vérification d'intégrité garantit la cohérence après chargement
- ✅ Plus de confusion entre les mondes lors des changements de contexte

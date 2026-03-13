# ✅ Corrections Manuelles Immédiates - À Appliquer Maintenant

## 🎯 État Actuel

Le script Python a **partiellement réussi** :
- ✅ **Correction #2 appliquée** : `applySnapshot()` utilise maintenant `setPartieId()`
- ⚠️ **Correction #1 requise** : `setPartieId()` doit être corrigé manuellement

## 🔧 Correction #1 : Modifier `setPartieId()` dans game_state.dart

### **Fichier** : `lib/models/game_state.dart` (ligne ~88)

### **Rechercher** :
```dart
void setPartieId(String id) {
  // Enforce UUID v4 format (cloud-first invariant: identité technique stricte)
  final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}?$');
  if (uuidV4.hasMatch(id)) {
    _partieId = id;
  } else {
    // Ignorer les identifiants non conformes (aucune création implicite ici)
  }
}
```

### **Remplacer par** :
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

### **Changements clés** :
1. Regex corrigée : `{12}?$` → `{12} ?$` (espace optionnel)
2. Ajout de logs pour tracer les changements d'identité
3. Ajout d'une exception `ArgumentError` pour les ID invalides
4. Stack trace pour debugging

---

## 🔧 Correction #3 : Ajouter vérification dans `loadGameById()`

### **Fichier** : `lib/services/persistence/game_persistence_orchestrator.dart` (ligne ~1485)

### **Localiser** :
Chercher la fin de la méthode `Future<void> loadGameById(GameState state, String id, {bool allowRestore = true})` 

### **Ajouter AVANT le dernier `}`** :
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
  }
```

---

## ✅ Test Immédiat

Après avoir appliqué les corrections :

```powershell
# Recompiler l'app
flutter clean
flutter run

# Observer les logs dans la console
# Vous devriez voir :
# [GameState] ⚠️ Changement de partieId détecté: <uuid1> → <uuid2>
# [LOAD] ✅ Vérification d'intégrité réussie
```

---

## 🎯 Scénario de Test

1. Créer "Monde Test 1"
2. Jouer jusqu'au niveau 2
3. Retour liste des mondes
4. Créer "Monde Test 2"
5. Retour liste des mondes
6. **VÉRIFIER** : Les deux mondes sont présents
7. Charger "Monde Test 1"
8. **OBSERVER LES LOGS** : Changement de partieId détecté
9. Retour liste des mondes
10. **VÉRIFIER** : Les deux mondes sont toujours présents

---

## 📊 Résultat Attendu

- ✅ Aucune perte de données
- ✅ Aucune duplication
- ✅ Logs clairs dans la console
- ✅ Exceptions levées pour les ID invalides

---

## 🚨 Si Problème

Si vous voyez une exception `ArgumentError` :
1. C'est **normal** - cela signifie qu'un ID invalide a été détecté
2. Vérifier les logs pour identifier la source
3. Corriger la source du problème (snapshot corrompu, etc.)

---

## ⏭️ Prochaines Étapes

Une fois ces corrections appliquées et testées :
1. Appliquer Phase 2 (Renforcement persistance)
2. Appliquer Phase 3 (Amélioration UI)
3. Créer les tests automatisés (Phase 4)

Voir `PLAN_CORRECTION_COMPLET.md` pour les détails complets.

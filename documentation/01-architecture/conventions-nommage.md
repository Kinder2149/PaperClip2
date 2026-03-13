# Conventions de Nommage — PaperClip2

**Date** : 15 janvier 2026  
**Statut** : ✅ ACTIF

---

## Identifiants de Monde

### Terme Canonique : `worldId`

**Utilisation recommandée :**
- ✅ UI et écrans utilisateur
- ✅ Documentation utilisateur
- ✅ Noms de méthodes publiques
- ✅ Paramètres d'API client

**Exemple :**
```dart
Future<void> deleteWorld({required String worldId}) { ... }
```

**Justification :**
- Plus explicite pour l'utilisateur final
- Cohérent avec la terminologie UI ("Monde")
- Évite la confusion avec "partie" (terme technique)

---

### Terme Technique : `partieId`

**Utilisation acceptée :**
- ✅ Code backend (routes `/saves/:partieId`)
- ✅ Persistance locale (clés de stockage)
- ✅ Logs techniques
- ✅ Noms de variables internes

**Exemple :**
```typescript
app.get('/saves/:partieId', async (req, res) => { ... });
```

**Justification :**
- Historique du projet (terme legacy)
- Cohérent avec l'architecture backend existante
- Acceptable dans le code technique interne

---

## Équivalence Stricte

⚠️ **IMPORTANT** : `worldId` et `partieId` sont **strictement équivalents**.

- **Même format** : UUID v4
- **Même valeur** : `abc-123-def-456`
- **Même usage** : Identifiant technique unique

### Exemple de Cohérence

```dart
// Client Flutter
final worldId = 'abc-123-def-456';
await cloudAdapter.pushById(partieId: worldId, ...);

// Backend Firebase Functions
// PUT /worlds/:worldId → Stocké dans players/{uid}/saves/{partieId}
```

---

## Migration Progressive

### Phase Actuelle

Les deux termes coexistent comme alias pour faciliter la transition.

**Règles actuelles :**
1. Nouveau code public → Préférer `worldId`
2. Code legacy → Accepter `partieId`
3. Documenter l'équivalence dans les commentaires

### Objectif Long Terme

Standardiser sur `worldId` partout (client + backend).

**Timeline :**
- **Q1 2026** : Documentation + Alias (actuel)
- **Q2 2026** : Migration progressive des appels
- **Q3 2026** : Suppression des `@Deprecated`

---

## Règles pour Nouveau Code

### ✅ À FAIRE

```dart
// Méthode publique avec worldId
Future<void> saveWorld({required String worldId}) {
  return _saveInternal(partieId: worldId);
}

// Commentaire explicite
/// Sauvegarde un monde par son worldId (identifiant technique UUID v4).
/// Note: partieId est un alias legacy de worldId.
```

### ❌ À ÉVITER

```dart
// Nouvelle méthode publique avec partieId
Future<void> saveWorld({required String partieId}) { ... }

// Pas de commentaire sur l'équivalence
Future<void> saveWorld({required String worldId}) { ... }
```

---

## Checklist par Composant

### Backend (Firebase Functions)

- [x] Routes `/saves/:partieId` → Garder (compatibilité)
- [x] Routes `/worlds/:worldId` → Alias canonique
- [x] Documentation API → Clarifier équivalence
- [ ] Logs → Utiliser `worldId` dans les nouveaux logs

### Client Flutter

#### Services de Persistance

- [x] `GamePersistenceOrchestrator` → Alias ajoutés
- [x] `CloudPersistenceAdapter` → Utilise `partieId` en interne
- [x] `SavesFacade` → Méthodes `*ByWorldId` ajoutées
- [ ] Nouveaux services → Utiliser `worldId`

#### UI

- [x] `WorldsScreen` → Utilise `worldId` partout
- [x] `WorldCard` → Affiche "Monde" (pas "Partie")
- [ ] Nouveaux écrans → Utiliser `worldId`

---

## Exemples de Migration

### Avant (Legacy)

```dart
// Service
Future<void> pushCloudFromSaveId({required String partieId}) { ... }

// Appel
await orchestrator.pushCloudFromSaveId(partieId: myId);
```

### Après (Recommandé)

```dart
// Service avec alias
Future<void> pushCloudFromWorldId({required String worldId}) {
  return _pushInternal(partieId: worldId);
}

@Deprecated('Use pushCloudFromWorldId instead')
Future<void> pushCloudFromSaveId({required String partieId}) {
  return pushCloudFromWorldId(worldId: partieId);
}

// Appel
await orchestrator.pushCloudFromWorldId(worldId: myId);
```

---

## FAQ

### Pourquoi ne pas tout renommer d'un coup ?

**Risque de breaking changes** : Renommer tous les `partieId` en `worldId` nécessiterait :
- Modification de 50+ fichiers
- Mise à jour de tous les tests
- Risque de régression
- Coordination backend/client

**Approche progressive** : Les alias permettent une transition sans risque.

### Le backend doit-il changer ses routes ?

**Non.** Les routes `/saves/:partieId` restent pour compatibilité.

Les routes `/worlds/:worldId` sont des alias qui utilisent le même stockage Firestore (`players/{uid}/saves/{partieId}`).

### Comment gérer les anciens snapshots ?

**Aucun changement nécessaire.** Les snapshots existants utilisent déjà `partieId` ou `worldId` de manière interchangeable dans les métadonnées.

Le backend accepte les deux noms de champs.

---

## Validation

### Tests de Non-Régression

```dart
test('worldId and partieId are interchangeable', () async {
  final id = const Uuid().v4();
  
  // Push avec partieId
  await adapter.pushById(partieId: id, ...);
  
  // Pull avec worldId (même ID)
  final data = await adapter.pullById(partieId: id);
  
  expect(data, isNotNull);
});
```

### Checklist de Migration

Pour chaque nouveau fichier/méthode :
- [ ] Utilise `worldId` dans les signatures publiques
- [ ] Documente l'équivalence avec `partieId`
- [ ] Ajoute un alias `@Deprecated` si remplace une méthode legacy
- [ ] Tests passent avec les deux termes

---

## Références

- [Architecture Globale](./ARCHITECTURE_GLOBALE.md)
- [API Backend](./backend/firebase_functions_api.md)
- [Guide Migration](./MIGRATION_PARTIE_TO_WORLD.md)

---

**Dernière mise à jour** : 15 janvier 2026  
**Auteur** : Équipe PaperClip2

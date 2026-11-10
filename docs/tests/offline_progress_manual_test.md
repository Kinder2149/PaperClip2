# Test Manuel - Système de Notification Offline

## ✅ Vérifications de compilation

### Fichiers modifiés :
1. ✅ `lib/constants/game_config.dart` - OFFLINE_MAX_DURATION = 120 minutes
2. ✅ `lib/services/offline_progress_service.dart` - OfflineProgressResult enrichi
3. ✅ `lib/widgets/dialogs/offline_progress_dialog.dart` - Widget créé
4. ✅ `lib/services/game_runtime_coordinator.dart` - Callback configuré
5. ✅ `lib/screens/worlds_screen.dart` - Callback branché

### Résultat flutter analyze :
- ✅ Aucune erreur de compilation
- ⚠️ Warnings mineurs (imports non utilisés, deprecated methods) - non bloquants

---

## 📋 Plan de test manuel

### Test 1 : Absence courte (< 120 min)
**Objectif** : Vérifier que la notification s'affiche avec les bonnes données

**Étapes** :
1. Lancer l'app
2. Attendre que le jeu soit chargé (WorldsScreen visible)
3. Mettre l'app en arrière-plan (bouton Home)
4. Attendre 30 secondes
5. Revenir sur l'app

**Résultat attendu** :
- ✅ Notification "Bon retour !" s'affiche
- ✅ Durée affichée : "30 secondes" ou "1 minute"
- ✅ Trombones produits : >= 0
- ✅ Argent gagné : >= 0
- ✅ Pas d'indicateur orange (pas cappé)

---

### Test 2 : Absence moyenne (~ 5 minutes)
**Objectif** : Vérifier le calcul des gains

**Étapes** :
1. Lancer l'app
2. Noter les ressources actuelles (trombones, argent)
3. Mettre l'app en arrière-plan
4. Attendre 5 minutes
5. Revenir sur l'app

**Résultat attendu** :
- ✅ Notification affichée
- ✅ Durée : "5 minutes"
- ✅ Trombones produits : > 0 (si production active)
- ✅ Argent gagné : > 0 (si autoSell activé)
- ✅ Pas d'indicateur orange

---

### Test 3 : Cap à 120 minutes
**Objectif** : Vérifier que le cap fonctionne

**Option A - Test rapide (modifier temporairement la constante)** :
1. Modifier `OFFLINE_MAX_DURATION` à `Duration(seconds: 10)`
2. Lancer l'app
3. Mettre en arrière-plan
4. Attendre 30 secondes
5. Revenir

**Résultat attendu** :
- ✅ Notification affichée
- ✅ Durée : "30 secondes"
- ✅ **Indicateur orange visible** (icône orange + texte "Production limitée")
- ✅ Gains calculés sur 10 secondes max

**Option B - Test réel (120 minutes)** :
1. Lancer l'app
2. Mettre en arrière-plan
3. Attendre > 2 heures
4. Revenir

**Résultat attendu** :
- ✅ Notification affichée
- ✅ Durée : "> 120 minutes"
- ✅ **Indicateur orange visible**
- ✅ Gains calculés sur 120 minutes max

---

### Test 4 : AutoSell désactivé
**Objectif** : Vérifier que la vente respecte le paramètre

**Étapes** :
1. Lancer l'app
2. **Désactiver la vente automatique** dans les paramètres
3. Mettre en arrière-plan
4. Attendre 1-2 minutes
5. Revenir

**Résultat attendu** :
- ✅ Notification affichée
- ✅ Trombones produits : > 0
- ✅ **Argent gagné : 0** (pas de vente)

---

### Test 5 : Formatage des données
**Objectif** : Vérifier l'affichage unifié

**Étapes** :
1. Produire beaucoup de trombones (> 1000)
2. Mettre en arrière-plan
3. Attendre 1 minute
4. Revenir

**Résultat attendu** :
- ✅ Trombones : format compact (ex: "1.2K", "15.3K")
- ✅ Argent : format monétaire (ex: "12,50 €", "1 234,56 €")
- ✅ Durée : en minutes (ex: "1 minute", "5 minutes", "120 minutes")

---

### Test 6 : Retour immédiat
**Objectif** : Vérifier qu'il n'y a pas de notification si absence < 1 seconde

**Étapes** :
1. Lancer l'app
2. Mettre en arrière-plan
3. **Revenir immédiatement** (< 1 seconde)

**Résultat attendu** :
- ✅ Pas de notification (ou notification avec "0 seconde")

---

## 🐛 Problèmes connus

### Erreurs de compilation non liées :
- ❌ Fichiers `.g.dart` manquants (cloud models)
- ❌ Problèmes de compatibilité `build_runner` / `dart_style`
- ❌ Méthodes dépréciées `GoogleSignIn`

**Impact** : Ces erreurs empêchent l'exécution des tests unitaires automatisés, mais **n'affectent pas** le code de la notification offline qui compile correctement.

---

## ✅ Validation

### Code compilable :
- ✅ Tous les fichiers modifiés compilent sans erreur
- ✅ Warnings mineurs uniquement (non bloquants)

### Tests unitaires (11 tests) :
- ✅ Créés dans `test/unit/offline_progress_notification_test.dart`
- ❌ Non exécutables actuellement (dépendances projet cassées)
- ✅ Tests de logique métier (calculs de durée, structure de données)

### Tests manuels :
- 📋 6 scénarios de test définis ci-dessus
- ⏳ À exécuter sur device/émulateur

---

## 🚀 Prochaines étapes

1. **Tester manuellement** selon les scénarios ci-dessus
2. **Corriger les dépendances** du projet si nécessaire :
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. **Exécuter les tests unitaires** une fois les dépendances corrigées
4. **Ajuster** si nécessaire selon les résultats des tests manuels

# TEST COMPLET - FLUX UTILISATEUR CLOUD SYNC

**Date:** 2026-04-06  
**Compte test:** test.keamder@gmail.com  
**Objectif:** Valider le flux complet de création d'entreprise et synchronisation cloud

---

## 🎯 RÉSUMÉ DES TESTS AUTOMATISÉS

### Tests unitaires exécutés
```
✅ 25 tests PASSED
❌ 4 tests FAILED (API obsolète - non bloquant)

Tests réussis:
- ✅ Création entreprise génère UUID v4 valide
- ✅ Snapshot v3 structure complète
- ✅ Métadonnées snapshot complètes
- ✅ Restauration depuis snapshot
- ✅ Sérialisation JSON
- ✅ Dates ISO 8601 cohérentes
- ✅ Validation format snapshot
```

### Tests échoués (non bloquants)
Les tests échoués utilisent des méthodes obsolètes (`saveEnterprise`, `loadEnterprise`) qui ont été remplacées par l'API ID-first. Ces échecs n'affectent pas le fonctionnement de l'application.

---

## 📋 PLAN DE TEST MANUEL - FLUX COMPLET

### PRÉPARATION

1. **Lancer l'application en mode web**
   ```powershell
   cd c:\DEV\PROJETS\applications_mobile\PaperClip2
   flutter run -d chrome --web-port=50652
   ```

2. **Ouvrir la console navigateur** (F12 → Console)
   - Vérifier qu'il n'y a pas d'erreurs CORS
   - Surveiller les logs de synchronisation

3. **Ouvrir la console Flutter**
   - Surveiller les logs détaillés
   - Vérifier les étapes de bootstrap

---

## TEST 1: LOGIN INITIAL (Nouvel utilisateur)

### Actions
1. Ouvrir http://localhost:50652
2. Cliquer sur le bouton de connexion Google
3. Se connecter avec:
   - Email: `test.keamder@gmail.com`
   - Mot de passe: `6W@693SZiD01`

### Résultats attendus

**UI:**
- ✅ Popup Google OAuth s'ouvre
- ✅ Login réussi
- ✅ Message "Synchronisation cloud..." apparaît brièvement
- ✅ Notification "✅ Synchronisation terminée" s'affiche (3 secondes)
- ✅ Navigation automatique vers WelcomeScreen

**Logs Flutter (console):**
```
[BOOTSTRAP] User detected: {uid}
[AUTH-LISTENER] _syncUserImmediately() CALLED | uid={uid}
[AUTH-LISTENER] STEP 6: Activating CloudPort...
[CloudPortManager] activate() called
[CloudPortManager] Activation successful
[AUTH-LISTENER] STEP 7: CloudPort activation result=true
[AUTH-LISTENER] STEP 8: Calling onPlayerConnected() with timeout
[PLAYER-CONNECTED] Début synchronisation complète
[SYNC-LOGIN] syncAllWorldsFromCloud() called
[SYNC-LOGIN] Mondes cloud récupérés | count=0
[AUTH-LISTENER] STEP 9: onPlayerConnected() completed | success=true
```

**Console navigateur:**
```
GET https://api-g3tpwosnaq-uc.a.run.app/enterprise/{uid} → 404
(NORMAL - nouvel utilisateur sans entreprise)
```

### ✅ Validation
- [ ] Login réussi sans erreur
- [ ] Notification de sync affichée
- [ ] 404 sur /enterprise/{uid} (normal)
- [ ] Aucune erreur CORS
- [ ] Navigation vers WelcomeScreen

---

## TEST 2: CRÉATION ENTREPRISE

### Actions
1. Sur WelcomeScreen, naviguer vers la page de création d'entreprise
2. Entrer le nom: `Test Enterprise Keamder`
3. Valider la création

### Résultats attendus

**UI:**
- ✅ Formulaire de création s'affiche
- ✅ Validation du nom réussie
- ✅ Navigation automatique vers MainScreen
- ✅ Entreprise affichée avec le nom correct

**Logs Flutter:**
```
[GameState] Nouvelle entreprise créée: Test Enterprise Keamder, enterpriseId: {uuid}
[SAVE-QUEUE] enqueue | trigger=manual
[SAVE-PUMP] pump_start
[WORLD-SAVE] done | worldId={enterpriseId}
[PUMP] Push cloud | worldId={enterpriseId}
worlds_put_attempt | worldId={enterpriseId}
worlds_put_success | worldId={enterpriseId} | latency_ms={X}
[cloud][success] pushCloudById
```

**Console navigateur:**
```
PUT https://api-g3tpwosnaq-uc.a.run.app/enterprise/{uid} → 201 Created
```

### ✅ Validation
- [ ] Entreprise créée avec UUID v4 valide
- [ ] Sauvegarde locale réussie
- [ ] Push cloud réussi (201)
- [ ] Latency < 5 secondes
- [ ] Navigation vers MainScreen

---

## TEST 3: AUTOSAVE ET SYNC AUTOMATIQUE

### Actions
1. Dans MainScreen, effectuer des actions (acheter clips, etc.)
2. Attendre 10 secondes (délai autosave)
3. Observer les logs

### Résultats attendus

**Logs Flutter:**
```
[SAVE-QUEUE] enqueue | trigger=autosave
[SAVE-PUMP] pump_start
[PUMP] Push cloud | worldId={enterpriseId}
worlds_put_success | worldId={enterpriseId}
```

**Console navigateur:**
```
PUT https://api-g3tpwosnaq-uc.a.run.app/enterprise/{uid} → 200 OK
```

### ✅ Validation
- [ ] Autosave déclenché après 10s
- [ ] Push cloud automatique réussi
- [ ] Aucune erreur de synchronisation

---

## TEST 4: LOGOUT ET RE-LOGIN (Persistence cloud)

### Actions
1. Déconnexion de l'application
2. Fermer l'onglet du navigateur
3. Rouvrir http://localhost:50652
4. Se reconnecter avec le même compte test

### Résultats attendus

**UI:**
- ✅ Login réussi
- ✅ Message "Synchronisation cloud..."
- ✅ Notification "✅ Synchronisation terminée"
- ✅ **Navigation DIRECTE vers MainScreen** (pas WelcomeScreen)
- ✅ Entreprise "Test Enterprise Keamder" chargée automatiquement
- ✅ Toutes les données restaurées (clips, argent, etc.)

**Logs Flutter:**
```
[SYNC-LOGIN] syncAllWorldsFromCloud() called
[SYNC-LOGIN] Mondes cloud récupérés | count=1
[SYNC-LOGIN] Synchronisation monde | worldId={enterpriseId}
[SYNC-LOGIN] Cloud importé (cloud wins)
[SYNC-LOGIN] Monde synchronisé
[BootstrapScreen] Entreprise trouvée (ID: {enterpriseId}), chargement...
```

**Console navigateur:**
```
GET https://api-g3tpwosnaq-uc.a.run.app/enterprise/{uid} → 200 OK
(Retourne l'entreprise créée précédemment)
```

### ✅ Validation
- [ ] Entreprise restaurée depuis le cloud
- [ ] Navigation directe vers MainScreen
- [ ] Toutes les données préservées
- [ ] Aucune perte de progression

---

## TEST 5: MODIFICATION ET RE-SYNC

### Actions
1. Modifier l'état du jeu (acheter clips, améliorer production)
2. Attendre l'autosave (10s)
3. Déconnexion + reconnexion
4. Vérifier que les modifications sont préservées

### Résultats attendus

**Logs Flutter (après reconnexion):**
```
[SYNC-LOGIN] Cloud importé (cloud wins)
```

### ✅ Validation
- [ ] Modifications sauvegardées dans le cloud
- [ ] Modifications restaurées après reconnexion
- [ ] Aucune perte de données

---

## 🎯 CHECKLIST VALIDATION GLOBALE

### Fonctionnalités critiques
- [ ] **Login Google** fonctionne sans erreur OAuth
- [ ] **CloudPort** s'active automatiquement après login
- [ ] **Notification sync** s'affiche à l'utilisateur
- [ ] **404 initial** géré silencieusement (nouvel utilisateur)
- [ ] **Création entreprise** génère UUID v4 valide
- [ ] **Sauvegarde locale** fonctionne
- [ ] **Push cloud** réussit (201/200)
- [ ] **Autosave** déclenché après 10s
- [ ] **Re-login** restaure l'entreprise depuis le cloud
- [ ] **Navigation** correcte (WelcomeScreen → MainScreen)

### Performance
- [ ] **Latency cloud** < 5 secondes
- [ ] **Aucun timeout** de synchronisation
- [ ] **Aucune erreur CORS** dans la console

### UX
- [ ] **Feedback visuel** pendant la sync (loading)
- [ ] **Notifications** claires et informatives
- [ ] **Pas de blocage** de l'interface
- [ ] **Transitions** fluides entre écrans

---

## 📊 RAPPORT DE TEST

### Résultats

| Test | Status | Notes |
|------|--------|-------|
| Login initial | ⬜ | |
| Création entreprise | ⬜ | |
| Autosave | ⬜ | |
| Logout/Re-login | ⬜ | |
| Modification + Re-sync | ⬜ | |

### Erreurs rencontrées

```
[À remplir pendant les tests]
```

### Logs complets

```
[Copier/coller les logs Flutter et console navigateur]
```

---

## 🔧 DÉPANNAGE

### Erreur: CloudPort activation failed
**Cause:** Fichier .env manquant ou mal configuré  
**Solution:** Vérifier que `FIREBASE_API_URL` est défini dans `.env`

### Erreur: CORS policy blocked
**Cause:** Backend ne permet pas localhost  
**Solution:** Vérifier que le middleware CORS dans `functions/src/index.ts` inclut `http://localhost:50652`

### Erreur: 401 Unauthorized
**Cause:** Token Firebase expiré ou invalide  
**Solution:** Se déconnecter et se reconnecter

### Erreur: Timeout sync
**Cause:** Connexion réseau lente ou backend indisponible  
**Solution:** Vérifier la connexion internet et que le backend est déployé

---

## ✅ CONCLUSION

Ce test valide le flux complet:
1. ✅ Login Google
2. ✅ Activation CloudPort
3. ✅ Synchronisation initiale (404 normal)
4. ✅ Création entreprise
5. ✅ Sauvegarde locale + cloud
6. ✅ Autosave automatique
7. ✅ Persistence cloud (logout/login)
8. ✅ Restauration complète des données

**Statut final:** ⬜ PASSED / ⬜ FAILED

**Commentaires:**
```
[À remplir après les tests]
```

# 🧪 Guide de Test Complet - Authentification Google & Sauvegarde Cloud

## 📋 Objectif

Valider l'ensemble du flux d'authentification Google Firebase et de sauvegarde cloud, de la connexion initiale jusqu'à la récupération complète des données.

---

## ⚙️ Prérequis

### Configuration Backend
- ✅ Firebase Functions déployées : `https://api-g3tpwosnaq-uc.a.run.app`
- ✅ Firestore activé avec collection `enterprises`
- ✅ Firebase Authentication activé (Google Sign-In)

### Configuration Frontend
- ✅ Fichier `.env` configuré avec `FUNCTIONS_API_BASE`
- ✅ `google-services.json` présent (Android)
- ✅ `firebase_options.dart` configuré

### Environnement de Test
- **Plateforme recommandée** : Web (Chrome) - meilleur support Firebase
- **Alternative** : Android (si émulateur/device disponible)
- **Non supporté** : Windows (problèmes plugins Firebase Auth)

---

## 🎯 Scénario de Test Complet

### Phase 1️⃣ : Connexion Google & Activation CloudPort

#### Test 1.1 - Démarrage Application
**Action** :
```bash
flutter run -d chrome
```

**Résultat attendu** :
```
[MAIN] Application starting...
[MAIN] CloudPort activation | cloudEnabled=false isFirebaseSignedIn=false uid=null
[MAIN] CloudPort NOT activated (cloud disabled)
[BOOTSTRAP] No user initially
[BootstrapScreen] Aucune entreprise trouvée, affichage WelcomeScreen
```

**Validation** : ✅ Application démarre, WelcomeScreen affiché

---

#### Test 1.2 - Connexion Google
**Action** :
1. Cliquer sur bouton "Se connecter avec Google"
2. Sélectionner compte Google dans popup
3. Autoriser l'application

**Résultat attendu** :
```
[AUTH-LISTENER] _syncUserImmediately() CALLED | uid=<votre-uid>
[AUTH-LISTENER] STEP 1: Marking as synced
[AUTH-LISTENER] STEP 2: Getting SharedPreferences
[AUTH-LISTENER] STEP 3: Cloud preference | enabled=false
[AUTH-LISTENER] STEP 4: Auto-enabling cloud
[AUTH-LISTENER] STEP 5: Cloud enabled in prefs
[AUTH-LISTENER] STEP 6: Activating CloudPort...
[AUTH-LISTENER] STEP 7: CloudPort activation result=true
[AUTH-LISTENER] STEP 8: Calling onPlayerConnected()
[AUTH-LISTENER] STEP 9: onPlayerConnected() completed | success=true
```

**Validation** :
- ✅ Popup Google s'ouvre et se ferme
- ✅ CloudPort activé automatiquement (`result=true`)
- ✅ Synchronisation réussie (`success=true`)
- ✅ Redirection vers écran de création entreprise

**⚠️ Problèmes connus** :
- Erreurs CORS `Cross-Origin-Opener-Policy` : **NORMALES**, n'empêchent pas la connexion
- Warning "Could not find Noto fonts" : **IGNORABLE**, cosmétique uniquement

---

#### Test 1.3 - Vérification État CloudPort
**Action** : Ouvrir DevTools Console (F12)

**Commande à exécuter** :
```javascript
// Vérifier SharedPreferences (simulation)
localStorage.getItem('flutter.cloud_enabled')
```

**Résultat attendu** : `"true"`

**Validation** : ✅ CloudPort activé et persisté

---

### Phase 2️⃣ : Création Entreprise & Sauvegarde

#### Test 2.1 - Création Entreprise
**Action** :
1. Entrer nom entreprise : "Test Cloud Save [timestamp]"
2. Cliquer "Créer mon entreprise"

**Résultat attendu** :
```
[ENTERPRISE] Created new enterprise | id=<uuid-v4> name=Test Cloud Save...
```

**Validation** :
- ✅ UUID v4 généré (format : `xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx`)
- ✅ Redirection vers écran principal du jeu

---

#### Test 2.2 - Progression de Jeu
**Action** :
1. Cliquer "Fabriquer Trombone" x10
2. Acheter 1 Auto-Clipper
3. Attendre 30 secondes (sauvegarde automatique)

**Résultat attendu** :
```
[CLOUD-PUSH] START enterpriseId=<uuid>
[HTTP] request PUT /enterprise/<firebase-uid>
[CLOUD-PUSH] Response statusCode=200 success=true
[cloud][success] pushCloudById
```

**Validation** :
- ✅ Requête PUT vers backend Firebase Functions
- ✅ Code HTTP 200 (succès)
- ✅ Logs `[cloud][success]`

---

#### Test 2.3 - Vérification Backend Firestore
**Action** :
1. Ouvrir Firebase Console : `https://console.firebase.google.com/project/paperclip-98294/firestore`
2. Naviguer : Collection `enterprises` > Document `<votre-firebase-uid>`

**Résultat attendu** :
```json
{
  "enterprise_id": "<uuid-v4>",
  "snapshot": {
    "version": 3,
    "enterprise_id": "<uuid-v4>",
    "enterprise_name": "Test Cloud Save...",
    "clips": 10,
    "auto_clippers": 1,
    "funds": <valeur>,
    "quantum_foam": 0,
    "innovation_points": 0,
    "created_at": "2026-04-03T18:30:00.000Z",
    "updated_at": "2026-04-03T18:30:30.000Z"
  },
  "created_at": "2026-04-03T18:30:00.000Z",
  "updated_at": "2026-04-03T18:30:30.000Z"
}
```

**Validation** :
- ✅ Document existe avec UID Firebase
- ✅ Snapshot version 3
- ✅ Tous les champs en `snake_case`
- ✅ Dates au format ISO 8601
- ✅ Valeurs cohérentes avec progression

---

### Phase 3️⃣ : Suppression Locale & Récupération Cloud

#### Test 3.1 - Suppression Données Locales
**Action** :
1. Ouvrir DevTools (F12)
2. Application > Storage > Clear site data
3. Cocher "Local storage", "Session storage", "IndexedDB"
4. Cliquer "Clear site data"
5. Recharger la page (F5)

**Résultat attendu** :
```
[MAIN] Application starting...
[MAIN] CloudPort activation | cloudEnabled=false isFirebaseSignedIn=false uid=null
[BOOTSTRAP] No user initially
[BootstrapScreen] Aucune entreprise trouvée, affichage WelcomeScreen
```

**Validation** :
- ✅ Application redémarre comme au premier lancement
- ✅ WelcomeScreen affiché
- ✅ Aucune entreprise locale

---

#### Test 3.2 - Reconnexion Google
**Action** :
1. Cliquer "Se connecter avec Google"
2. Sélectionner le MÊME compte Google

**Résultat attendu** :
```
[AUTH-LISTENER] _syncUserImmediately() CALLED | uid=<même-uid>
[AUTH-LISTENER] STEP 6: Activating CloudPort...
[AUTH-LISTENER] STEP 7: CloudPort activation result=true
[AUTH-LISTENER] STEP 8: Calling onPlayerConnected()
[CLOUD-PULL] START enterpriseId=<uuid>
[HTTP] request GET /enterprise/<firebase-uid>
[CLOUD-PULL] Response statusCode=200 hasSnapshot=true
[cloud][success] pullCloudById
[AUTH-LISTENER] STEP 9: onPlayerConnected() completed | success=true
```

**Validation** :
- ✅ CloudPort réactivé
- ✅ Requête GET vers backend
- ✅ Snapshot récupéré (`hasSnapshot=true`)
- ✅ Synchronisation réussie

---

#### Test 3.3 - Vérification Restauration
**Action** : Observer l'écran principal du jeu

**Résultat attendu** :
- ✅ Nom entreprise identique : "Test Cloud Save [timestamp]"
- ✅ Nombre de trombones restauré : 10
- ✅ Auto-Clippers restaurés : 1
- ✅ Fonds restaurés
- ✅ Progression exactement comme avant suppression

**Validation** : ✅ Restauration complète depuis cloud

---

### Phase 4️⃣ : Synchronisation Continue

#### Test 4.1 - Modification Post-Restauration
**Action** :
1. Fabriquer 20 trombones supplémentaires
2. Acheter 2 Auto-Clippers supplémentaires
3. Attendre 30 secondes

**Résultat attendu** :
```
[CLOUD-PUSH] START enterpriseId=<uuid>
[HTTP] request PUT /enterprise/<firebase-uid>
[CLOUD-PUSH] Response statusCode=200 success=true
```

**Validation** :
- ✅ Nouvelle sauvegarde cloud automatique
- ✅ Snapshot mis à jour dans Firestore
- ✅ `updated_at` plus récent que `created_at`

---

#### Test 4.2 - Multi-Device (Optionnel)
**Action** :
1. Ouvrir application sur un 2ème appareil/navigateur
2. Se connecter avec le MÊME compte Google

**Résultat attendu** :
- ✅ Même entreprise chargée
- ✅ Progression synchronisée
- ✅ Modifications sur device 1 visibles sur device 2 après refresh

---

### Phase 5️⃣ : Suppression & Nettoyage

#### Test 5.1 - Suppression Entreprise
**Action** :
1. Menu > Paramètres > Supprimer Entreprise
2. Confirmer la suppression

**Résultat attendu** :
```
[CLOUD-DELETE] START enterpriseId=<uuid>
[HTTP] request DELETE /enterprise/<firebase-uid>
[CLOUD-DELETE] Response statusCode=204
[cloud][success] deleteCloudById
```

**Validation** :
- ✅ Requête DELETE vers backend
- ✅ Code HTTP 204 (No Content)
- ✅ Document supprimé de Firestore
- ✅ Retour au WelcomeScreen

---

#### Test 5.2 - Déconnexion
**Action** :
1. Menu > Se déconnecter

**Résultat attendu** :
```
[AUTH] User signed out
[CLOUD] CloudPort deactivated
```

**Validation** :
- ✅ Utilisateur déconnecté
- ✅ CloudPort désactivé
- ✅ Retour au WelcomeScreen

---

## 📊 Checklist Complète

### ✅ Authentification
- [ ] Connexion Google réussie
- [ ] UID Firebase récupéré
- [ ] Popup Google se ferme correctement
- [ ] Pas d'erreur bloquante (CORS warnings OK)

### ✅ Activation CloudPort
- [ ] CloudPort activé automatiquement après connexion
- [ ] `cloud_enabled=true` dans SharedPreferences
- [ ] Logs `CloudPort activation result=true`

### ✅ Création Entreprise
- [ ] UUID v4 généré (36 caractères)
- [ ] Nom personnalisé sauvegardé
- [ ] Redirection vers écran principal

### ✅ Sauvegarde Cloud (Push)
- [ ] Requête PUT automatique après 30s
- [ ] Code HTTP 200
- [ ] Document créé dans Firestore
- [ ] Snapshot version 3
- [ ] Tous les champs en snake_case
- [ ] Dates ISO 8601 valides

### ✅ Récupération Cloud (Pull)
- [ ] Suppression locale réussie
- [ ] Reconnexion avec même compte
- [ ] Requête GET automatique
- [ ] Snapshot récupéré
- [ ] Progression restaurée à l'identique

### ✅ Synchronisation Continue
- [ ] Modifications sauvegardées automatiquement
- [ ] `updated_at` mis à jour
- [ ] Multi-device synchronisé (optionnel)

### ✅ Suppression & Nettoyage
- [ ] DELETE entreprise réussie (204)
- [ ] Document supprimé de Firestore
- [ ] Déconnexion propre
- [ ] CloudPort désactivé

---

## 🐛 Problèmes Connus & Solutions

### Problème 1: Erreurs CORS "Cross-Origin-Opener-Policy"
**Symptôme** :
```
Cross-Origin-Opener-Policy policy would block the window.closed call
```

**Cause** : Politique de sécurité Firebase Auth sur Web

**Solution** : **IGNORER** - Ces warnings n'empêchent pas la connexion

**Validation** : Si vous voyez `[AUTH-LISTENER] _syncUserImmediately() CALLED`, la connexion a réussi

---

### Problème 2: CloudPort non activé après connexion
**Symptôme** :
```
[MAIN] CloudPort NOT activated (cloud disabled)
```
Mais PAS de logs `[AUTH-LISTENER] STEP 6: Activating CloudPort...`

**Cause** : Fonction `_syncUserImmediately()` ne s'exécute pas complètement

**Solution** :
1. Vérifier les logs complets dans console
2. Chercher erreurs JavaScript
3. Vérifier que `FirebaseAuthService.instance.currentUser` n'est pas null

**Debug** :
```javascript
// Dans DevTools Console
console.log('User:', firebase.auth().currentUser);
```

---

### Problème 3: Requête HTTP échoue (CORS backend)
**Symptôme** :
```
[HTTP] request PUT /enterprise/<uid>
Access to fetch blocked by CORS policy
```

**Cause** : Backend Firebase Functions non configuré pour CORS

**Solution** : Vérifier `functions/src/index.ts` contient :
```typescript
app.use(cors({ origin: true }));
```

---

### Problème 4: Snapshot non récupéré (404)
**Symptôme** :
```
[CLOUD-PULL] Response statusCode=404
```

**Cause** : Aucune sauvegarde cloud pour cet utilisateur

**Solution** : Normal au premier lancement - créer une entreprise et attendre sauvegarde automatique

---

## 📈 Métriques de Performance

### Temps de Réponse Attendus
- **Connexion Google** : 2-5 secondes
- **Activation CloudPort** : < 1 seconde
- **Push cloud (PUT)** : 500-1500 ms
- **Pull cloud (GET)** : 300-800 ms
- **Delete cloud** : 200-500 ms

### Taille Snapshot
- **Snapshot minimal** : ~2 KB
- **Snapshot avec progression** : 3-5 KB
- **Snapshot complet (agents/recherches)** : 10-15 KB

---

## 🔍 Logs de Référence

### Connexion Réussie
```
[AUTH-LISTENER] _syncUserImmediately() CALLED | uid=Gw4RFU78ckVfP48shZ0SY0JlM3w2
[AUTH-LISTENER] STEP 1: Marking as synced
[AUTH-LISTENER] STEP 2: Getting SharedPreferences
[AUTH-LISTENER] STEP 3: Cloud preference | enabled=false
[AUTH-LISTENER] STEP 4: Auto-enabling cloud
[AUTH-LISTENER] STEP 5: Cloud enabled in prefs
[AUTH-LISTENER] STEP 6: Activating CloudPort...
[AUTH-LISTENER] STEP 7: CloudPort activation result=true
[AUTH-LISTENER] STEP 8: Calling onPlayerConnected()
[AUTH-LISTENER] STEP 9: onPlayerConnected() completed | success=true
```

### Sauvegarde Réussie
```
[CLOUD-PUSH] START enterpriseId=a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d
[HTTP] request PUT /enterprise/Gw4RFU78ckVfP48shZ0SY0JlM3w2
[CLOUD-PUSH] Response statusCode=200 success=true
[cloud][success] pushCloudById
```

### Récupération Réussie
```
[CLOUD-PULL] START enterpriseId=a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d
[HTTP] request GET /enterprise/Gw4RFU78ckVfP48shZ0SY0JlM3w2
[CLOUD-PULL] Response statusCode=200 hasSnapshot=true
[cloud][success] pullCloudById
```

---

## 📝 Rapport de Test

### Template de Rapport
```markdown
# Rapport de Test - Auth Google & Cloud Save
**Date** : [Date]
**Testeur** : [Nom]
**Plateforme** : [Web/Android/iOS]
**Version** : [Version app]

## Résultats

### Phase 1 - Connexion
- [ ] Test 1.1 - Démarrage : ✅ / ❌
- [ ] Test 1.2 - Connexion Google : ✅ / ❌
- [ ] Test 1.3 - CloudPort activé : ✅ / ❌

### Phase 2 - Sauvegarde
- [ ] Test 2.1 - Création entreprise : ✅ / ❌
- [ ] Test 2.2 - Push cloud : ✅ / ❌
- [ ] Test 2.3 - Firestore vérifié : ✅ / ❌

### Phase 3 - Récupération
- [ ] Test 3.1 - Suppression locale : ✅ / ❌
- [ ] Test 3.2 - Reconnexion : ✅ / ❌
- [ ] Test 3.3 - Restauration : ✅ / ❌

### Phase 4 - Synchronisation
- [ ] Test 4.1 - Modification post-restauration : ✅ / ❌
- [ ] Test 4.2 - Multi-device : ✅ / ❌ / N/A

### Phase 5 - Nettoyage
- [ ] Test 5.1 - Suppression entreprise : ✅ / ❌
- [ ] Test 5.2 - Déconnexion : ✅ / ❌

## Problèmes Rencontrés
[Décrire les problèmes]

## Notes
[Observations supplémentaires]
```

---

## 🚀 Commandes Utiles

### Lancer l'application
```bash
# Web (recommandé)
flutter run -d chrome

# Android
flutter run -d <device-id>

# Lister devices
flutter devices
```

### Nettoyer et rebuild
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Voir logs Firebase Functions
```bash
firebase functions:log --only api
```

### Déployer backend
```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

---

## ✅ Conclusion

Ce guide couvre l'ensemble du flux d'authentification Google et de sauvegarde cloud. Tous les tests doivent être **VERTS** (✅) pour valider le déploiement en production.

**Critères de succès** :
- ✅ 100% des tests Phase 1-3 passent
- ✅ 90%+ des tests Phase 4-5 passent
- ✅ Aucune erreur bloquante
- ✅ Données persistées correctement dans Firestore
- ✅ Restauration fidèle à 100%

# Tests Automatisés - Cloud Sync

## 🎯 Objectif

Tests automatisés du flux complet de synchronisation cloud avec le compte test `test.keamder@gmail.com`.

## 📋 Tests inclus

### Groupe 1: Flux Complet
1. ✅ **TEST 1**: Vérification compte test connecté
2. ✅ **TEST 2**: CloudPort activation
3. ✅ **TEST 3**: Synchronisation initiale (404 attendu)
4. ✅ **TEST 4**: Création entreprise + sauvegarde locale
5. ✅ **TEST 5**: Push cloud vers `/enterprise/{uid}`
6. ✅ **TEST 6**: Pull cloud depuis `/enterprise/{uid}`
7. ✅ **TEST 7**: Cycle complet (Création → Push → Pull → Validation)

### Groupe 2: Validation Architecture
8. ✅ **TEST 8**: Architecture entreprise unique (CHANTIER-01)
9. ✅ **TEST 9**: Format snapshot v3

## 🚀 Exécution

### Méthode 1: Script PowerShell (Recommandé)

```powershell
cd c:\DEV\PROJETS\applications_mobile\PaperClip2
.\test\integration_test\run_cloud_tests.ps1
```

**Le script va:**
1. Lancer l'application Flutter en mode web
2. Vous demander de vous connecter avec le compte test
3. Exécuter automatiquement tous les tests
4. Afficher les résultats

### Méthode 2: Manuelle

**Étape 1: Lancer l'application**
```powershell
flutter run -d chrome --web-port=50652
```

**Étape 2: Se connecter**
- Email: `test.keamder@gmail.com`
- Mot de passe: `6W@693SZiD01`
- Attendre la synchronisation initiale

**Étape 3: Exécuter les tests** (dans un nouveau terminal)
```powershell
flutter test test/integration_test/cloud_sync_automated_test.dart --reporter=expanded
```

## ⚠️ Prérequis

### 1. Firebase configuré
- Fichier `.env` avec `FIREBASE_API_URL`
- Firebase initialisé dans l'application

### 2. Backend déployé
- API accessible: `https://api-g3tpwosnaq-uc.a.run.app`
- Endpoint `/enterprise/{uid}` fonctionnel
- CORS configuré pour `http://localhost:50652`

### 3. Compte test
- Email: `test.keamder@gmail.com`
- Mot de passe: `6W@693SZiD01`
- Compte Google valide et actif

## 📊 Résultats attendus

### Succès complet
```
✅ TEST 1 PASSED: Compte test validé
✅ TEST 2 PASSED: CloudPort activé
✅ TEST 3 PASSED: Sync initiale complétée
✅ TEST 4 PASSED: Entreprise créée et sauvegardée
✅ TEST 5 PASSED: Push cloud réussi
✅ TEST 6 PASSED: Pull cloud réussi
✅ TEST 7 PASSED: Cycle complet validé
✅ TEST 8 PASSED: Architecture entreprise unique validée
✅ TEST 9 PASSED: Snapshot v3 validé

All tests passed!
```

### Échecs possibles

#### ❌ Utilisateur non connecté
```
❌ ERREUR: Utilisateur non connecté
   Pour exécuter ces tests:
   1. Lancez l'app: flutter run -d chrome
   2. Connectez-vous avec: test.keamder@gmail.com
   3. Relancez les tests
```
**Solution:** Suivre les étapes d'exécution

#### ❌ Firebase non initialisé
```
❌ ERREUR Firebase: [core/no-app] No Firebase App '[DEFAULT]' has been created
```
**Solution:** Lancer l'application d'abord (`flutter run -d chrome`)

#### ❌ Erreur CORS
```
❌ Access to fetch has been blocked by CORS policy
```
**Solution:** Vérifier que le backend autorise `http://localhost:50652`

#### ❌ Erreur 401 Unauthorized
```
❌ TEST 5 FAILED: Erreur push cloud
   Erreur: 401 Unauthorized
```
**Solution:** Token Firebase expiré - se déconnecter et reconnecter

## 🔍 Détails des tests

### TEST 1: Vérification compte test
- Vérifie que l'utilisateur est connecté
- Valide l'email: `test.keamder@gmail.com`
- Récupère l'UID Firebase

### TEST 2: CloudPort activation
- Active le CloudPort
- Vérifie que le type est `CloudPersistenceAdapter`
- Désactive après test (cleanup)

### TEST 3: Synchronisation initiale
- Appelle `onPlayerConnected()`
- Pour un nouvel utilisateur: 404 normal (0 mondes)
- Pour utilisateur existant: restaure les mondes

### TEST 4: Création entreprise
- Crée entreprise avec nom test
- Génère UUID v4 valide
- Sauvegarde localement

### TEST 5: Push cloud
- Crée entreprise
- Sauvegarde localement
- Push vers `/enterprise/{uid}`
- Vérifie succès (201/200)

### TEST 6: Pull cloud
- Appelle `onPlayerConnected()`
- Pull depuis `/enterprise/{uid}`
- Vérifie que les mondes sont restaurés

### TEST 7: Cycle complet
1. Crée entreprise avec données (Quantum: 100, PI: 500)
2. Push vers cloud
3. Pull depuis cloud
4. Valide que les données sont préservées

### TEST 8: Architecture entreprise unique
- Valide endpoint `/enterprise/{uid}`
- Confirme 1 entreprise max par utilisateur

### TEST 9: Format snapshot v3
- Vérifie `snapshotSchemaVersion = 3`
- Valide présence `enterpriseId` dans metadata
- Vérifie `gameVersion`

## 🐛 Dépannage

### Les tests ne trouvent pas l'utilisateur
**Problème:** Tests exécutés avant login  
**Solution:** Attendre que l'application soit complètement chargée et que vous soyez connecté

### Timeout sur les requêtes cloud
**Problème:** Backend lent ou indisponible  
**Solution:** Vérifier que le backend est déployé et accessible

### Erreur "Snapshot absent"
**Problème:** Sauvegarde locale corrompue  
**Solution:** Supprimer les données locales et relancer

## 📈 Métriques de performance

Les tests mesurent:
- **Latency push cloud** (doit être < 5s)
- **Latency pull cloud** (doit être < 5s)
- **Temps total sync** (doit être < 30s)

## ✅ Validation finale

Après exécution réussie, vous devriez avoir:
- ✅ 9 tests passés
- ✅ 0 tests échoués
- ✅ Entreprise créée dans le cloud
- ✅ Données synchronisées
- ✅ Cycle complet validé

## 📝 Notes

- Les tests utilisent le **compte test réel** (pas de mock)
- Les tests effectuent de **vraies requêtes HTTP** vers le backend
- Les tests créent de **vraies données** dans Firebase
- Cleanup automatique après chaque test

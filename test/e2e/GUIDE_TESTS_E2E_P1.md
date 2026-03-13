# Guide Tests E2E - Phase 1 (Corrections P1)

## Objectif
Valider les corrections P1 (dégradation UX) avec des tests end-to-end reproductibles.

---

## Test E2E-P1-1: Réconciliation Automatique au Bootstrap

### Scénario
Vérifier que les mondes pending sont automatiquement réconciliés au login.

### Prérequis
- Application installée sur device
- Utilisateur déconnecté

### Étapes
1. **Créer monde hors-ligne**
   - Lancer app sans connexion
   - Créer nouveau monde "Monde Offline"
   - Vérifier notification "💾 Monde sauvegardé localement"
   - Fermer app

2. **Se connecter**
   - Activer connexion internet
   - Lancer app
   - Se connecter avec Google
   - **ATTENDRE** bootstrap complet

3. **Vérifier réconciliation**
   - Vérifier notification "✅ 1 monde(s) synchronisé(s) avec le cloud"
   - Ouvrir WorldsScreen
   - Vérifier "Monde Offline" présent avec icône cloud

### Résultat Attendu
✅ Monde créé hors-ligne automatiquement synchronisé au login  
✅ Notification utilisateur affichée  
✅ Aucune erreur dans logs

### Logs à Vérifier
```
[RETRY] Succès pour <partieId>
[RETRY] Terminé: 1 succès, 0 échecs, 0 expirés, 0 limites atteintes
```

---

## Test E2E-P1-2: Limite 3 Tentatives Retry

### Scénario
Vérifier que les mondes pending sont abandonnés après 3 tentatives échouées.

### Prérequis
- Backend inaccessible (simuler erreur 500)
- Monde pending existant

### Étapes
1. **Créer monde pending**
   - Créer monde hors-ligne
   - Vérifier flag `pending_identity_<partieId>` dans SharedPreferences

2. **Tenter sync avec backend down**
   - Se connecter (backend retourne 500)
   - Vérifier compteur retry incrémenté
   - Répéter 2 fois (total 3 tentatives)

3. **Vérifier abandon**
   - 4ème tentative: vérifier notification "⚠️ X monde(s) non synchronisé(s) (limite retry atteinte)"
   - Vérifier flag `pending_identity_<partieId>` supprimé

### Résultat Attendu
✅ Max 3 tentatives effectuées  
✅ Flag pending supprimé après 3 échecs  
✅ Notification utilisateur affichée

---

## Test E2E-P1-3: Limite 10 Mondes - Création UI

### Scénario
Vérifier que l'utilisateur ne peut pas créer plus de 10 mondes via UI.

### Prérequis
- Utilisateur connecté
- 10 mondes déjà créés

### Étapes
1. **Créer 10 mondes**
   - Créer 10 mondes via UI
   - Vérifier tous synchronisés

2. **Tenter créer 11ème monde**
   - Cliquer FAB "+"
   - **VÉRIFIER** SnackBar affiché:
     ```
     Limite de 10 mondes atteinte. 
     Supprimez un monde existant pour en créer un nouveau.
     ```

3. **Vérifier dialogue non ouvert**
   - NewGameDialog ne doit PAS s'ouvrir
   - Compteur mondes reste à 10

### Résultat Attendu
✅ SnackBar affiché  
✅ Dialogue création bloqué  
✅ Aucune requête HTTP envoyée

---

## Test E2E-P1-4: Limite 10 Mondes - Push Cloud

### Scénario
Vérifier que le push cloud est bloqué si limite atteinte.

### Prérequis
- Utilisateur connecté
- 10 mondes dans cloud
- 1 monde local non synchronisé

### Étapes
1. **Créer 10 mondes cloud**
   - Via autre device ou directement dans Firestore
   - Vérifier `listParties()` retourne 10 mondes

2. **Créer monde local**
   - Créer monde hors-ligne sur device test
   - Vérifier sauvegarde locale OK

3. **Tenter sync**
   - Se connecter
   - Vérifier notification:
     ```
     ⚠️ Limite de 10 mondes atteinte
     Supprimez un monde existant pour en créer un nouveau
     ```

4. **Vérifier état**
   - Monde reste local uniquement
   - Aucune requête PUT /worlds envoyée
   - Log: `[cloud][error] Limite de 10 mondes atteinte`

### Résultat Attendu
✅ Push cloud bloqué  
✅ Notification utilisateur affichée  
✅ Monde reste local (pas d'erreur 400 backend)

---

## Test E2E-P1-5: Détection Conflit Multi-Device

### Scénario
Vérifier qu'un conflit multi-device est détecté et notifié.

### Prérequis
- Utilisateur connecté sur 2 devices (A et B)
- Monde "Test Conflit" synchronisé

### Étapes
1. **Modifier sur Device A**
   - Ouvrir "Test Conflit" sur Device A
   - Jouer 10 minutes
   - Sauvegarder (auto-save)
   - Vérifier sync cloud OK

2. **Modifier sur Device B (hors-ligne)**
   - Mettre Device B hors-ligne
   - Ouvrir "Test Conflit" sur Device B
   - Jouer 10 minutes
   - Sauvegarder localement
   - Timestamp local > 5 min après cloud

3. **Reconnecter Device B**
   - Activer connexion sur Device B
   - Lancer app
   - **ATTENDRE** sync automatique

4. **Vérifier détection conflit**
   - Notification affichée:
     ```
     ⚠️ Conflit détecté: "Test Conflit"
     Version cloud plus récente appliquée
     ```
   - Log: `[SYNC-LOGIN] Conflit détecté multi-device`
   - Version cloud appliquée (cloud wins)

### Résultat Attendu
✅ Conflit détecté (diff > 5 min)  
✅ Notification utilisateur affichée  
✅ Version cloud appliquée  
✅ Logs détaillés avec timestamps

---

## Test E2E-P1-6: Pas de Conflit si Diff < 5 Minutes

### Scénario
Vérifier qu'aucune notification n'est affichée si diff < 5 minutes.

### Prérequis
- Même setup que E2E-P1-5

### Étapes
1. **Modifier sur Device A**
   - Sauvegarder sur Device A

2. **Modifier sur Device B rapidement**
   - Dans les 3 minutes suivantes
   - Modifier sur Device B
   - Reconnecter

3. **Vérifier pas de notification conflit**
   - Aucune notification "Conflit détecté"
   - Cloud wins appliqué silencieusement
   - Log: `[SYNC-LOGIN] Cloud importé (cloud wins)`

### Résultat Attendu
✅ Pas de notification conflit  
✅ Cloud wins appliqué  
✅ UX fluide (pas de bruit inutile)

---

## Checklist Validation Complète

### Réconciliation
- [ ] E2E-P1-1: Réconciliation automatique au bootstrap
- [ ] E2E-P1-2: Limite 3 tentatives retry

### Limite Mondes
- [ ] E2E-P1-3: Limite 10 mondes - Création UI
- [ ] E2E-P1-4: Limite 10 mondes - Push cloud

### Conflits Multi-Device
- [ ] E2E-P1-5: Détection conflit (diff > 5 min)
- [ ] E2E-P1-6: Pas de conflit (diff < 5 min)

---

## Commandes Utiles

### Vérifier SharedPreferences (Android)
```bash
adb shell run-as com.kinder2149.paperclip2 cat /data/data/com.kinder2149.paperclip2/shared_prefs/FlutterSharedPreferences.xml | grep pending_identity
```

### Vérifier Logs
```bash
adb logcat | grep -E "RETRY|SYNC-LOGIN|cloud_max_worlds|sync_conflict"
```

### Simuler Backend Down
Modifier `.env`:
```
FUNCTIONS_API_BASE=http://localhost:9999
```

### Compter Mondes Cloud
```dart
final entries = await CloudPersistenceAdapter().listParties();
print('Mondes cloud: ${entries.length}');
```

---

## Notes Importantes

1. **TTL 7 jours**: Flags pending expirés automatiquement après 7 jours
2. **Cloud wins**: Principe cloud-first, version cloud toujours prioritaire
3. **Seuil conflit**: 5 minutes choisi pour équilibre UX/détection
4. **Notifications**: Durée 5-7 secondes pour laisser temps de lecture

---

## Prochaines Étapes

Après validation de tous les tests E2E-P1:
1. Implémenter tests automatisés (integration_test/)
2. Passer aux corrections P2 (qualité code)
3. Mettre à jour SYSTEM_INVARIANTS.md

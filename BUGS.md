# BUGS — PaperClip2

> Format : `[date découverte] | [description] | [statut] | [fichier concerné]`

---

| Date | Description | Statut | Fichier |
|---|---|---|---|
| 2026-04-10 | 30 occurrences de `worldId` dans les logs (cosmétique, pas de bug runtime) | ✅ Résolu | `lib/services/persistence/game_persistence_orchestrator.dart` |
| 2026-04-10 | Google Sign-In Android : `clientConfigurationError — serverClientId must be provided, null` | ✅ Résolu (code) | `lib/services/auth/firebase_auth_service.dart` |
| 2026-04-10 | Google Sign-In Android : `[16] Account reauth failed` après fix code | ⏳ En attente config | `android/app/google-services.json` + Firebase Console |

---

## Analyse détaillée — Bug Google Sign-In Android (AUTH-ANDROID-FIX)

### Cause racine 1 — Code (✅ Résolu)
`google_sign_in v7.2.0` a changé son API :
- Plus de constructeur `GoogleSignIn(serverClientId: ...)` → utiliser `GoogleSignIn.instance`
- `serverClientId` doit être passé via `GoogleSignIn.instance.initialize(serverClientId: '...')`
- `signIn()` → `authenticate()` / `signInSilently()` → `attemptLightweightAuthentication()`

**Fix appliqué :** `firebase_auth_service.dart` — méthode `_ensureGoogleSignInInitialized()` avec `serverClientId` explicite.

### Cause racine 2 — Configuration Firebase (⏳ action manuelle requise)
Le SHA-1 du debug keystore de la machine de développement actuelle n'est pas enregistré dans Firebase Console.

**SHA-1s enregistrés dans Firebase :**
| SHA-1 | Type |
|---|---|
| `12:25:16:7B:BD:67:3B:CE:4B:C0:C8:11:1B:A5:03:CC:99:E1:AD:E4` | Clé de signature Google Play (production) |
| `EE:FE:16:FD:72:08:38:24:06:EE:67:DA:67:05:94:79:5B:1D:9D:CB` | Clé d'importation (upload key) |
| `94:95:FD:94:32:6F:9D:6C:1A:64:99:91:9E:41:47:7C:FB:84:F7:54` | Debug keystore (autre machine) |

**SHA-1 manquant (machine actuelle) :**
`2B:CB:36:78:FD:AA:D5:8D:C1:16:01:53:36:49:9C:E7:E7:D0:AA:77`

**Fix requis :**
1. Firebase Console → Paramètres du projet → PaperClip Android → Ajouter une empreinte
2. Ajouter `2B:CB:36:78:FD:AA:D5:8D:C1:16:01:53:36:49:9C:E7:E7:D0:AA:77` (SHA-1)
3. Télécharger le nouveau `google-services.json` → remplacer `android/app/google-services.json`
4. `flutter build apk --debug` → tester sur appareil Android

### Note pour les prochaines machines de dev
Chaque nouveau poste de développement a son propre debug keystore avec un SHA-1 unique.
Il faut systématiquement l'ajouter dans Firebase Console avant de tester le Sign-In Google sur Android.


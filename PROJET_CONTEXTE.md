# PROJET_CONTEXTE — PaperClip2

> Emplacement : racine du projet
> Source de vérité absolue — lire EN ENTIER avant toute action.
> Toute décision technique qui contredit ce fichier est interdite.
> Dernière mise à jour : 2026-08-06

---

## 1. IDENTITÉ DU PROJET

| Champ | Valeur |
|---|---|
| Nom | PaperClip2 |
| Type | Application mobile (Flutter / Android) |
| Objectif en 1 phrase | Jeu de gestion incrémental (idle game) où le joueur produit et vend des trombones pour développer son empire industriel, avec sauvegarde cloud multi-appareils |
| Statut | En développement — core gameplay stable, cloud stable |
| Utilisateurs actuels | Tests internes (1 compte de test) |
| Dernière mise à jour | 2026-08-06 |

---

## 2. STACK TECHNIQUE

**Frontend :**
- Framework : Flutter 3.x
- Langage : Dart
- Composants UI : Material Design (widgets Flutter natifs)
- Gestion de l'affichage dynamique : Provider (ChangeNotifier)

**Backend :**
- Framework : Express 4.x (Node.js 20)
- Langage : TypeScript
- Hébergement : Firebase Functions v2
- Port local : Firebase Emulators (8080 Firestore, 5001 Functions)

**Base de données :**
- Technologie : Cloud Firestore
- Collection principale : `enterprises/{uid}` (une entrée par utilisateur Firebase)
- Lancement en local : `firebase emulators:start` dans /functions

**Services externes :**
- Comptes utilisateurs : Firebase Auth (Google Sign-In)
- Sauvegarde cloud : Cloud Firestore via Firebase Functions REST API
- Stockage local : SharedPreferences (Flutter)
- Mise en ligne : Google Play Store (APK/AAB)

---

## 3. ARCHITECTURE

```
PaperClip2/
├── lib/
│   ├── screens/           # UI : bootstrap, welcome, main, profile
│   ├── models/            # GameState, SaveMetadata, ResetHistory
│   ├── services/
│   │   ├── auth/          # FirebaseAuthService (Google Sign-In)
│   │   ├── persistence/   # GamePersistenceOrchestrator, SyncResult
│   │   ├── cloud/         # CloudPortManager, CloudPersistencePort
│   │   ├── save_system/   # LocalSaveGameManager
│   │   ├── runtime/       # RuntimeActions (façade UI → RuntimeCoordinator)
│   │   └── google/        # GoogleBootstrap, Achievements, Leaderboards
│   ├── controllers/       # GameSessionController
│   ├── widgets/           # SyncStatusChip, SaveButton
│   └── main.dart
├── functions/             # Backend Firebase Functions (TypeScript)
│   └── src/index.ts       # GET/PUT/DELETE /enterprise/:uid
├── test/
│   └── persistence/       # Tests HTTP multi-appareils (5/5 ✅)
└── PROJET_CONTEXTE.md     # Ce fichier
```

**Nombre de services actifs :** ~15 / 20 maximum

**Flux principal :**
```
Démarrage → BootstrapScreen → AppBootstrapController
  → Firebase Auth check → sync cloud (onPlayerConnected)
  → si entreprise locale : LoadGameById → MainScreen
  → si aucune entreprise  : WelcomeScreen (Créer ou Reprendre)
```

---

## 4. FONCTIONNALITÉS

### ✅ Stables (ne pas toucher sans raison)

- Gameplay core : production manuelle/auto de trombones, marché, upgrades, niveaux
- Sauvegarde locale (SharedPreferences) avec système de backup automatique
- Sauvegarde cloud Firebase (push/pull) via Cloud Functions
- Authentification Google (Firebase Auth + google_sign_in v7)
- Sync multi-appareils au login (onPlayerConnected)
- Navigation dynamique WelcomeScreen : bouton "Reprendre" si entreprise existante
- Navigation post-reconnexion automatique vers MainScreen (loadGameByIdAndStartAutoSave)
- ProfileScreen : affichage stats, déconnexion (avec reset GameState), suppression entreprise (local + cloud + compte Firebase)
- Tests de persistance multi-appareils (test/persistence/) : 5/5 ✅

### 🚧 En cours / À améliorer

- Notifications utilisateur après sync : correction partielle (false errors supprimées)
- Google Play Games (achievements, leaderboards) : câblé mais pas testé en production

### ❌ Bugs connus

- Aucun bug bloquant connu à ce jour
- Si `requires-recent-login` lors de la suppression du compte Firebase : message informatif affiché, suppression manuelle via Firebase Console requise

### 🔒 Hors scope (ne jamais implémenter sans décision explicite)

- Multi-entreprises par compte (architecture entreprise unique décidée)
- Supabase (remplacé par Firebase)
- Système de monde / WorldsScreen (remplacé par entreprise unique)
- Backend HTTP dédié autre que Firebase Functions
- iOS / Web (Android uniquement pour l'instant)

---

## 5. RÈGLES STRICTES DU PROJET

- GRAPHIFY ACTIF : Lire graphify-out/GRAPH_REPORT.md en début de chaque session.
  Si absent → le regénérer avant tout autre travail (graphify claude install + graphify .)
- Ne modifier QUE les fichiers concernés par la mission en cours
- Ne créer aucun nouveau fichier sans le lister ici après création
- Ne pas ajouter de dépendance sans demande explicite
- Modifier l'existant avant d'en créer du nouveau
- Zéro structure vide créée "pour le futur"
- L'identité utilisateur = Firebase UID (source de vérité unique)
- Le GameState doit TOUJOURS être réinitialisé (deleteEnterprise) avant toute déconnexion

---

## 6. DÉCISIONS FIGÉES

| Date | Décision | Raison |
|---|---|---|
| 2026-04-14 | graphify initialisé | Réduction tokens, carte persistante entre sessions |
| 2026-01 | Entreprise unique par compte (pas multi-monde) | Simplification architecture, UX plus claire |
| 2026-01 | Firebase UID = identité canonique (pas Google Play ID) | Firebase Auth est la source de vérité |
| 2026-01 | google_sign_in v7 : GoogleSignIn.instance.initialize(serverClientId) | Constructeur privé depuis v7 |
| 2026-01 | Snapshot v3 format avec dates ISO à 3 décimales | Compatibilité backend JS Date.toISOString() |
| 2026-01 | Tests de persistance = HTTP pur (pas SDK Flutter) | Fonctionne en VM Dart sans platform channels |
| 2026-04 | loadGameByIdAndStartAutoSave(id) vs loadEnterpriseAndStartAutoSave() | Évite le deadlock enterpriseId==null |
| 2026-08-06 | Imports internes en style absolu (`package:paperclip2/...`) | Convention Dart/Flutter officielle, cohérence du projet (52 fichiers absolus vs 96 relatifs avant uniformisation) |
| 2026-08-06 | Interrupteurs Sons et Notifications retirés du panel Paramètres | Aucun service réel activable derrière (`playSfx()` stub no-op, `NotificationManager` sans notion ON/OFF) — à réintroduire si ces services sont construits un jour |

---

## 7. FICHIERS DE DOCUMENTATION AUTORISÉS

| Fichier | Rôle |
|---|---|
| PROJET_CONTEXTE.md | Source de vérité (ce fichier) |
| README.md | Guide démarrage rapide |
| METHODO/STACK_STANDARD.md | Stack de référence globale |
| docs/01-architecture/architecture-globale.md | Architecture technique détaillée |
| docs/02-guides-developpeur/api-backend.md | API Cloud Functions |

Tout autre fichier .md → archive/.

---





## 8. SESSION EN COURS

Graphify : ✅ COMPLÉTÉ (à rafraîchir — imports modifiés depuis la dernière génération)
Objectif de la session : 3 corrections préparées via Brain (chaîne "bug") et exécutées par Claude Code — README.md fantôme, incohérence de style d'imports, interrupteurs settings_panel.dart non câblés.
Fichiers concernés : lib/models/README.md, 48 fichiers lib/ (imports game_config.dart/game_state.dart), lib/screens/panels/settings_panel.dart
Hors scope cette session : services Sons/Notifications (inexistants, non construits), fichiers dupliqués constants/game_config.dart et game_state.dart à la racine (hors lib/, morts, signalés mais non traités)
Résultat fin de session : 3 missions closes et validées (flutter analyze sans régression, test manuel de l'interrupteur Musique validé par Kinder).
Graphe mis à jour : non — à relancer (graphify claude install / graphify .) avant la prochaine analyse d'architecture

## 9. BACKLOG (missions suivantes)

1. Google Play Games achievements/leaderboards — tester en production
2. Build release (APK signé) — préparation Google Play Store
3. Onboarding utilisateur — tutoriel première utilisation
4. Rafraîchir `graphify-out/` (`graphify .`) — le graphe actuel date du 2026-08-05, avant l'uniformisation des imports du 2026-08-06 ; ses "God Nodes" montrent encore `../../constants/game_config.dart` (32 edges) et `package:paperclip2/constants/game_config.dart` (16 edges) comme deux nœuds séparés, résidu de l'ancien mélange relatif/absolu.
5. Traiter ou supprimer les fichiers morts hors `lib/` signalés en session du 2026-08-06 : `constants/game_config.dart` et `game_state.dart` dupliqués à la racine du projet (hors scope de cette session-là, jamais rouverts depuis).

## 10. AUDIT DE REPRISE (2026-08-06)
**Constat :** ce fichier et `CHANGELOG.md` viennent d'être mis à jour aujourd'hui (session close, validée par Kinder). `graphify-out/GRAPH_REPORT.md` existe (234 fichiers, 2257 nœuds, 81 communautés) mais date de la veille (2026-08-05) — cohérent avec la note « Graphe mis à jour : non » en section 8. Aucun écart supplémentaire trouvé entre la doc et l'état du code lors de cet audit ; le projet est le mieux tenu du périmètre audité jusqu'ici (méthode déjà respectée : graphify actif, backlog priorisé, décisions figées à jour).
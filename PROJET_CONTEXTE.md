# PROJET_CONTEXTE — PaperClip2

> Emplacement : racine du projet
> Template source : METHODO/PROJET_CONTEXTE_TEMPLATE.md
>
> ⚠️ INSTRUCTION POUR L'IA (Claude et Cascade)
> Ce fichier est la source de vérité absolue du projet.
> Le lire EN ENTIER avant toute action.
> Toute décision technique qui le contredit est interdite.
> Si une demande sort de ce cadre : poser UNE question avant d'agir.

---

## 1. IDENTITÉ DU PROJET

| Champ | Valeur |
|---|---|
| Nom | PaperClip2 |
| Type | Mobile |
| Objectif en 1 phrase | Jeu idle incrémental : gérer et vendre des trombones, progresser par resets avec méta-progression |
| Statut | En développement (ancienne version sur Play Store, sans utilisateurs actifs) |
| Utilisateurs actuels | 0 actifs |
| Dernière mise à jour de ce fichier | 2026-04-10 |

---

## 2. STACK TECHNIQUE

> Tout ce qui n'est pas listé ici ne doit pas être utilisé sans validation.

**Frontend :**
- Framework : Flutter 3.x
- Langage : Dart 3.8+
- Composants UI : fl_chart (graphiques), just_audio (audio jeu), games_services (Google Play Games)
- Gestion de l'affichage dynamique : Provider ^6.1.1

**Backend :**
- Framework : Express.js sur Firebase Functions v2
- Langage : TypeScript (Node.js 20)
- Endpoint principal : `/enterprise/{uid}` (GET, PUT, DELETE)

**Base de données :**
- Technologie : Cloud Firestore
- Collection active : `/enterprises/{uid}` (snapshot v3, schéma entreprise unique)
- Stockage local : SharedPreferences + SQLite (via path_provider)
- Collections obsolètes (ne pas utiliser) : `/players/{uid}/saves/` et `/players/{uid}/analytics/`

**Services externes :**
- Comptes utilisateurs : Firebase Auth + Google Sign-In
- Stockage fichiers : NON UTILISÉ (Firebase Storage non actif dans ce projet)
- Mise en ligne : Google Play Store (en développement)
- Autres : Google Play Games Services (achievements, leaderboards)

---

## 3. ARCHITECTURE

> Cette structure ne change pas sans validation écrite dans ce fichier.

```
PaperClip2/
├── lib/
│   ├── screens/ + widgets/         → Couche 1 : Interface (UI uniquement)
│   ├── services/ + managers/       → Couche 2 : Logique métier
│   │   ├── persistence/            → Orchestration save/sync
│   │   ├── cloud/                  → Sync Firestore
│   │   ├── auth/                   → Authentification
│   │   ├── backend/                → Client API Functions
│   │   └── [autres sous-dossiers]
│   └── models/                     → Couche 3 : Données et état
├── functions/src/                  → Backend Firebase Functions
├── METHODO/                        → Méthode de travail (ne pas modifier)
├── PROJET_CONTEXTE.md              → Ce fichier
├── README.md                       → Commandes et démarrage
├── CHANGELOG.md                    → Historique des missions
├── BUGS.md                         → Bugs connus
└── STACK_STANDARD.md               → Stack de référence
```

**Nombre de services actifs : 20 / 20 maximum**

| # | Service | Rôle |
|---|---|---|
| 1 | GameState | État central du jeu |
| 2 | GamePersistenceOrchestrator | Orchestration sauvegarde/sync |
| 3 | LocalGamePersistence | Sauvegarde locale SQLite |
| 4 | CloudPersistenceAdapter | Synchronisation Firestore |
| 5 | AppBootstrapController | Démarrage et initialisation |
| 6 | GameRuntimeCoordinator | Boucle de jeu et runtime |
| 7 | EventSystem | Bus d'événements inter-services |
| 8 | AudioService | Sons et effets audio |
| 9 | FirebaseAuthService | Authentification Firebase |
| 10 | BackendHttpClient | Appels API Firebase Functions |
| 11 | AnalyticsService | Événements analytiques |
| 12 | MetricsWatchdog | Surveillance métriques jeu |
| 13 | ProgressionService | Règles de progression |
| 14 | UpgradeService | Effets des améliorations |
| 15 | XPService | Formules XP et niveaux |
| 16 | RareResourcesService | Quantum et Innovation Points |
| 17 | ResetRewardsCalculator | Calcul récompenses de reset |
| 18 | AgentSystem | 6 agents IA d'optimisation |
| 19 | MarketService | Insights et dynamique de marché |
| 20 | GoogleServicesAdapter | Play Games achievements/leaderboards |

---

## 4. FONCTIONNALITÉS

### ✅ Stables (ne pas toucher sans raison)
- Sauvegarde locale (SQLite/SharedPreferences)
- Synchronisation cloud Firestore — architecture entreprise unique, LWW
- Firebase Auth + Google Sign-In — cloud automatique si connecté (préférence `cloud_enabled` supprimée)
- Appels auth centralisés via `AppBootstrapController.requestGoogleSignIn()`
- Déclencheur sync unique : listener Firebase Auth dans `AppBootstrapController`
- Interface PageView (8 panneaux swipables)
- Système de recherche (tech tree, 20 nœuds)
- Ressources rares (Quantum max 500 / Innovation Points max 100)
- Système XP + niveaux
- Audio jeu (just_audio)
- Thème et design responsive (refonte avril 2026)

### 🚧 En cours (missions actives uniquement)
- Aucune mission active

### 🔜 Missions futures (ne pas commencer avant validation)
- Système de Reset complet (code partiel dans `services/reset/`, non testé)
- Agents IA (visibles en UI, non testés — code dans `agents/`)

### ❌ Bugs connus
- Aucun bug connu

### 🔒 Hors scope (ne jamais implémenter sans décision explicite)
- Architecture multi-worlds / multi-save (abandonnée — décision figée)
- Firebase Storage (non utilisé dans ce projet)
- Endpoints `/worlds/*` et `/saves/*` (supprimés du backend)

---

## 5. RÈGLES STRICTES DU PROJET

- Ne modifier QUE les fichiers concernés par la mission en cours
- Ne créer aucun nouveau fichier sans le lister ici après création
- Ne pas ajouter de dépendance sans demande explicite
- Modifier l'existant avant d'en créer du nouveau
- Zéro structure vide créée "pour le futur"
- Tout fichier .md créé hors des 5 autorisés va directement dans `_archives/`
- Les scripts Python à la racine (`fix_*.py`) et `.venv/` sont des artefacts obsolètes — ne pas les utiliser
- Le dossier `archive/` contient du code mort — ne pas en extraire sans décision explicite

---

## 6. DÉCISIONS FIGÉES

> Ces décisions ont été prises et validées. Elles ne se remettent pas en question.

| Date | Décision | Raison |
|---|---|---|
| 2026-04-07 | Architecture entreprise unique — 1 seule entreprise UUID v4 par joueur | Simplification vs multi-worlds, Firestore `/enterprises/{uid}` |
| 2026-04-07 | Stratégie LWW (Last-Write-Wins) pour les conflits cloud | Cloud gagne toujours à la connexion, offline-first sinon |
| 2026-04-08 | Interface PageView 8 panneaux swipables | Refonte UX mobile — responsive validé |
| 2026-04-10 | Firebase Storage non utilisé dans ce projet | Auth + Firestore suffisants, pas de besoin de stockage fichiers |

---

## 7. FICHIERS DE DOCUMENTATION AUTORISÉS

| Fichier | Rôle |
|---|---|
| PROJET_CONTEXTE.md | Source de vérité (ce fichier) |
| README.md | Présentation, commandes, démarrage |
| CHANGELOG.md | Historique des missions terminées |
| BUGS.md | Bugs connus et leur statut |
| STACK_STANDARD.md | Stack et règles de référence |

Tout autre fichier .md va dans `_archives/`, jamais créé spontanément.

---

## 8. SESSION EN COURS

**Objectif de la session :** Correction bug Android Google Sign-In (`clientConfigurationError — serverClientId must be provided, null`)
**Fichiers concernés :** `lib/services/auth/firebase_auth_service.dart` (1 fichier, 3 changements)
**Hors scope cette session :** Reset system, Agents IA, nouvelles fonctionnalités, refactoring architecture
**Résultat de fin de session :** ✅ Session terminée — Cause racine : `google_sign_in v7+` ne lit plus automatiquement le `serverClientId` depuis `google-services.json` sur Android. Fix : remplacement de `GoogleSignIn.instance` par une instance statique configurée avec `serverClientId` explicite (client Web, client_type 3 : `555184834356-lr2v3kje289ghiad05uj7d2eha74kqqi.apps.googleusercontent.com`). Méthodes migrées : `authenticate()` → `signIn()`, `attemptLightweightAuthentication()` → `signInSilently()`. 1 fichier modifié. ⚠️ À tester sur appareil Android physique avec APK debug fraîchement compilé.

---

## 9. BACKLOG (missions suivantes)

> Ordonné par priorité. Ne jamais commencer la suivante sans que la précédente soit ✅ testée.

1. ✅ Créer PROJET_CONTEXTE.md et aligner sur METHODO — fait le 2026-04-10
2. ✅ Nettoyage worldId → enterpriseId — fait le 2026-04-10 (0 occurrence résiduelle)
3. Implémenter et tester le système de Reset complet
4. Tester et valider les Agents IA (6 agents)

---

*Template source : METHODO/PROJET_CONTEXTE_TEMPLATE.md*
*Rempli avec : Claude (mode Project)*
*Lu par : Cascade à chaque début de session*

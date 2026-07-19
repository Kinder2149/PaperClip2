# BILAN AUDIT — PaperClip2
**Date :** 2026-04-12
**Fichiers analysés :** ~85 fichiers (screens, panels, managers, models, services, constants)
**Problèmes identifiés :** 39 problèmes uniques (après déduplication inter-phases)

---

## RÉSUMÉ EXÉCUTIF

Le jeu est jouable mais contient des impasses utilisateur critiques : depuis le menu Paramètres,
les actions "Nouvelle partie" et "Retour au menu" amènent sur un écran dont tous les boutons
sont neutralisés — l'utilisateur est coincé. La déconnexion depuis l'onglet Paramètres ne redirige
pas vers l'accueil. Deux effets de recherche achetables (Réduction volatilité, Saturation marché)
sont affichés comme "Actifs" mais n'ont aucun effet dans le jeu. Quatre chantiers techniques
sont partiellement câblés : acheter un nœud de recherche "Débloquer agent" ou "Bonus reset"
n'a aucune conséquence réelle (la logique est remplacée par un simple `print()`).
Environ 30 fichiers contiennent du code mort issu de systèmes supprimés (mode compétitif,
missions, Supabase, analytics HTTP) qui peuvent être supprimés sans risque.

---

## TABLEAU DE BORD

| # | Problème | Type | Impact | Complexité |
|---|---|---|---|---|
| F1 | StartScreen zombie : accessible depuis Paramètres mais boutons neutralisés | FLUX CASSÉ | 🔴 3 | MOYENNE |
| F2 | "Nouvelle partie" / "Retour au menu" mènent à StartScreen = impasse | FLUX CASSÉ | 🔴 3 | FAIBLE |
| F3 | Se déconnecter (onglet Paramètres) : Firebase déconnecté mais jeu reste ouvert | FLUX CASSÉ | 🔴 3 | FAIBLE |
| F4 | CompetitiveResultScreen → StartScreen = impasse (boutons morts) | FLUX CASSÉ | 🟡 2 | FAIBLE |
| F5 | Double déclenchement vers MainScreen (bootstrap + app_bootstrap_controller) | FLUX CASSÉ | 🟡 2 | MOYENNE |
| E1 | auth_choice_screen : route /auth déclarée, jamais appelée | ROUTE MORTE | 🟢 1 | FAIBLE |
| E2 | demand_calculation_screen : jamais importé ni navigué | ÉCRAN MORT | 🟢 1 | FAIBLE |
| E3 | sales_history_screen : jamais importé ni navigué | ÉCRAN MORT | 🟢 1 | FAIBLE |
| E4 | progression_screen : doublon du panel, orphelin | ÉCRAN MORT | 🟢 1 | FAIBLE |
| E5 | statistics_screen : doublon du panel, orphelin | ÉCRAN MORT | 🟢 1 | FAIBLE |
| E6 | competitive_result_screen : déclencheur absent, inaccessible | ÉCRAN MORT | 🟡 2 | FAIBLE |
| D1 | calculateQuantumReward en 2 versions incompatibles (types + bonus différents) | DOUBLON | 🔴 3 | MOYENNE |
| D2 | calculateInnovationPointsReward idem | DOUBLON | 🔴 3 | MOYENNE |
| D3 | Calcul discount métal en 3 endroits : ResourceManager oublie l'upgrade discount | DOUBLON | 🔴 3 | FAIBLE |
| D4 | Constantes formule reset dupliquées dans 2 fichiers (14 valeurs) | DOUBLON | 🟡 2 | FAIBLE |
| D5 | Constantes XP divergentes : game_config vs xp_config (valeurs différentes) | DOUBLON | 🔴 3 | FAIBLE |
| D6 | Reset fragmenté en 3 chemins sans orchestrateur + arbre recherche non réinitialisé au prestige | DOUBLON | 🔴 3 | ÉLEVÉE |
| D7 | calculateAutoclipperCost en 3 versions légèrement différentes | DOUBLON | 🟡 2 | MOYENNE |
| C1 | Système compétitif : 4 fichiers résidus (competitive_result_service, mode_indicator, etc.) | CODE MORT | 🟡 2 | FAIBLE |
| C2 | MissionSystem + mission.dart officiellement en pause, jamais initialisés | CODE MORT | 🟡 2 | FAIBLE |
| C3 | email_identity_service.dart : Supabase supprimé, toutes méthodes = UnsupportedError | CODE MORT | 🟢 1 | FAIBLE |
| C4 | analytics_http_port.dart désactivé, jamais instancié | CODE MORT | 🟢 1 | FAIBLE |
| C5 | EventManager : 5 méthodes mortes + 2 valeurs enum jamais émises | CODE MORT | 🟢 1 | FAIBLE |
| C6 | Mixins GameStateXxx jamais utilisés + 7 méthodes/constantes fantômes | CODE MORT | 🟢 1 | FAIBLE |
| C7 | AchievementsEventAdapter + LeaderboardsEventAdapter aveugles (eventId jamais émis) → Google Play Games non fonctionnel | CODE MORT | 🟡 2 | MOYENNE |
| B1 | CHANTIER-03 Recherche : acheter "Débloquer Agent / Slot" = print() seulement, aucun effet | CHANTIER BLOQUÉ | 🔴 3 | ÉLEVÉE |
| B2 | CHANTIER-05 Reset Progression : MODIFY_RESET = print(), recordReset() jamais appelé → 0 Quantum / PI généré | CHANTIER BLOQUÉ | 🔴 3 | ÉLEVÉE |
| B3 | CHANTIER-02 Ressources Rares : quantum/PI en save mais aucune mécanique ne les génère | CHANTIER BLOQUÉ | 🟡 2 | ÉLEVÉE |
| B4 | CHANTIER-04 Agents : déblocage via recherche silencieux (print() uniquement) | CHANTIER BLOQUÉ | 🟡 2 | MOYENNE |
| A1 | Recherche "Réduction volatilité" : affiché Actif, jamais lu par MarketManager | INCOHÉRENCE AFFICHAGE | 🔴 3 | FAIBLE |
| A2 | Recherche "Saturation marché" : affiché Actif, jamais appliqué dans processSales | INCOHÉRENCE AFFICHAGE | 🔴 3 | FAIBLE |
| A3 | Prix de vente affiché sur slider ≠ prix réel (bonus recherche non reflété) | INCOHÉRENCE AFFICHAGE | 🟡 2 | FAIBLE |
| A4 | Bouton "Créer un trombone" actif si métal = 0, tap silencieux sans feedback | INCOHÉRENCE AFFICHAGE | 🟡 2 | FAIBLE |
| A5 | Symbole $ au lieu de € dans ResearchPanel (header + coûts) | INCOHÉRENCE AFFICHAGE | 🟡 2 | FAIBLE |
| A6 | Bouton "Activer agent" affiché sans vérification Quantum : échec silencieux | INCOHÉRENCE AFFICHAGE | 🟡 2 | FAIBLE |
| A7 | Recherche "Formation Agents" (agentEfficiency) non appliquée dans AgentManager | INCOHÉRENCE AFFICHAGE | 🟡 2 | MOYENNE |
| A8 | Recherche "Automatisation Achat" : feature flag non connecté à l'achat auto métal | INCOHÉRENCE AFFICHAGE | 🟡 2 | MOYENNE |
| A9 | "Se déconnecter" : comportement différent selon SettingsPanel (rien) vs SettingsBottomSheet (ProfileScreen) | INCOHÉRENCE AFFICHAGE | 🟡 2 | FAIBLE |
| A10 | Réputation marché : valeur brute 0.5–1.5 sans explication ni unité | INCOHÉRENCE AFFICHAGE | 🟢 1 | FAIBLE |

---

## DÉTAIL PAR CATÉGORIE

### Flux cassés & impasses utilisateur

- **F1 — StartScreen zombie** : L'écran est encore accessible depuis le menu Paramètres (icône ⚙️) via "Nouvelle partie" et "Retour au menu". Une fois dessus, les boutons "Créer une entreprise" et "Continuer" affichent uniquement une notification sans rien faire. L'utilisateur se retrouve dans une impasse sans pouvoir avancer ni retourner au jeu facilement.

- **F2 — "Nouvelle partie" / "Retour au menu" mènent à StartScreen** : Ces deux actions du SettingsBottomSheet naviguent vers StartScreen avec `continueOpensWorlds: true`, un flag référençant le concept de "mondes" supprimé au CHANTIER-01. Résultat : un menu sans issue.

- **F3 — Déconnexion sans redirection** : L'onglet Paramètres (index 7 de MainScreen) appelle `FirebaseAuthService.signOut()` puis `setState()`. Firebase est bien déconnecté, mais l'utilisateur reste sur le MainScreen avec toutes les données du jeu visibles. Il devrait être redirigé vers WelcomeScreen.

- **F4 — CompetitiveResultScreen → StartScreen** : Cet écran (fin de partie compétitive) renvoie vers StartScreen. Or StartScreen est un zombie — voir F1.

- **F5 — Double navigation vers MainScreen** : Le BootstrapScreen peut naviguer vers MainScreen, ET l'AppBootstrapController peut simultanément pousser MainScreen via navigatorKey global si une sync cloud réussit pendant que l'utilisateur est sur WelcomeScreen. Deux entrées concurrentes vers le même écran.

---

### Écrans morts & orphelins

- **E1 — auth_choice_screen** : Route `/auth` déclarée dans main.dart, mais `Navigator.pushNamed(context, '/auth')` n'est appelé nulle part. Fichier importé dans start_screen.dart sans instanciation.

- **E2 — demand_calculation_screen** : Aucun import ni navigation depuis aucun fichier du projet. Orphelin complet.

- **E3 — sales_history_screen** : Même cas qu'E2.

- **E4 — progression_screen** : Son équivalent fonctionnel est `progression_panel.dart` (onglet 5 de MainScreen). Le screen est un doublon abandonné.

- **E5 — statistics_screen** : Idem, doublon de `statistics_panel.dart` (onglet 6).

- **E6 — competitive_result_screen** : L'événement `reason: 'ui_show_competitive_result'` qui devrait le déclencher n'est émis nulle part dans le code. L'écran existe mais est inaccessible.

---

### Doublons de logique

- **D1+D2 — calculateQuantumReward / calculateInnovationPointsReward** : Deux implémentations coexistent dans `reset_rewards_calculator.dart` et `rare_resources_calculator.dart`. Les constantes sont redéfinies localement dans la première. Le type du paramètre clips diffère (`double` vs `int`). Le bonus recherche n'est présent que dans une version. Risque de résultats différents selon le chemin emprunté.

- **D3 — Calcul discount métal** : Trois endroits calculent le prix effectif du métal. `GameState.effectiveMetalUnitPrice` est la version correcte (cumule upgrade + recherche). `ResourceManager.canPurchaseMetal()` oublie le discount upgrade — l'acheteur automatique métal utilise donc un prix incorrect, plus élevé que le réel.

- **D4 — Constantes formule reset** : 14 constantes identiques dans `rare_resources_constants.dart` ET redéfinies localement dans `reset_rewards_calculator.dart`. Toute modification d'équilibre doit être faite dans 2 fichiers.

- **D5 — Constantes XP divergentes** : `game_config.dart` (MANUAL_PRODUCTION_XP=1.5, COMBO_MULTIPLIER=0.1, MAX_COMBO_COUNT=5) et `xp_config.dart` (MANUAL_PRODUCTION_BASE=0.25, COMBO_INCREMENT=0.1, COMBO_MAX=10) définissent les mêmes paramètres avec des valeurs différentes.

- **D6 — Reset fragmenté** : Trois chemins de reset distincts sans orchestrateur central (GameState.reset(), ResetManager._resetAllManagers(), GameState.deleteEnterprise()). Problème critique : lors d'un prestige via ResetManager, l'arbre de recherche n'est PAS réinitialisé malgré l'existence de `ResearchManager.resetForProgression()`. Le joueur conserve ses recherches après un prestige.

- **D7 — calculateAutoclipperCost** : Présent dans PlayerManager (sans discount recherche), ProductionManager (avec discount recherche + automation), et UpgradeEffectsCalculator (sans discount recherche). Trois formules légèrement différentes pour le même calcul.

---

### Code mort & chantiers bloqués

- **C1 — Résidus du système compétitif** : `competitive_result_service.dart` (compute() jamais appelée), `competitive_mode_indicator.dart` (retourne SizedBox.shrink()), import fantôme de competitive_result_screen dans metal_crisis_dialog.dart, import fantôme de competitive_result_service dans game_state.dart. Tous issus du CHANTIER-01 supprimé.

- **C2 — MissionSystem** : Déclaré "OFFICIELLEMENT EN PAUSE" dans progression_system.dart. `initialize()` jamais appelé. Conservé uniquement pour compatibilité des saves JSON existantes.

- **C3 — email_identity_service.dart** : Supabase est supprimé du projet. Ce fichier lance `UnsupportedError` sur toutes ses méthodes. Jamais importé nulle part.

- **C4 — analytics_http_port.dart** : Déclaré "Port HTTP désactivé (Firebase Callable-only)". Lance `UnsupportedError`. Seul `NoOpAnalyticsPort` est utilisé — aucune analytics n'est jamais enregistrée.

- **C5 — EventManager méthodes mortes** : `_convertImportanceToPriority()` (doublon exact de `_importanceToPriority()`), `_cleanOldEvents()`, `getEventsByImportance()`, `showNotification()` (boucle fermée, aucun effet), `_featureUnlocker` (champ non utilisé dans la classe). Deux valeurs d'enum (`productionTick`, `marketTick`) jamais émises.

- **C6 — Mixins et méthodes fantômes** : 6 mixins GameStateXxx déclarés dans `game_state_interfaces.dart`, aucune classe n'utilise `with GameStateXxx`. 7 autres éléments : `calculateCompetitiveScore()` (retourne 0), `handleCompetitiveGameEnd()` (corps vide), `_getQuantumResearchBonus()` (TODO retourne 0.0), `_getInnovationResearchBonus()` (idem), `ProgressionBonus.calculateLevelBonus()` (wrapper inutile), `XPConfig.RESET_XP_BONUS_MAX_RESETS` et `PATH_MILESTONE_BONUS` (constantes jamais lues).

- **C7 — Google Play Games aveugle** : `AchievementsEventAdapter` et `LeaderboardsEventAdapter` sont démarrés dans main.dart et écoutent le bus d'événements. Ils attendent `event.data['eventId']` — mais aucun événement émis dans le codebase n'inclut ce champ. Résultat : les achievements et leaderboards Google Play Games ne fonctionneront jamais en production.

- **B1 — CHANTIER-03 Recherche : déblocage agent cassé** : Dans `_applyResearchEffect()`, les types `UNLOCK_AGENT` et `UNLOCK_SLOT` font uniquement `print('TODO...')`. Acheter un nœud de recherche "Débloquer Agent" dans l'interface ne débloque aucun agent réellement.

- **B2 — CHANTIER-05 Reset Progression : aucune génération de ressources rares** : Le type `MODIFY_RESET` dans `_applyResearchEffect()` fait uniquement `print('TODO...')`. `recordReset()` dans RareResourcesManager existe mais n'est jamais appelé lors d'un reset. Un joueur qui effectue un prestige ne reçoit ni Quantum ni Points Innovation.

- **B3 — CHANTIER-02 Ressources Rares** : Les champs quantum et pointsInnovation sont initialisés et sérialisés dans les saves, mais aucune mécanique de jeu active ne les fait augmenter (en l'absence de CHANTIER-04 et CHANTIER-05 complets).

- **B4 — CHANTIER-04 Agents : déblocage via recherche** : Même problème que B1 — `UNLOCK_SLOT` est un print(). Les agents peuvent être activés manuellement via l'UI, mais la mécanique "débloqué par une recherche" est silencieuse.

---

### Incohérences d'affichage

- **A1+A2 — Recherches affichées actives sans effet** : Les nœuds "Réduction volatilité" et "Saturation marché" sont achetables, affichés comme "Actifs" dans le panel Recherche, mais `volatilityReduction` et `marketSaturationRisk` ne sont jamais lus par MarketManager dans les calculs de simulation. Le joueur paie sans résultat.

- **A3 — Prix de vente affiché ≠ prix réel** : Le slider affiche `playerManager.sellPrice`. Les ventes se font à `sellPrice × (1 + bonus_recherche_prix_vente)`. Le prix effectif n'est jamais affiché nulle part.

- **A4 — Bouton "Créer un trombone" toujours actif** : Quand le métal tombe à 0, le bouton reste cliquable mais n'a aucun effet et ne donne aucun retour visuel à l'utilisateur.

- **A5 — Symbole $ dans ResearchPanel** : Le header "Argent" et les coûts des recherches en argent affichent `$X` alors que toute l'application utilise `€`.

- **A6 — Bouton "Activer agent" sans vérification Quantum** : Le bouton est affiché même si le joueur n'a pas assez de Quantum. En cas d'insuffisance, `activateAgent()` retourne `false` silencieusement, sans aucun message à l'utilisateur.

- **A7 — Formation Agents non appliquée** : La recherche `agentEfficiency` calcule un bonus mais AgentManager ne lit jamais ce bonus. Les agents travaillent toujours à leur efficacité de base.

- **A8 — Automatisation Achat non connectée** : La recherche débloque le feature flag `auto_metal_purchase`, mais ce flag n'est jamais lu par `_autoMetalBuyerEnabled` dans PlayerManager. L'achat automatique de métal n'est pas activé par cette recherche.

- **A9 — Double système de paramètres incohérent** : SettingsPanel (onglet 7) et SettingsBottomSheet (icône ⚙️) couvrent les mêmes fonctions. "Se déconnecter" depuis SettingsPanel appelle signOut + setState sans navigation. Depuis SettingsBottomSheet, c'est ProfileScreen qui gère la déconnexion avec redirection vers WelcomeScreen. Même action, résultats différents.

- **A10 — Réputation sans contexte** : La valeur de réputation (0.5 à 1.5) est affichée brute sans préciser que c'est un multiplicateur de demande mondiale, ni comment l'améliorer.

---

## ORDRE DE TRAITEMENT RECOMMANDÉ

### 🔴 Priorité 1 — Utilisateur bloqué ou trompé (traiter en premier)

| Ordre | Problème | Session estimée |
|---|---|---|
| 1 | **F2+F3** — Rerouter "Nouvelle partie" et "Retour menu" vers WelcomeScreen (contourne F1 sans supprimer StartScreen) | 1 session |
| 2 | **F3** — Se déconnecter depuis SettingsPanel : ajouter navigation vers WelcomeScreen | 1 session (30 min) |
| 3 | **A1+A2** — Implémenter volatilityReduction et marketSaturationRisk dans MarketManager, ou retirer l'affichage "Actif" | 1 session |
| 4 | **D3** — ResourceManager.canPurchaseMetal() : ajouter le discount upgrade manquant | 1 session (15 min) |
| 5 | **D5** — Unifier les constantes XP (supprimer celles de game_config, garder xp_config) | 1 session |
| 6 | **D1+D2** — Unifier calculateQuantumReward/calculateInnovationPointsReward sur RareResourcesCalculator | 1 session |
| 7 | **B1** — Implémenter UNLOCK_AGENT et UNLOCK_SLOT dans _applyResearchEffect() | 1 session |
| 8 | **B2** — Implémenter MODIFY_RESET et connecter recordReset() au flux de prestige | 1 session |
| 9 | **D6** — Appeler ResearchManager.resetForProgression() dans ResetManager._resetAllManagers() | 1 session (30 min) |

### 🟡 Priorité 2 — Confusion possible, expérience dégradée

| Ordre | Problème | Session estimée |
|---|---|---|
| 10 | **A5** — Remplacer $ par € dans ResearchPanel | 1 session (15 min) |
| 11 | **A4** — Désactiver bouton "Créer trombone" si métal = 0 + feedback visuel | 1 session (30 min) |
| 12 | **A6** — Désactiver bouton "Activer agent" si Quantum insuffisant + message | 1 session (30 min) |
| 13 | **A3** — Afficher le prix de vente effectif (avec bonus) à côté du slider | 1 session |
| 14 | **A9** — Unifier la déconnexion entre SettingsPanel et SettingsBottomSheet | 1 session |
| 15 | **A7+A8** — Connecter agentEfficiency à AgentManager + auto_metal_purchase à PlayerManager | 1 session |
| 16 | **C7** — Google Play Games : émettre eventId dans les événements déclencheurs | 1 session |
| 17 | **B3** — CHANTIER-02 : définir la mécanique de génération quantum/PI (dépend B1+B2) | Plusieurs sessions |
| 18 | **F5** — Double navigation MainScreen : ajouter garde `if (mounted)` dans bootstrap | 1 session (30 min) |
| 19 | **C1+C2** — Supprimer les résidus compétitifs et MissionSystem (attention: garder compatibilité save JSON) | 1 session |
| 20 | **D7** — Unifier calculateAutoclipperCost sur ProductionManager | 1 session |
| 21 | **E6+F4** — Supprimer CompetitiveResultScreen ou brancher un déclencheur valide | 1 session |

### 🟢 Priorité 3 — Technique uniquement, invisible utilisateur

| Ordre | Problème | Session estimée |
|---|---|---|
| 22 | **E1 à E5** — Supprimer 5 écrans orphelins + route /auth | 1 session |
| 23 | **C3+C4** — Supprimer email_identity_service.dart et analytics_http_port.dart | 1 session (15 min) |
| 24 | **C5+C6** — Nettoyer EventManager (méthodes mortes) + mixins GameStateXxx + méthodes fantômes | 1 session |
| 25 | **D4** — Supprimer constantes dupliquées dans reset_rewards_calculator.dart | 1 session (15 min) |
| 26 | **A10** — Afficher réputation comme "Multiplicateur de demande" avec une barre ou un label | 1 session |

---

*Document produit lors de l'AUDIT-COMPLET-V1 — Phase 5 : Synthèse & bilan final*
*Phases réalisées : 1 Navigation, 2 Affichage, 3 Doublons, 4 Code mort*

# Architecture — Clean Architecture (stricte)

> Status: FROZEN — 2025-12-25 (Option A: Clean absolu, greenfield)
> Toute évolution structurelle future doit être proposée via un ADR séparé et explicitement référencé ici. Les invariants d’identité/persistance et l’Option A (JWT-only, ownership par `player_uid`, aucune compat legacy) sont considérés comme normatifs.

Ce document décrit la structure cible du code et les règles de dépendances.

## Objectif

- Rendre le coeur métier testable (sans Flutter / UI / persistance).
- Réduire le couplage transversal (notamment via singletons globaux).
- Clarifier les responsabilités : données vs logique vs orchestration vs IO/UI.

## Couches (strictes)

### 1) Domain (`lib/domain`)

- **Contient** : règles métier pures, entités/valeurs, use-cases métier, événements métier (Domain Events).
- **Interdit** :
  - imports Flutter (`package:flutter/...`), `dart:ui`, widgets, navigation.
  - persistance (shared_preferences, fichiers, sqlite, etc.).
  - appels à des singletons UI (ex: `EventManager.instance`).
- **Autorisé** : `dart:core`, `dart:math`, `dart:async` (si nécessaire), classes pures.

### 2) Application (`lib/application`)

- **Contient** : orchestration des flux (cas d’usage applicatifs), coordination entre Domain et Infrastructure.
- **Rôle** : brancher les ports (interfaces) du Domain vers des implémentations Infrastructure.
- **Autorisé** : dépendre de `domain`.
- **Interdit** : widgets UI.

### 3) Infrastructure (`lib/infrastructure`)

- **Contient** : implémentations concrètes des ports (storage, persistance, services externes, adaptateurs).
- **Autorisé** : dépendre de `domain` et `application`.
- **Interdit** : dépendre de la couche UI (sauf si un adaptateur est explicitement côté UI/presentation).

### 4) Presentation (`lib/presentation`)

- **Contient** : UI Flutter (widgets, screens), UI stores (ex: EventManager si conservé côté UI), adaptateurs UI.
- **Autorisé** : dépendre de `application` (et donc indirectement du Domain).
- **Interdit** : le Domain ne dépend jamais de la Presentation.

## Règles de dépendances (résumé)

- `presentation` -> `application` -> `domain`
- `infrastructure` -> `application` -> `domain`
- **Jamais** : `domain` -> `presentation` ou `domain` -> `infrastructure`

## Ports (contrats)

Les communications sortantes du Domain (notifications, persistance, horloge, etc.) se font via des **ports** (interfaces) définis dans `domain`.

Exemples de ports à introduire progressivement :

- `DomainEventSink` : publication d’événements métier.
- `Clock` : accès au temps (pour timers/expiration) — optionnel mais recommandé.

## Événements

- `DomainEvent` : événement métier (pas de texte UI, pas d’icônes, pas de couleurs).
- `NotificationEvent` (UI) : représentation affichable à l’utilisateur.

Le mapping `DomainEvent -> NotificationEvent` doit vivre en `presentation` ou `infrastructure`, jamais dans le Domain.

## Règles anti-régression (P1)

- Ne pas ajouter de nouveaux usages de `EventManager.instance` dans le coeur métier.
- Ne pas importer Flutter dans les fichiers qui migrent vers `domain/`.

## Migration incrémentale

La migration est volontairement progressive :

1. Introduire les ports + adaptateurs.
2. Migrer les systèmes métier (ex: `LevelSystem`) pour publier des `DomainEvent` via port.
3. Réduire les responsabilités des stores UI (ex: `EventManager`).
4. Réduire `GameState` vers une façade d’état/commandes.

## GameState — Rôle et Frontières (référence)

### Rôle actuel

- Façade d’état du jeu, point central de lecture/écriture d’état runtime.
- Initialise et relie les managers coeur (Player/Market/Resource/Level/Production/Statistics), le `GameEngine` et l’`EventBus`.
- Délègue la logique métier (production, upgrades, marché, progression) au `GameEngine`/managers.
- Sérialise/désérialise l’état via snapshot (`toSnapshot`/`applySnapshot`).
- Orchestration: AUCUNE (tick, autosave, offline, UI, audio sont externalisés).

### Ce que GameState ne doit pas faire

- Pas de timers/boucles/scheduling (tick déclenché depuis un contrôleur externe).
- Pas d’UI/audio: pas de formatage/affichage/navigation ni de contrôle audio (événements uniquement, façades externes).
- Pas d’I/O direct de persistance (uniquement via l’orchestrateur).
- Pas de règles métier réimplémentées ici (utiliser `GameEngine`/managers/services spécialisés).

### Points d’extension autorisés

- Nouvelles lectures/écritures d’état simples et documentées.
- Délégation vers services/engine via méthodes fines (sans logique UI/audio).
- Évolution du snapshot (clés sous `metadata`/`core`/`stats`) documentée et testée.

### Garde-fous

- Interdiction d’introduire des helpers UI/audio/formatage dans `GameState`.
- Toute nouvelle méthode doit prouver la délégation métier et l’absence de scheduling/IO.
- Stratégie “snapshot-first”: le snapshot est la source de vérité; legacy conservé uniquement pour compat/migration.

## Références
- Conformité du système de sauvegarde: `docs/FINAL_SAVE_SYSTEM_COMPLIANCE.md`
- Schéma Supabase (identité): `docs/SUPABASE_SCHEMA.md`
- Checklist environnement Prod: `docs/PROD_ENV_CHECKLIST.md`

## Couche Runtime (Application) — Composants clés

- GameSessionController
  - Pilote la cadence et la boucle de jeu (timers), calcule `elapsedSeconds`.
  - Publie des métriques de tick (drift/durée) et déclenche le watchdog de dérive.

- GameRuntimeCoordinator
  - Orchestration runtime: autosave (via GamePersistenceOrchestrator), offline progress, lifecycle (pause/resume), wiring Audio/UI.
  - Maintient des métadonnées runtime (via `RuntimeMetaRegistry`) et les propage dans `GameState` avant persistance pour garder des snapshots cohérents.
  - Instrumentation autosave (métriques et watchdog lenteur/erreurs).

- GameUiFacade
  - Abonnée au bus d’événements de `GameState`; mappe les raisons UI (`ui_show_*`, `ui_unlock_notification`) vers `GameUiPort`/services UI.
  - Débranche l’UI du domaine.

- RuntimeMetaRegistry
  - Stocke `lastActiveAt`, `lastOfflineAppliedAt`, `offlineSpecVersion` hors du domaine.
  - Source de vérité runtime; synchronisée avec `GameState` au moment des saves/loads.

- Observabilité
  - `RuntimeMetrics`: logs structurés (tick/autosave/offline).
  - `RuntimeWatchdog`: alertes (tick drift élevé, autosave lente/erreurs consécutives).

# Architecture — Clean Architecture (stricte)

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

# Domain (Clean Architecture)

Ce dossier contient le **coeur métier** de l’application.

## Règles

- Pas d’import Flutter (`package:flutter/...`).
- Pas de persistance directe (pas de `SharedPreferences`, pas de fichiers, etc.).
- Pas de dépendance à des singletons UI (`EventManager.instance`, navigation, widgets).

## Contenu attendu

- Entités / Value Objects
- Services métier purs
- Événements métier (`DomainEvent`)
- Ports (interfaces) pour sortir du domain (ex: `DomainEventSink`, `Clock`)

## Migration

Le code existant migrera progressivement ici, en commençant par la progression (LevelSystem) et les événements.

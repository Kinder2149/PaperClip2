# Glossaire — Identité & Persistance

Dernière mise à jour: 2025-12-25

- player_uid: identifiant interne canonique du joueur (UUID v4), généré localement, stable, opaque, indépendant du réseau.
- partie_id: identifiant unique d’une partie (UUID v4), une partie appartient à un seul player_uid.
- snapshot: capture complète et autosuffisante de l’état d’une partie à un instant t.
- rev: numéro de révision séquentiel d’un snapshot au sein d’une même partie_id (append-only, strictement croissant).
- schema_version: version du format de snapshot, utilisée pour gérer les évolutions de schéma.

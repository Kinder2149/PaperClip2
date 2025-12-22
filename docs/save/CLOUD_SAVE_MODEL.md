# Modèle de Sauvegarde Cloud — Paperclip (Mission 4)

Objectif: définir le format d’export cloud à partir de SAVE_SCHEMA_V1 afin de permettre au joueur de retrouver sa partie sur plusieurs appareils, sans risque.

Références:
- Schéma local: `docs/save/SAVE_SCHEMA_V1.md` (source de vérité)
- Identité: `docs/google/IDENTITY_LAYER.md` (états d’identité, opt‑in requis)

Règles non négociables:
- Local > Cloud par défaut
- Choix utilisateur explicite (opt‑in)
- Aucune écriture cloud automatique destructrice

---

## 1) Objet CloudSave (transport)

Le cloud ne stocke qu’un paquet auto‑contenu, immuable au sens « snapshot de session » + quelques métadonnées minimales.

```json
{
  "cloudSave": {
    "id": "<server-guid-or-hash>",
    "owner": {
      "provider": "google",
      "playerId": "<google-play-games-id>"
    },
    "payload": {
      "version": "SAVE_SCHEMA_V1",
      "snapshot": <gameSnapshot-object>,
      "displayData": {
        "money": 0.0,
        "paperclips": 0.0,
        "autoClipperCount": 0,
        "netProfit": 0.0
      }
    },
    "meta": {
      "appVersion": "<GameConstants.VERSION>",
      "createdAt": "<ISO8601>",
      "uploadedAt": "<ISO8601>",
      "device": {
        "model": "?",
        "platform": "android|ios|web",
        "locale": "fr-FR"
      }
    }
  }
}
```

Principes:
- `payload.snapshot` = `gameSnapshot` (voir SAVE_SCHEMA_V1) → vérité du jeu.
- `displayData` = résumé pour listes cloud (non contractuel pour le gameplay).
- `owner` = rattachement à l’identité Google (récepteur passif; pas de logique d’auth détaillée ici).

---

## 2) Versionnement & compatibilité
- `payload.version` = `SAVE_SCHEMA_V1`
- Évolution vers V2: ajout de clés facultatives uniquement. Les sens sémantiques ne changent pas.
- Le serveur stocke des « révisions » (append‑only) pour conserver l’historique sans écrasement destructeur.

---

## 3) Métadonnées minimales
- `owner` (provider, playerId): rattachement identitaire
- `meta.appVersion`, `meta.uploadedAt`: traçabilité
- `meta.device`: purely informative (diagnostic)

---

## 4) Sécurité & intégrité
- Intégrité: checksum/etag côté serveur (hors scope implémentation) pour détecter conflits.
- Taille: limite serveur raisonnable (snapshot seul + displayData), pas de blobs.
- Confidentialité: pas de PII sensible dans le snapshot; l’identité est uniquement l’ID Play Games.

---

## 5) Stratégie de rétention côté cloud
- Historisation des révisions (dernier N, à définir)
- Marqueur « favorite/current » côté client (non destructeur) pour désigner la révision préférée par l’utilisateur

---

## 6) API cloud (conceptuelle)
- `POST /cloudsave` → crée une nouvelle révision (append‑only)
- `GET /cloudsave?owner=<playerId>` → liste les révisions (résumé + dates)
- `GET /cloudsave/{id}` → récupère une révision complète (snapshot)
- `PUT /cloudsave/{id}/label` → marquer une révision « favorite/current » (non destructeur)

Note: ce document ne prescrit pas l’implémentation ni l’hébergement; il fixe les invariants de format et de non‑destruction.

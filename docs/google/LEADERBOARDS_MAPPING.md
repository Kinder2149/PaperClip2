# Mapping Métriques → Classements Play Games (Mission 3)

Objectif: relier des métriques de progression aux classements Play Games. Google est récepteur passif: aucun upload automatique n’est décidé ici.

Références:
- Événements: `docs/progression/GAME_EVENTS_REFERENCE.md`
- Courbe: `docs/progression/PROGRESSION_CURVE_REFERENCE.md`
- Identité: `docs/google/IDENTITY_LAYER.md`

Lignes directrices:
- Métriques lisibles, résistantes aux exploits (limiter les effets d’un pic éphémère)
- Alignées avec les paliers de la courbe et l’économie du jeu
- Périmètre minimal (3–5 classements) pour itérer

---

## Classements proposés (alignés aux captures Play Console)

1) Classement Général
- Métrique: Score global composite (pondération de plusieurs indicateurs)
  - Base: `production.total_clips` (40%)
  - Économie: `economy.net_profit` (40%)
  - Maîtrise: `economy.money_per_minute_peak` (20%)
- Formule (indicative, à geler ultérieurement):
  - `score = w1*normalize(total_clips) + w2*normalize(net_profit) + w3*normalize(peak_mpm)`
- Raison courbe: valorise production, profit et maîtrise du tempo

2) Machine de Production
- Métrique: `production.total_clips`
- Type: cumulatif (croissant dans le temps)
- Raison courbe: lisible, robuste et emblématique du cœur du jeu

3) Banquier hors-pair
- Métrique: `economy.net_profit`
- Type: cumulatif (peut redescendre si dépenses > revenus, mais la mesure reste représentative)
- Raison courbe: focalisé sur la santé économique

---

## Normalisation & Anti-abus (principes)
- Normaliser chaque métrique en interne avant composition (min/max historiques, ou seuils fixes par saison)
- Définir des bornes de contribution par tick (éviter un gonflement ponctuel démesuré)
- Publier sur action explicite (pas de push silencieux)

## Fréquence de publication (proposée)
- Publication manuelle (bouton) ou à des moments clés (ex: fin de session), mais toujours opt-in
- IdentityLayer: requiert `signed_in_sync_enabled`

## Cohérence Courbe
- Les 3 classements couvrent: production (progression longue), économie (gestion), maîtrise (pic €/min)
- Alignement missions: milestones intermédiaires peuvent encourager la montée dans ces classements

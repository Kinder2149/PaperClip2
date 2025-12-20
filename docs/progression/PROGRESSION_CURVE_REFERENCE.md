# Référence Courbe de Progression (Paperclip)

Objectif: documenter les paliers, le rythme attendu, les zones critiques d’accélération/friction et la cohérence avec les missions (sur la base des audits existants, sans les réécrire).

## Principes Généraux
- Le core local est la source de vérité.
- La progression repose sur la production→vente→réinvestissement.
- Les paliers de niveau débloquent UI et leviers (marché, upgrades, automatisation).
- Les missions rythment l’orientation (objectifs atteignables, guidance légère).

---

## Paliers de Progression (extrait structuré)
- Palier A — Onboarding (Niveaux 1–4)
  - Découverte production manuelle et premières ventes
  - Constitution d’un petit capital
  - Frictions attendues: manque de métal temporaire
  - Leviers: prix de vente de base, achat de premier métal, 1ers upgrades

- Palier B — Déblocage Marché (Niveau 5)
  - Déblocage de l’écran Marché et dynamique de prix/demande
  - Introduction à la gestion de l’élasticité (prix) et des stocks
  - Leviers: achat de métal en pack, ajustement du prix, premières stratégies

- Palier C — Upgrades étendus (Niveau 7)
  - Déblocage des améliorations (production, stockage, qualité, marché)
  - Montée en puissance: vitesse/lot/efficacité, stockage plus grand
  - Apparition d’arbitrages (investissement vs liquidité)

- Palier D — Automatisation (milieu de jeu)
  - Achat d’autoclippers, production automatique significative
  - Cycle Argent→Autoclipper→Demande/Qualité→Ventes
  - Zones de friction: métal vs cadence de prod, prix trop haut

- Palier E — Maîtrise Marché (mid/late)
  - Utilisation d’upgrades Marché (Marketing, Réputation, Étude, Négociation)
  - Stabilisation via “Étude de marché”, optimisation de prix, réduction coût métal
  - Accélérations: enchaînements d’upgrades, réinvestissements efficaces

- Palier F — Endgame
  - Optimisation fine (qualité/marketing) et records 
  - Objectifs “longs” (trombones totaux, bénéfices, pics €/min)
  - Préparation aux succès & classements (jalons élevés)

---

## Rythme Attendu
- Première boucle courte (quelques minutes) jusqu’au marché
- Boucles plus longues ensuite (achats métal/upgrade/autoclippers)
- Pics d’accélération après déblocages et upgrades clés
- Ralentissements ponctuels: manque metal, prix trop agressif, crise marché

---

## Zones Critiques
- Frictions
  - Métal insuffisant vs hausse de cadences
  - Prix trop élevé → demande en berne
  - Volatilité marché (sans “Étude”) crée des écarts temporaires
- Accélérations
  - Acquisition d’autoclippers
  - Upgrades de production (speed/bulk/efficiency)
  - Upgrades marché (marketing, réputation, étude, négociation)

---

## Cohérence avec les Missions
- Les missions jalonnent les paliers précédents (production/ventes, achats clés, seuils d’XP)
- Elles servent de repères explicites pour les événements de référence (voir GAME_EVENTS_REFERENCE)
- Alignement: chaque mission doit mapper sur un ou plusieurs événements normalisés (ex: produire X, vendre Y, atteindre niveau N)

---

## Liens avec Réussites / Classements / Cloud
- Réussites: s’appuieront sur les événements normalisés (ponctuels/cumulatifs/métriques)
- Classements: exploitent des métriques claires (trombones totaux, bénéfice net, pics €/min, vitesse d’accès à des paliers)
- Sauvegarde cloud: synchronise les compteurs cumulés et snapshots de progression, tout en gardant le core local maître

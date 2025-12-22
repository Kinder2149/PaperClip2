# Mapping Événements → Succès Play Games (Mission 3)

Objectif: relier la référence d'événements (docs/progression/GAME_EVENTS_REFERENCE.md) aux succès Play Games. Google est récepteur passif: aucune émission automatique n'est décidée ici.

Références:
- Événements: `docs/progression/GAME_EVENTS_REFERENCE.md`
- Courbe: `docs/progression/PROGRESSION_CURVE_REFERENCE.md`
- Identité: `docs/google/IDENTITY_LAYER.md` (état signé requis pour publier, sans automatisme)

Lignes directrices:
- Pas de couplage à la sauvegarde.
- Déclencheurs côté client ultérieurement, via une couche d'orchestration qui consomme les événements normalisés.
- Seuils alignés avec la courbe (paliers lisibles: 1k/10k/100k, etc.).

---

## Tableau de correspondance (proposé)

1) Gain d'XP (succès: "Gain d'exp")
- Événement source: `level.reached`
- Type: Ponctuel (multi-niveaux)
- Critère: Atteindre le Niveau 5 (déblocage Marché)
- Raison courbe: marque la fin de l'onboarding

2) Score Compétitif 10K
- Événement source: `production.total_clips` (ou une métrique compétitive homologue si activée)
- Type: Métrique cumulée
- Critère: Total trombones produits ≥ 10,000
- Raison courbe: premier jalon de production significatif

3) Score Compétitif 50K
- Événement source: `production.total_clips`
- Type: Métrique cumulée
- Critère: Total trombones produits ≥ 50,000
- Raison courbe: jalon milieu de progression

4) Score Compétitif 100K
- Événement source: `production.total_clips`
- Type: Métrique cumulée
- Critère: Total trombones produits ≥ 100,000
- Raison courbe: jalon avancé

5) Speed Run
- Événement source: `time.total_played` + `level.reached`
- Type: Ponctuel (condition temporelle)
- Critère: Atteindre Niveau 7 en ≤ 20 minutes de jeu total
- Raison courbe: maîtrise de l'onboarding + accélération early-game

6) Maître de l'Efficacité
- Événement source: `upgrades.upgrade_purchased` (id = efficiency) + `statistics` (métal par trombone)
- Type: Ponctuel
- Critère: Atteindre une consommation ≤ 0.05 métal/clip (ou niveau d'upgrade efficacité max)
- Raison courbe: optimisation de la ressource critique

7) Premier Autoclipper
- Événement source: `automation.autoclipper_purchased`
- Type: Ponctuel
- Critère: Acheter 1 autoclipper
- Raison courbe: entrée dans l'automatisation

8) Marchand avisé
- Événement source: `market.price_set` + `market.demand_sampled`
- Type: Ponctuel
- Critère: Stabiliser une demande ≥ 0.75 pendant 60s avec prix custom
- Raison courbe: compréhension élasticité/prix

9) Ingénieur du Marché
- Événement source: `upgrades.branch_market_invested`
- Type: Ponctuel
- Critère: Acheter 1 upgrade de chaque type marché (marketing, réputation, étude, négociation)
- Raison courbe: diversification commerciale

10) Banquier hors-pair (option lié au classement homonyme)
- Événement source: `economy.net_profit`
- Type: Ponctuel
- Critère: Atteindre bénéfice net ≥ 10,000 €
- Raison courbe: jalon économique majeur

---

## Notes de cohérence
- Les seuils proposés respectent la progression (voir PROGRESSION_CURVE_REFERENCE).
- Les succès utilisent exclusivement les événements normalisés documentés.
- Aucune émission n'est faite vers Google dans ce document; l'Identity Layer impose un opt-in (signed_in_sync_enabled) et un déclenchement explicite ultérieur.

# Référence des Événements de Jeu (Paperclip)

Objectif: transformer les audits existants (missions + courbe joueur) en référence exploitable pour les succès, classements, synchronisation et sauvegarde cloud. Cette référence ne redéfinit pas les événements: elle les formalise.

## Légende
- Type: Unique (ponctuel), Cumulatif (compte sur la durée), Métrique (valeur mesurée en continu)
- Lien Progression: décrit le rôle dans la courbe joueur (déblocage, montée en puissance, économie, maîtrise, endgame)

---

## Économie et Production
- ID: production.manual_clip_made
  - Nom: Trombones produits (manuel)
  - Type: Cumulatif
  - Déclenchement: à chaque production manuelle
  - Lien Progression: onboarding, découverte du loop de base

- ID: production.auto_clip_made
  - Nom: Trombones produits (automatique)
  - Type: Cumulatif
  - Déclenchement: génération automatique par autoclippers
  - Lien Progression: montée en puissance et automatisation

- ID: production.total_clips
  - Nom: Total trombones produits
  - Type: Métrique (somme)
  - Déclenchement: mise à jour à chaque production
  - Lien Progression: jalons majeurs (1k, 10k, 100k, 1M)

- ID: economy.money_earned
  - Nom: Argent gagné (brut)
  - Type: Cumulatif
  - Déclenchement: à chaque vente
  - Lien Progression: capacité à financer upgrades et achats

- ID: economy.money_spent
  - Nom: Argent dépensé
  - Type: Cumulatif
  - Déclenchement: achat d’upgrades, autoclippers, métal
  - Lien Progression: investissement et gestion des ressources

- ID: economy.net_profit
  - Nom: Bénéfice net
  - Type: Métrique (money_earned - money_spent)
  - Déclenchement: recalcul après transactions
  - Lien Progression: santé économique, jalons de rentabilité

- ID: economy.money_per_minute_peak
  - Nom: Pic €/min
  - Type: Métrique (max historique)
  - Déclenchement: mis à jour à l’atteinte d’un nouveau pic
  - Lien Progression: efficacité commerciale maximale

- ID: economy.money_per_minute_current
  - Nom: €/min actuel
  - Type: Métrique (instantané)
  - Déclenchement: fenêtre glissante
  - Lien Progression: rythme courant, feedback de tuning

---

## Marché
- ID: market.price_set
  - Nom: Ajustement du prix de vente
  - Type: Ponctuel
  - Déclenchement: modification du prix par le joueur
  - Lien Progression: maîtrise du marché et de l’élasticité de la demande

- ID: market.demand_sampled
  - Nom: Demande estimée
  - Type: Métrique
  - Déclenchement: calcul de demande (prix, marketing, réputation, saturation, dynamiques)
  - Lien Progression: compréhension des leviers de marché

- ID: market.metal_purchased_pack
  - Nom: Achat de métal (pack)
  - Type: Cumulatif
  - Déclenchement: achat d’un pack de métal
  - Lien Progression: gestion des intrants et des coûts

- ID: market.reputation_level
  - Nom: Réputation (niveau courant)
  - Type: Métrique
  - Déclenchement: mises à jour marché/ventes
  - Lien Progression: fidélisation et demande soutenue

- ID: market.crisis_experienced
  - Nom: Crise de marché subie
  - Type: Cumulatif
  - Déclenchement: entrée dans une condition de crise (volatilité/stock)
  - Lien Progression: résilience, gestion du risque

---

## Automatisation et Upgrades
- ID: automation.autoclipper_purchased
  - Nom: Autoclipper acheté
  - Type: Cumulatif
  - Déclenchement: achat réussi d’un autoclipper
  - Lien Progression: accélération de la production

- ID: upgrades.upgrade_purchased
  - Nom: Amélioration achetée
  - Type: Cumulatif
  - Déclenchement: achat d’une amélioration (production, marché, stockage)
  - Lien Progression: verticalisation et spécialisation

- ID: upgrades.branch_market_invested
  - Nom: Investissement “Marché”
  - Type: Cumulatif
  - Déclenchement: achat d’upgrade marketing/réputation/étude/négociation
  - Lien Progression: orientation commerciale et stabilité

---

## Progression (Niveaux, Missions, Temps)
- ID: level.reached
  - Nom: Niveau atteint (n)
  - Type: Ponctuel (multi-niveaux)
  - Déclenchement: seuil XP franchi
  - Lien Progression: paliers de déblocage UI et features

- ID: time.total_played
  - Nom: Temps de jeu total
  - Type: Métrique (cumulé)
  - Déclenchement: incrément régulier
  - Lien Progression: engagement, cadence

- ID: mission.completed
  - Nom: Mission complétée
  - Type: Cumulatif
  - Déclenchement: critères mission atteints (cf. audit missions)
  - Lien Progression: guidage et structuration de la courbe

---

## Sauvegarde & Session
- ID: save.manual
  - Nom: Sauvegarde manuelle
  - Type: Ponctuel
  - Déclenchement: action utilisateur
  - Lien Progression: sécurité de session

- ID: save.autosave
  - Nom: Sauvegarde automatique (événement important)
  - Type: Ponctuel
  - Déclenchement: achat autoclipper, upgrades, milestones
  - Lien Progression: fluidité et continuité

- ID: session.offline_applied
  - Nom: Progression hors-ligne appliquée
  - Type: Ponctuel
  - Déclenchement: chargement avec intervalle offline calculé
  - Lien Progression: continuité cross-sessions

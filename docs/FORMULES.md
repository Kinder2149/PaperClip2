# Formules de Calcul - PaperClip2

**Date** : 9 avril 2026  
**Version** : 3.0  
**Statut** : ✅ Production

## 📋 Vue d'Ensemble

Ce document regroupe toutes les formules de calcul utilisées dans PaperClip2.

---

## 🔮 Quantum

### Formule Complète

```
Quantum = BASE + PRODUCTION + REVENUS + AUTOCLIPPERS + NIVEAU + TEMPS

Où :
- BASE = 20 (minimum garanti)
- PRODUCTION = log10(totalPaperclips / 1_000_000) × 15
- REVENUS = sqrt(totalMoney / 10_000) × 8
- AUTOCLIPPERS = autoClipperCount × 0.8
- NIVEAU = (playerLevel / 10)^1.5 × 12
- TEMPS = min(playTimeHours × 2, 50)

Bonus premier reset : ×1.5
Plafond maximum : 500 Q
```

### Exemples

**Reset 1 (niveau 20)** :
- totalPaperclips = 10M
- totalMoney = 50k€
- autoClippers = 50
- playTime = 5h
- → Quantum ≈ 30-40 Q

**Reset 2 (niveau 30)** :
- totalPaperclips = 100M
- totalMoney = 500k€
- autoClippers = 150
- playTime = 15h
- → Quantum ≈ 80-100 Q

**Reset 3+ (niveau 40+)** :
- totalPaperclips = 1B+
- totalMoney = 5M€+
- autoClippers = 300+
- playTime = 30h+
- → Quantum ≈ 150-200 Q

---

## 💡 Points Innovation

### Formule Complète

```
PointsInnovation = BASE + RECHERCHES + NIVEAU + BONUS_QUANTUM

Où :
- BASE = 10 (minimum)
- RECHERCHES = nombreRecherchesComplétées × 2
- NIVEAU = playerLevel × 0.5
- BONUS_QUANTUM = (quantumGagné / 10)

Plafond maximum : 100 PI
```

### Exemples

**Reset 1 (niveau 20, 5 recherches)** :
- recherches = 5
- niveau = 20
- quantum = 35
- → PI = 10 + 10 + 10 + 3.5 ≈ 20-25 PI

**Reset 2 (niveau 30, 12 recherches)** :
- recherches = 12
- niveau = 30
- quantum = 90
- → PI = 10 + 24 + 15 + 9 ≈ 45-50 PI

**Reset 3+ (niveau 40+, 20 recherches)** :
- recherches = 20
- niveau = 40
- quantum = 180
- → PI = 10 + 40 + 20 + 18 ≈ 70-80 PI

---

## 📊 Valeur Entreprise

### Formule Simplifiée

```
ValeurEntreprise = ARGENT + METAL + PRODUCTION + AUTOCLIPPERS

Où :
- ARGENT = totalMoney
- METAL = metalStock × prixMetal
- PRODUCTION = totalPaperclips × 0.001
- AUTOCLIPPERS = autoClipperCount × 100
```

### Utilisation

Cette formule est utilisée pour :
- Afficher valeur entreprise dans UI
- Calculer gains potentiels reset
- Recommandations timing reset

---

## 🎯 XP et Niveau

### Gain XP

```
XP par action :
- Fabriquer trombone : 1 XP
- Vendre trombone : 2 XP
- Acheter autoclipper : 50 XP
- Compléter recherche : 100 XP
- Activer agent : 75 XP
```

### XP Requis par Niveau

```
XP_requis(niveau) = 100 × (niveau^1.5)

Exemples :
- Niveau 2 : 283 XP
- Niveau 5 : 1118 XP
- Niveau 10 : 3162 XP
- Niveau 20 : 8944 XP
- Niveau 30 : 16431 XP
```

---

## 💰 Marché Mondial Simulé

> Mis à jour : 10 avril 2026 — Nouveau système de marché mondial avec concurrence simulée.

### Équation A — Demande Mondiale

```
DemandeMondiale(t) = 500 × (0.7 + 0.3 × sin(2π × t / 300))

Paramètres :
- 500  = demande de base mondiale (trombones/s)
- 0.7  = facteur minimum (cycle économique bas)
- t    = secondes de jeu cumulées depuis le début/reset
- 300s = période du cycle économique (5 minutes)

Résultat : varie entre 350/s et 500/s
```

### Équation B — Prix Concurrent

```
PrixConcurrent(t) = 0.30 × (1 + 0.20 × sin(2π × t / 360)) + bruit[-0.03, +0.03]

Paramètres :
- 0.30  = prix concurrent de base
- 0.20  = amplitude de variation (±20%)
- 360s  = période du cycle concurrent (6 minutes)
- bruit = valeur aléatoire fixée UNE FOIS par tick

Résultat : varie entre ~0.18€ et ~0.42€
```

### Équation C — Part de Marché du Joueur

```
delta = (PrixConcurrent - PrixJoueur) / PrixConcurrent

Si delta ≥ 0 (joueur moins cher — attractif) :
  PartMarché = clamp(0.20 + 0.50 × delta, 0.20, 0.70)

Si delta < 0 (joueur plus cher — peu attractif) :
  PartMarché = clamp(0.20 × (1 + delta)², 0.02, 0.20)

Exemples :
- Joueur à 0.25€ vs concurrent 0.30€ → delta=+0.17 → part=28%
- Joueur au même prix (0.30€) → delta=0 → part=20%
- Joueur à 0.35€ vs concurrent 0.30€ → delta=-0.17 → part=14%
- Joueur à 0.45€ vs concurrent 0.30€ → delta=-0.5 → part=5%
```

### Équation D — Ventes Réelles

```
DemandePrixJoueur = DemandeMondiale × PartMarché × Marketing × Réputation

VentesRéelles/s = min(DemandePrixJoueur, StockTrombones)

Marketing = 1 + niveau × 0.15   (bonus upgrades)
Réputation = 0.5 à 1.5          (évolue avec l'historique des ventes)
```

### Agent MarketAnalyst — Stratégie d'optimisation

```
L'agent teste 3 scénarios à chaque activation (toutes les 5 min) :
  Revenue_stable = prixActuel     × demand(prixActuel)
  Revenue_+3%    = prixActuel×1.03 × demand(prixActuel×1.03)
  Revenue_-3%    = prixActuel×0.97 × demand(prixActuel×0.97)

→ Applique la direction avec le meilleur revenu/s
→ Borné entre MIN_PRICE (0.01€) et MAX_PRICE (0.50€)
```

### Réputation

```
Réputation évolue lentement (tous les 10s) :
- Prix dans la plage optimale (0.25-0.35€) + ventes régulières → +0.01
- Prix excessif (> 0.50€) + faibles ventes consécutives → -0.01
Bornes : 0.5 à 1.5
```

---

## 🏭 Production

### Production Manuelle

```
Production_manuelle = 1 trombone par clic
```

### Production Automatique

```
Production_auto = ∑(autoclipper_i × vitesse_i)

Où :
- autoclipper_i = nombre d'autoclippers de niveau i
- vitesse_i = vitesse de base × multiplicateurs

Vitesses de base :
- Niveau 1 : 1 trombone/s
- Niveau 2 : 2 trombones/s
- Niveau 3 : 5 trombones/s
- Niveau 4 : 10 trombones/s
- Niveau 5 : 25 trombones/s
```

### Multiplicateurs Production

```
Multiplicateur_total = RECHERCHES × AGENTS × NIVEAU

Où :
- RECHERCHES : 1.0 à 3.0 (cumul recherches)
- AGENTS : 1.0 à 2.0 (agents actifs)
- NIVEAU : 1.0 + (playerLevel × 0.01)
```

---

## 🤖 Coûts Agents

### Activation Agent

```
Coût_activation = COUT_BASE × (1 + activations_precedentes × 0.5)

Coûts de base :
- ProductionOptimizer : 10 Q
- MarketAnalyst : 15 Q
- MetalBuyer : 12 Q
- InnovationResearcher : 20 Q
- QuantumResearcher : 25 Q
```

### Durée Agent

```
Durée = DUREE_BASE × (1 + niveau_recherche × 0.2)

Durées de base :
- Tous les agents : 300s (5 minutes)

Avec recherches :
- Niveau 1 : 360s (6 minutes)
- Niveau 2 : 420s (7 minutes)
- Niveau 3 : 480s (8 minutes)
```

---

## 🔬 Coûts Recherches

### Formule Générale

```
Coût_recherche = COUT_BASE × (1 + dépendances × 0.3)

Coûts de base :
- Recherches Tier 1 : 5 PI
- Recherches Tier 2 : 10 PI
- Recherches Tier 3 : 20 PI
- Recherches META : 50 PI
```

---

## 📊 Métriques Équilibrage

### Progression Cible

| Niveau | Temps | Quantum | PI | Resets |
|--------|-------|---------|-----|--------|
| 20 | 2-3h | 30-40 | 20-25 | 1 |
| 30 | 5-7h | 80-100 | 45-50 | 2 |
| 40 | 10-15h | 150-200 | 70-80 | 3-4 |
| 50 | 20-30h | 300-400 | 90-100 | 5-7 |

### Validation

- Reset rentable à partir niveau 20
- Progression cohérente
- Agents utiles mais pas obligatoires
- Recherches impactantes

---

**Dernière mise à jour** : 9 avril 2026  
**Statut** : ✅ Production

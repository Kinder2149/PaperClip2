# PaperClip2 - Dossier Screens

## Objectif

Le dossier `screens` contient tous les écrans principaux de l'application. Chaque écran représente une vue complète et indépendante accessible via la navigation principale ou secondaire.

## Écrans Principaux

- **production_screen.dart** : Écran principal de production où le joueur peut fabriquer des trombones manuellement et voir ses auto-clippers fonctionner.

- **market_screen.dart** : Écran du marché où le joueur peut vendre ses trombones, suivre les tendances de prix et gérer ses stratégies de vente.

- **new_metal_production_screen.dart** : Écran dédié à la production et à l'achat de métal, ressource essentielle à la fabrication de trombones.

- **upgrade_screen.dart** : Écran d'achat des améliorations disponibles pour le joueur.

- **settings_screen.dart** : Écran de configuration des paramètres du jeu et de gestion du compte utilisateur.

- **friends_screen.dart** et **leaderboard_screen.dart** : Écrans liés aux fonctionnalités sociales (amis, classements).

- **achievements_screen.dart** : Écran affichant les succès et objectifs du joueur.

## Architecture

Chaque écran suit une architecture similaire :
1. Utilisation de `Consumer<GameState>` pour accéder à l'état du jeu via Provider
2. Organisation en sections distinctes pour une meilleure lisibilité
3. Délégation de la logique métier aux managers appropriés
4. Utilisation de widgets réutilisables pour les éléments communs

## Navigation

La navigation entre les écrans se fait principalement via :
- Une barre de navigation inférieure (BottomNavigationBar)
- Des boutons spécifiques pour la navigation contextuelle
- Le gestionnaire de routes Flutter pour les transitions

## Bonnes Pratiques

- Séparer clairement la logique d'affichage de la logique métier
- Utiliser des Builders pour les sections complexes de l'interface
- Préférer les widgets stateless quand possible pour améliorer les performances
- Appliquer la réactivité via Provider/Consumer pour les mises à jour d'interface

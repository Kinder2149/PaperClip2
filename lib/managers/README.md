# PaperClip2 - Dossier Managers

## Objectif

Le dossier `managers` contient tous les gestionnaires qui implémentent la logique métier principale du jeu. Ces classes sont responsables de la gestion des différents aspects du gameplay et des mécaniques de jeu.

## Composants Principaux

- **player_manager.dart** : Gère toutes les données et fonctionnalités liées au joueur, y compris l'achat d'améliorations, la gestion des ressources du joueur et les statistiques de progression.

- **resource_manager.dart** : Gère la production et la consommation des ressources principales du jeu (trombones, métal, argent). Ce manager a été standardisé pour utiliser "métal" comme ressource principale (anciennement "wire").

- **market_manager.dart** : Gère tout ce qui est lié au marché, y compris les ventes, la demande, les prix et les statistiques de vente.

- **production_manager.dart** : Gère la logique de production, y compris les autoclippers, megaclippers et autres systèmes de production automatique.

- **event_manager.dart** : Gère le système d'événements du jeu, permettant aux composants de s'abonner et de réagir à des événements spécifiques.

- **mock/** : Sous-dossier contenant des versions mock des managers pour les tests et le développement.

## Conventions de Nommage

Suite à la standardisation des noms de méthodes, les conventions suivantes sont appliquées :
- Achat d'éléments : `purchase<Item>` (ex: `purchaseAutoClipper`, `purchaseMetal`)
- Production de ressources : `produce<Resource>` (ex: `producePaperclip`, `produceClips`)
- Consommation de ressources : `spend<Resource>` (ex: `spendMetal`, `spendMoney`)

## Dépendances

Les managers interagissent entre eux via des interfaces définies dans `game_state_interfaces.dart`. Cela permet d'éviter les dépendances circulaires et de faciliter les tests unitaires.

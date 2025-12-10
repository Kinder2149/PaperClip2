# PaperClip2 - Dossier Utils

## Objectif

Le dossier `utils` contient des fonctions et classes utilitaires qui peuvent être utilisées dans toute l'application. Ces utilitaires fournissent des fonctionnalités génériques qui ne sont pas spécifiques à la logique métier du jeu.

## Composants Principaux

- **formatter_utils.dart** : Fonctions pour formatter les nombres, dates, et autres types de données pour l'affichage.

- **icon_helper.dart** : Utilitaire pour gérer les icônes de l'application, récupérer les icônes appropriées pour différentes entités du jeu.

- **color_utils.dart** : Utilitaires pour la gestion des couleurs, la génération de dégradés, et autres manipulations visuelles.

- **time_utils.dart** : Fonctions pour la manipulation et le formatage du temps et des durées.

- **url_handler.dart** : Utilitaire pour gérer les URLs et les liens externes.

## Historique

Ce dossier a été consolidé lors de la réorganisation du projet. Les fonctionnalités qui étaient auparavant séparées entre `utils` et `utilities` ont été fusionnées dans ce seul dossier pour éviter la duplication et la confusion.

## Bonnes Pratiques

- Les fonctions dans ce dossier doivent être purement fonctionnelles (sans effets de bord) quand c'est possible.
- Les utilitaires doivent être bien documentés avec des commentaires clairs sur leur usage.
- Préférer des fonctions ou méthodes statiques pour les utilitaires simples.
- Les classes utilitaires complexes peuvent être implémentées comme des services si elles nécessitent un état.

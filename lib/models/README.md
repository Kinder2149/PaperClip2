# PaperClip2 - Dossier Models

## Objectif

Le dossier `models` contient les structures de données fondamentales, les interfaces et les classes de base qui définissent l'architecture du jeu. Ces modèles servent de contrats entre les différents composants du système.

## Composants Principaux

- **game_state.dart** : Classe centrale qui coordonne tous les managers et fournit un point d'accès unifié à l'état du jeu. Elle est utilisée avec Provider pour la gestion d'état.

- **game_state_interfaces.dart** : Définit les interfaces que doivent implémenter les différents managers. Permet de découpler les composants et d'éviter les dépendances circulaires.

- **json_loadable.dart** : Interface de base pour les objets qui peuvent être sérialisés/désérialisés en JSON. Utilisée par les managers pour la sauvegarde/chargement.

- **event_system.dart** : Définit le système d'événements de l'application, permettant la communication entre composants.

- **level_system.dart** : Gère le système de niveaux et d'expérience du joueur.

- **progression_system.dart** : Gère la progression du joueur et les succès.

- **upgrade.dart** : Modèles pour les améliorations disponibles dans le jeu.

## Fichiers Legacy

Certains fichiers sont marqués avec le suffixe `_legacy` pour indiquer qu'ils sont obsolètes mais conservés pour référence ou compatibilité :

- **resource_manager_legacy.dart** : Ancienne version du gestionnaire de ressources, remplacée par celle dans le dossier `managers/`.
- **game_state_legacy.dart** : Ancienne version de l'état du jeu, conservée pour référence.

## Notes Importantes

La logique métier a été migrée des modèles vers les managers appropriés. Les modèles dans ce dossier se concentrent désormais sur la structure des données plutôt que sur la logique applicative.

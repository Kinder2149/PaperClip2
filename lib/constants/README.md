# PaperClip2 - Dossier Constants

## Objectif

Le dossier `constants` est un dossier centralisé qui contient toutes les constantes et configurations utilisées dans l'application. Cette organisation facilite la maintenance et la cohérence du code.

## Composants Principaux

- **game_config.dart** : Contient toutes les configurations et paramètres du jeu, notamment :
  - Les énumérations pour les types d'événements (`EventType`)
  - Les modes de jeu (`GameMode`)
  - Les constantes d'équilibrage (coûts, taux, efficacité du métal, etc.)
  - Les paramètres de base de production et de vente
  - Les configurations de fonctionnalités spécifiques

- **game_constants.dart** : Contient des constantes spécifiques à la mécanique de jeu et aux règles de gameplay, comme :
  - Les intervalles de temps pour divers événements
  - Les valeurs par défaut pour l'initialisation des composants
  - Les facteurs de conversion et multiplicateurs

- **storage_constants.dart** : Définit les constantes utilisées pour le stockage de données, notamment :
  - Les clés pour SharedPreferences
  - Les noms de fichiers pour les sauvegardes locales
  - Les identifiants pour le stockage cloud
  - Les formats de date et structures de fichiers

## Historique

Ce dossier a été créé lors de la réorganisation du projet pour centraliser toutes les constantes qui étaient auparavant dispersées dans les dossiers `models` et `services`. Cette consolidation améliore la maintenabilité et réduit la duplication.

## Bonnes Pratiques

- Toute nouvelle constante doit être ajoutée au fichier approprié dans ce dossier.
- Les constantes doivent être regroupées de manière logique et documentées clairement.
- Préférer l'utilisation des constantes définies ici plutôt que des valeurs littérales dans le code.

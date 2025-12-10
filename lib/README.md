# PaperClip2 - Structure du Projet

## Vue d'ensemble

PaperClip2 est un jeu de type idle/clicker développé en Flutter. Ce dossier `lib` contient l'ensemble du code source de l'application.

## Structure des dossiers

- **constants/** : Contient toutes les constantes de l'application (configurations de jeu, constantes de stockage, etc.)
- **managers/** : Contient les gestionnaires qui implémentent la logique métier du jeu (production, marché, ressources, joueur, etc.)
- **models/** : Contient les modèles de données et interfaces du jeu
- **screens/** : Contient les écrans principaux de l'application
- **services/** : Contient les services qui interagissent avec les systèmes externes (sauvegarde, authentification, API, etc.)
- **utils/** : Contient des utilitaires et helpers divers
- **widgets/** : Contient les widgets réutilisables organisés par catégorie

## Architecture

L'application utilise une architecture basée sur le modèle Provider pour la gestion d'état. Le `GameState` sert de point central pour accéder aux différents managers et services.

## Migration Récente

Le projet a subi une migration majeure de Firebase vers une API FastAPI personnalisée. De plus, une réorganisation de la structure du projet a été effectuée pour améliorer la maintenabilité (fusion de dossiers redondants, consolidation des constantes, standardisation des noms de méthodes).

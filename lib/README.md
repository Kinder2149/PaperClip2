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

## Orientation Backend

Le backend autoritaire est Firebase Cloud Functions (HTTP v2) + Firestore. FastAPI est considéré comme legacy et n'est plus utilisé. Les services réseau du client consomment l'API Functions via `EnvConfig.backendBaseUrl` et s'authentifient avec un ID Token Firebase.

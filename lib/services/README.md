# PaperClip2 - Dossier Services

## Objectif

Le dossier `services` contient les services qui interagissent avec des systèmes externes ou fournissent des fonctionnalités transversales à l'application. Ces services sont généralement des singletons qui peuvent être accédés depuis différents points de l'application.

## Composants Principaux

- **api_client.dart** : Client API centralisé pour toutes les interactions avec le backend FastAPI. Gère les requêtes HTTP, l'authentification et le traitement des réponses.

- **auth_service.dart** : Gère l'authentification utilisateur, y compris la connexion par fournisseurs externes (Google, Apple) et la persistance des sessions. Remplace l'ancien service Firebase Authentication.

- **auto_save_service.dart** : Service responsable de la sauvegarde automatique périodique de l'état du jeu.



- **notification_service.dart** et **notification_storage_service.dart** : Gèrent les notifications in-app et leur persistance.

- **social_service.dart** : Gère les fonctionnalités sociales comme les amis, les classements et les succès. Interface avec les APIs sociales du backend.

- **storage_service.dart** : Service pour le stockage et la récupération de fichiers. Remplace Firebase Storage.

## Migration Backend

Ces services ont été refactorisés pour utiliser un backend FastAPI personnalisé au lieu de Firebase. Les points importants de cette migration sont :

- Utilisation de tokens JWT au lieu de tokens Firebase
- Gestion locale de la persistance des sessions
- Implémentation d'une stratégie de rafraîchissement silencieux des tokens via Google OAuth
- Uniformisation des appels API via le client API central

## Cohérence avec le Backend

Les services ont été conçus pour correspondre aux endpoints FastAPI suivants :
- `/auth/` : Authentification et gestion des utilisateurs
- `/api/storage/` : Stockage et récupération de fichiers
- `/api/social/` : Fonctionnalités sociales
- `/api/analytics/` : Analytique et reporting
- `/api/config/` : Configuration à distance

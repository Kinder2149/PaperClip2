# Migration de Firebase vers FastAPI

Ce document décrit la migration complète de l'application Flutter PaperClip2 de Firebase vers un backend FastAPI personnalisé.

## Configuration requise

Pour que l'application fonctionne correctement, vous devez créer un fichier `.env` à la racine du projet avec les variables suivantes :

```
# URL de l'API - Utilisées selon le mode de compilation
API_BASE_URL=https://paperclip2-api.onrender.com/api
API_PROD_URL=https://paperclip2-api.onrender.com/api
API_DEV_URL=http://10.0.2.2:8000/api

# Clé API pour l'authentification
API_KEY=votre_api_key_ici

# Configuration du stockage S3 (si utilisé)
S3_BUCKET_NAME=paperclip2-storage
S3_REGION=eu-west-3

# IDs pour l'authentification OAuth
GOOGLE_CLIENT_ID=votre_google_client_id_ici
APPLE_CLIENT_ID=votre_apple_client_id_ici
```

## Services migrés

### 1. AuthService
- Remplace Firebase Authentication
- Gère l'authentification par email/mot de passe et fournisseurs OAuth (Google, Apple)
- Utilise des jetons JWT pour l'authentification entre sessions

### 2. StorageService
- Remplace Firebase Storage
- Gère le téléchargement et le téléversement de fichiers
- Supporte le stockage local et dans le cloud (S3)

### 3. SaveService
- Remplace Firestore pour les sauvegardes
- Gère la synchronisation des sauvegardes entre local et cloud
- Optimisé pour minimiser les transferts de données

### 4. SocialService
- Remplace les fonctionnalités sociales de Firebase
- Gestion des amis, demandes d'amitié et classements
- Statistiques utilisateur et succès

### 5. AnalyticsService
- Remplace Firebase Analytics et Crashlytics
- Suivi des événements et erreurs
- Génération de rapports personnalisés

### 6. ConfigService
- Remplace Firebase Remote Config
- Configuration à distance de l'application
- Gestion des paramètres et fonctionnalités

## Structure des fichiers

Les services principaux se trouvent dans les répertoires suivants :
- `lib/services/api/` : Services d'API principaux
- `lib/services/user/` : Gestion des utilisateurs
- `lib/services/social/` : Fonctionnalités sociales
- `lib/services/save/` : Système de sauvegarde
- `lib/config/` : Configuration centralisée

## Notes importantes

1. Tous les appels API utilisent désormais des paramètres nommés pour plus de clarté
2. Les réponses API suivent un format standard : `{'success': bool, 'data': any, 'message': string}`
3. La gestion des erreurs est centralisée via `analyticsService.recordError()`
4. Les anciens fichiers Firebase ont été remplacés ou conservés avec l'extension `.bak`

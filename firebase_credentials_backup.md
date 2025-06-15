# PaperClip2 - Sauvegarde des Identifiants Firebase

## Identifiants du Projet
- **Projet ID**: paperclip2-2149
- **Sender ID**: 426827215567
- **Android App ID**: 1:426827215567:android:3ad9dbbddffce7c8ef2dd0
- **Bundle ID iOS**: com.example.paperclip2

## URLs Firebase
- **Database URL**: https://paperclip2-2149-default-rtdb.europe-west1.firebasedatabase.app
- **Storage Bucket**: paperclip2-2149.firebasestorage.app

## Clés API
- Android Debug API Key: AIzaSyD-9tSrke72PouQMnMX-a7eZSW0jkFMBWY
- Les autres clés API sont stockées dans le fichier `.env` avec les variables suivantes:
  - FIREBASE_ANDROID_API_KEY
  - FIREBASE_IOS_API_KEY
  - FIREBASE_WEB_API_KEY

## Configuration Firebase
Les services configurés dans l'application:
- Firebase Core
- Firebase Analytics
- Firebase Crashlytics
- Firebase Storage
- Firebase Remote Config

## Structure de stockage
- Les sauvegardes sont stockées dans: `saves/{userId}/game_save.json`

## Paramètres du jeu (Remote Config)
- metal_per_paperclip: 0.15
- initial_price: 0.25
- efficiency_multiplier: 0.10
- max_efficiency_level: 8

Conservez ce fichier en lieu sûr pour référence future si vous décidez de rétablir Firebase ou de migrer vers un autre service cloud.

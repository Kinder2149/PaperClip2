Politique de confidentialité – PaperClip2
Dernière mise à jour: 2025-12-30

1. Qui sommes-nous ?
Éditeur: [Keamder - DEV]
Application: PaperClip2 (com.kinder2149.paperclip2)
2. Portée de la présente politique
La présente politique décrit les traitements de données réalisés par l’application mobile PaperClip2, disponible sur Google Play. Elle s’applique à l’application, à ses fonctionnalités en ligne et aux services nécessaires à son fonctionnement.

3. Données traitées
3.1 Données d’identification de compte

Identifiants techniques liés à l’authentification et au compte (via Supabase Flutter).
Éléments potentiels liés au profil (ex.: email, nom d’affichage, avatar) si fournis dans le cadre de l’authentification.
Base factuelle: dépendance supabase_flutter (client) et flux OAuth (intent-filter io.supabase.flutter://login-callback).
3.2 Données de progression de jeu

Données de sauvegarde/état de partie nécessaires au fonctionnement du jeu (scores, progression, paramètres).
Base factuelle: composant de persistance applicative (stockage local et synchronisations réseau côté app).
3.3 Intégrations Google Play Games (le cas échéant)

Utilisation des services Google Play Games v2 pour fonctionnalités ludiques (succès/classements si activés).
Base factuelle: dépendance Android com.google.android.gms:play-services-games-v2:20.0.0 et métadonnée com.google.android.gms.games.APP_ID.
3.4 Données techniques de l’appareil

Informations techniques minimales nécessaires au fonctionnement, au diagnostic et à la compatibilité (ex.: version app).
Base factuelle: dépendance package_info_plus.
3.5 Stockage local sur l’appareil

Préférences applicatives (shared_preferences).
Cache d’images réseau (cached_network_image).
Stockage sécurisé de secrets/tokens (flutter_secure_storage).
Base factuelle: dépendances shared_preferences, cached_network_image, flutter_secure_storage, sqflite.
4. Données non collectées / Permissions non demandées
4.1 Accès aux médias et fichiers partagés

L’application ne déclare pas de permissions d’accès aux médias partagés ni au stockage externe de l’appareil.
Permissions suivantes non déclarées dans le manifeste source:
READ_MEDIA_IMAGES / READ_MEDIA_VIDEO / READ_MEDIA_AUDIO
READ_EXTERNAL_STORAGE / WRITE_EXTERNAL_STORAGE
Base factuelle: android/app/src/main/AndroidManifest.xml (seule permission présente: INTERNET).
4.2 Publicité et identifiant publicitaire

Aucune SDK publicitaire n’est intégrée.
La permission AD_ID n’est pas déclarée.
Base factuelle: pubspec.yaml, pubspec.lock, android/app/build.gradle, manifests source.
5. Finalités du traitement
Authentification et gestion du compte (via Supabase).
Sauvegarde et restauration de la progression du jeu.
Fonctionnalités ludiques (succès/leaderboards) via Google Play Games (si activées).
Amélioration de la stabilité et du fonctionnement (diagnostic minimal nécessaire).
Aucune diffusion de publicités.
6. Bases légales
Exécution du contrat (fourniture des fonctionnalités du jeu).
Intérêt légitime (sécurité, prévention des abus, maintien en conditions opérationnelles).
Consentement lorsque requis par la loi pour certaines intégrations (si applicable).
7. Partage de données
Fournisseurs techniques strictement nécessaires:
Supabase (authentification et backend applicatif).
Google Play Games (fonctionnalités ludiques, si activées).
Aucune vente de données.
Aucune transmission à des réseaux publicitaires.
8. Lieux de traitement et transferts
Les données peuvent être traitées et hébergées par des prestataires d’infrastructure sélectionnés par l’éditeur et/ou par Supabase.
Les localisations d’hébergement peuvent impliquer des transferts hors de l’UE selon la configuration des services.
[À compléter le cas échéant: régions, clauses contractuelles, mécanismes de transfert]
9. Durées de conservation
Données de compte: pendant la durée d’utilisation du service et selon obligations légales applicables.
Données de jeu: tant que le compte est actif ou jusqu’à suppression par l’utilisateur, sous réserve de sauvegardes et contraintes techniques.
Journaux techniques: durée limitée nécessaire au diagnostic et à la sécurité.
[À compléter si une politique précise existe]
10. Sécurité
Mesures de sécurité techniques et organisationnelles raisonnables sont mises en œuvre pour protéger les données (chiffrement au repos côté appareil via flutter_secure_storage pour secrets, communications réseau sécurisées, principe du moindre privilège).
[À compléter: politique interne, audits, pratiques de sauvegarde]
11. Vos droits
Selon la réglementation applicable (ex.: RGPD), vous disposez de droits d’accès, de rectification, d’effacement, de limitation, d’opposition, de portabilité.

Pour exercer vos droits: [À compléter – email/contact]
Preuve d’identité peut être requise.
Délai de réponse: sous 30 jours (ou selon la loi applicable).
12. Mineurs
[À compléter: politique d’âge cible (ex.: 13+), modalités spécifiques si l’app s’adresse aux enfants.]
13. Cookies et technologies similaires
L’application mobile ne recourt pas aux cookies de navigateur.
Des stockages locaux in-app (préférences, cache) sont utilisés pour le bon fonctionnement (non publicitaires).
14. Modifications de la politique
Nous pouvons mettre à jour la présente politique. La date de “Dernière mise à jour” en tête de document sera ajustée en conséquence.

15. Contact
Email de contact: [keamder.dev@gamil.com]

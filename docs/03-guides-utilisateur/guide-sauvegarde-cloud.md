# Guide utilisateur : Sauvegarde Cloud PaperClip2

Ce guide explique comment utiliser la fonctionnalité de sauvegarde cloud pour synchroniser vos mondes entre différents appareils.

## Vue d'ensemble

La sauvegarde cloud vous permet de :
- **Sauvegarder automatiquement** vos mondes dans le cloud
- **Récupérer vos mondes** sur un nouvel appareil
- **Jouer sur plusieurs appareils** avec synchronisation automatique
- **Protéger vos données** contre la perte de votre appareil

## Activation de la sauvegarde cloud

### Première connexion

1. Ouvrez l'écran des mondes (menu principal)
2. Connectez-vous avec votre compte Google Play Games ou Firebase
3. **La sauvegarde cloud s'active automatiquement** dès la connexion
4. Vos mondes existants seront automatiquement synchronisés

### Synchronisation automatique

Dès que vous êtes connecté :
- ✅ **Création de monde** : Chaque nouveau monde est automatiquement sauvegardé dans le cloud
- ✅ **Modifications** : Toutes vos modifications sont synchronisées automatiquement
- ✅ **Connexion** : À chaque connexion, vos mondes cloud sont récupérés automatiquement

## Limite de mondes

⚠️ **Important** : Vous pouvez créer jusqu'à **10 mondes maximum** par compte.

Si vous atteignez cette limite :
- Un message vous informera : *"Limite de 10 mondes atteinte. Supprimez un monde existant pour en créer un nouveau."*
- Vous devrez supprimer un monde existant avant d'en créer un nouveau
- Les mondes supprimés ne peuvent pas être récupérés (sauf via les backups locaux)

## États de synchronisation

Chaque monde affiche un badge indiquant son état de synchronisation :

### 🟢 Synchronisé
- Vos données locales et cloud sont identiques
- Aucune action requise
- Vous pouvez jouer en toute sécurité

### 🟡 En attente
- Une sauvegarde est en cours ou en attente
- Peut se produire si vous êtes hors ligne
- La synchronisation reprendra automatiquement dès la reconnexion

### 🔴 Erreur
- La dernière tentative de synchronisation a échoué
- Causes possibles : problème réseau, serveur indisponible, authentification expirée
- **Action** : Appuyez sur le bouton "Réessayer" pour relancer la synchronisation

### ☁️ Cloud uniquement
- Ce monde existe dans le cloud mais pas sur cet appareil
- **Action** : Appuyez sur "Télécharger" pour récupérer le monde localement

## Utilisation multi-appareils

### Scénario : Jouer sur plusieurs appareils

**Appareil 1 (téléphone)** :
1. Créez un monde "Ma Partie"
2. Jouez normalement
3. Le monde est automatiquement sauvegardé dans le cloud

**Appareil 2 (tablette)** :
1. Connectez-vous avec le même compte
2. Ouvrez l'écran des mondes
3. Votre monde "Ma Partie" apparaît automatiquement
4. Appuyez sur "Jouer" pour continuer votre partie

**Retour sur Appareil 1** :
- À la reconnexion, vos progrès de l'Appareil 2 sont automatiquement récupérés
- Le système choisit toujours la version la plus récente

## Actions disponibles

### Créer un nouveau monde
1. Appuyez sur le bouton "+" dans l'écran des mondes
2. Choisissez un nom et un mode de jeu
3. Le monde est créé localement ET dans le cloud (si connecté)

### Renommer un monde
1. Appuyez sur l'icône ✏️ à côté du nom du monde
2. Entrez le nouveau nom
3. Le changement est synchronisé automatiquement

### Supprimer un monde
1. Appuyez sur l'icône 🗑️
2. Confirmez la suppression
3. Le monde est supprimé localement ET dans le cloud

⚠️ **Attention** : La suppression est définitive (sauf backups locaux).

### Réessayer la synchronisation
Si un monde affiche l'état "Erreur" :
1. Vérifiez votre connexion internet
2. Appuyez sur le bouton "Réessayer"
3. Le système tentera de synchroniser à nouveau

### Télécharger un monde cloud
Si un monde affiche "Cloud uniquement" :
1. Appuyez sur le bouton "Télécharger"
2. Le monde est récupéré depuis le cloud
3. Vous pouvez maintenant y jouer localement

## Résolution de problèmes

### "Erreur de synchronisation"
**Causes possibles** :
- Pas de connexion internet
- Serveur temporairement indisponible
- Authentification expirée

**Solutions** :
1. Vérifiez votre connexion internet
2. Attendez quelques minutes et réessayez
3. Déconnectez-vous et reconnectez-vous
4. Si le problème persiste, contactez le support

### "Limite de mondes atteinte"
**Solution** :
- Supprimez un monde existant que vous n'utilisez plus
- Vous pourrez alors créer un nouveau monde

### "Monde introuvable"
**Causes possibles** :
- Le monde a été supprimé sur un autre appareil
- Problème de synchronisation

**Solutions** :
1. Rafraîchissez la liste des mondes (tirez vers le bas)
2. Vérifiez que vous êtes connecté avec le bon compte
3. Si le monde existe localement, utilisez "Réessayer" pour le pousser au cloud

## Sécurité et confidentialité

### Authentification
- Vos mondes sont protégés par votre compte Google Play Games ou Firebase
- Seul vous pouvez accéder à vos mondes
- Personne d'autre ne peut voir ou modifier vos sauvegardes

### Stockage des données
- Vos données sont stockées dans Firebase Firestore (Google Cloud)
- Les données sont chiffrées en transit (HTTPS)
- Conformité RGPD et protection des données personnelles

### Déconnexion
Si vous vous déconnectez :
- Vos mondes locaux restent accessibles
- La synchronisation cloud est désactivée
- Vous pouvez continuer à jouer hors ligne

## FAQ

**Q : Mes mondes sont-ils sauvegardés automatiquement ?**  
R : Oui, si vous êtes connecté, tous vos mondes sont automatiquement sauvegardés dans le cloud à chaque modification.

**Q : Puis-je jouer hors ligne ?**  
R : Oui, vous pouvez jouer hors ligne. Vos modifications seront synchronisées automatiquement dès que vous serez reconnecté.

**Q : Que se passe-t-il si je modifie un monde sur deux appareils en même temps ?**  
R : Le système choisit automatiquement la version la plus récente. Si vous modifiez le même monde sur deux appareils hors ligne, la dernière synchronisation gagnera.

**Q : Puis-je récupérer un monde supprimé ?**  
R : Non, la suppression est définitive dans le cloud. Cependant, des backups locaux peuvent exister sur votre appareil.

**Q : Combien de temps mes mondes sont-ils conservés dans le cloud ?**  
R : Vos mondes sont conservés indéfiniment tant que votre compte est actif.

**Q : Puis-je partager un monde avec un ami ?**  
R : Non, actuellement le partage de mondes n'est pas supporté. Chaque monde est lié à un compte utilisateur unique.

## Support

Si vous rencontrez un problème non résolu par ce guide :
1. Vérifiez les logs dans les paramètres de l'application
2. Notez le message d'erreur exact
3. Contactez le support avec ces informations

---

**Version du guide** : 1.0 (Janvier 2026)  
**Dernière mise à jour** : Après implémentation de la limite de 10 mondes et synchronisation automatique au login.

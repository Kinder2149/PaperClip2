# 🔐 SYSTÈME DE PERSISTANCE CLOUD

**Projet** : PaperClip2  
**Date** : 15 janvier 2026  
**Dernière mise à jour** : 20 janvier 2026  
**Statut** : ✅ Production

---

## 🎯 ARCHITECTURE CLOUD-FIRST

### Principe fondamental
**Cloud-first strict** : Toutes les parties sont disponibles au login, push automatique vers le cloud, local = cache temporaire.

### Identité unique
- **partieId** : UUID v4 unique généré à la création
- Aucune clé métier basée sur le nom
- Une partie = un partieId

---

## 📊 FLUX DE SYNCHRONISATION

### Création d'un monde
```
1. Utilisateur crée "test 1"
   ↓
2. UUID généré : f4edf80a-139e-48b0-a32b-b4902a0ccdf5
   ↓
3. Sauvegarde locale (LocalSaveGameManager)
   ↓
4. Push cloud automatique (si cloud_enabled = true)
   ↓
5. Données dans Firestore : players/<uid>/saves/<partieId>
```

### Après réinstallation
```
1. Utilisateur se connecte
   ↓
2. Cloud sync activé automatiquement
   ↓
3. Pull automatique des mondes cloud
   ↓
4. Affichage dans la liste des mondes
```

---

## 🔧 COMPOSANTS TECHNIQUES

### LocalSaveGameManager
Gestion des sauvegardes locales (SharedPreferences)

### GamePersistenceOrchestrator
Orchestration sauvegarde + cloud sync

### CloudPersistenceAdapter
Communication HTTP avec le backend

### SavesFacade
API unifiée pour l'UI

---

## 📝 CONFIGURATION

### Activation cloud sync
```dart
// lib/main.dart ligne 253
if (user != null) {
  await facade.setCloudEnabled(true);
}
```

### URL API
```env
# Production (déployée le 20 janvier 2026)
FUNCTIONS_API_BASE=https://api-g3tpwosnaq-uc.a.run.app
```

---

## ✅ VALIDATION

- [x] UUID unique pour chaque monde
- [x] Push automatique vers cloud
- [x] Pull automatique au login
- [x] Persistance après réinstallation
- [x] Retry automatique en cas d'échec
- [x] Logs détaillés pour debug

---

**Voir aussi** :
- `guide-persistance.md` - Guide développeur
- `guide-cloud-sync.md` - Synchronisation cloud
- `architecture-globale.md` - Vue d'ensemble

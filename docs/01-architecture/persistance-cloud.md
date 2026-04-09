# 🔐 SYSTÈME DE PERSISTANCE CLOUD

**Projet** : PaperClip2  
**Date** : 15 janvier 2026  
**Dernière mise à jour** : 20 janvier 2026  
**Statut** : ✅ Production

---

## 🎯 ARCHITECTURE ENTREPRISE UNIQUE

### Principe fondamental
**Entreprise unique** : 1 utilisateur = 1 entreprise persistante, synchronisation cloud automatique.

### Identité unique
- **enterpriseId** : UUID v4 unique généré à la création de l'entreprise
- Identité technique immuable (ne change jamais)
- Stockée dans `snapshot.metadata.enterpriseId`
- 1 utilisateur = 1 entreprise (pas de multi-save)

---

## 📊 FLUX DE SYNCHRONISATION

### Création d'une entreprise
```
1. Utilisateur crée "Mon Entreprise"
   ↓
2. UUID généré : f4edf80a-139e-48b0-a32b-b4902a0ccdf5
   ↓
3. Sauvegarde locale (LocalSaveGameManager)
   ↓
4. Push cloud automatique (si Firebase connecté)
   ↓
5. Données dans Firestore : enterprises/<uid>
```

### Synchronisation au login
```
1. Utilisateur se connecte avec Firebase
   ↓
2. Stratégie "cloud always wins"
   ↓
3. Si cloud existe → Pull et écrase local
   ↓
4. Si cloud n'existe pas → Push local vers cloud
   ↓
5. Chargement entreprise dans MainScreen
```

---

## 🔧 COMPOSANTS TECHNIQUES

### LocalSaveGameManager
Gestion des sauvegardes locales (SharedPreferences)

### GamePersistenceOrchestrator
Orchestration sauvegarde + cloud sync

### CloudPersistenceAdapter
Communication HTTP avec `/enterprise/{uid}`

---

## 📝 CONFIGURATION

### Endpoint API
```
GET  /enterprise/{uid}  → Récupérer l'entreprise
PUT  /enterprise/{uid}  → Sauvegarder l'entreprise
DELETE /enterprise/{uid} → Supprimer l'entreprise (testeurs)
```

### URL API
```env
# Production (déployée le 20 janvier 2026)
FUNCTIONS_API_BASE=https://api-g3tpwosnaq-uc.a.run.app
```

---

## ✅ VALIDATION

- [x] UUID v4 unique pour l'entreprise
- [x] Push automatique vers cloud
- [x] Sync "cloud always wins" au login
- [x] Persistance après réinstallation
- [x] Retry automatique (backoff exponentiel: 1s, 2s, 4s)
- [x] Logs détaillés pour debug
- [x] Format snapshot v3 avec `metadata.enterpriseId`

---

**Voir aussi** :
- `architecture-globale.md` - Vue d'ensemble
- `ENTREPRISE-UNIQUE.md` - Référence entreprise unique
- `../02-guides-developpeur/GUIDE_COMPLET_SAUVEGARDE_CLOUD.md` - Guide complet

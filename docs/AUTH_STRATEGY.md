# Stratégie d'Authentification - PaperClip2
**Date**: 20 janvier 2026  
**Décision**: Option A - Firebase comme Source Unique

---

## 🎯 Principe Directeur

**Firebase Auth est la source unique de vérité pour l'état d'authentification.**

Google Play Games Services (GPG) est utilisé **uniquement** pour les données cosmétiques (avatar, displayName) et les fonctionnalités sociales (leaderboards, achievements).

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTHENTIFICATION                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Firebase Auth (SOURCE DE VÉRITÉ)             │  │
│  │  • État connecté/déconnecté                          │  │
│  │  • Token JWT pour backend API                        │  │
│  │  • UID utilisateur (identité canonique)              │  │
│  │  • Email utilisateur                                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↓                                 │
│                   Déclenche au login                         │
│                            ↓                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │    Google Play Games (DONNÉES COSMÉTIQUES)           │  │
│  │  • Avatar URL (optionnel)                            │  │
│  │  • Display Name (optionnel)                          │  │
│  │  • Player ID (social uniquement)                     │  │
│  │  • Leaderboards / Achievements                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Règles d'Implémentation

### Règle 1 : Vérification d'État
**Toujours utiliser Firebase pour vérifier si l'utilisateur est connecté.**

```dart
// ✅ CORRECT
final user = FirebaseAuthService.instance.currentUser;
if (user != null) {
  // Utilisateur connecté
}

// ❌ INCORRECT
final google = context.read<GoogleServicesBundle>();
if (google.identity.status == IdentityStatus.authenticated) {
  // Ne pas utiliser GPG pour vérifier l'état connecté
}
```

### Règle 2 : Affichage des Données
**Utiliser GPG pour les données cosmétiques avec fallback sur Firebase.**

```dart
// ✅ CORRECT
final user = FirebaseAuthService.instance.currentUser;
final google = context.watch<GoogleServicesBundle>();

final displayName = google.identity.displayName  // Priorité GPG
    ?? user?.email?.split('@').first             // Fallback Firebase
    ?? 'Utilisateur';                            // Fallback par défaut

final avatarUrl = google.identity.avatarUrl;     // Peut être null
```

### Règle 3 : Flux de Connexion
**Connexion Firebase déclenche tentative GPG (best effort).**

```dart
// ✅ CORRECT
Future<void> signIn() async {
  // 1. Connexion Firebase (OBLIGATOIRE)
  await FirebaseAuthService.instance.signInWithGoogle();
  
  // 2. Tentative GPG (OPTIONNEL, best effort)
  try {
    final google = context.read<GoogleServicesBundle>();
    await google.identity.signIn();
  } catch (e) {
    // Échec GPG non bloquant
    Logger.warn('GPG sign-in failed (non-blocking): $e');
  }
}
```

### Règle 4 : Flux de Déconnexion
**Déconnexion Firebase + GPG (best effort).**

```dart
// ✅ CORRECT
Future<void> signOut() async {
  // 1. Déconnexion Firebase
  await FirebaseAuthService.instance.signOut();
  
  // 2. Déconnexion GPG (best effort)
  try {
    final google = context.read<GoogleServicesBundle>();
    await google.identity.signOut();
  } catch (e) {
    // Échec GPG non bloquant
    Logger.warn('GPG sign-out failed (non-blocking): $e');
  }
}
```

### Règle 5 : Gestion des Cas Limites
**Gérer explicitement le cas Firebase OK mais GPG KO.**

```dart
// ✅ CORRECT
Widget build(BuildContext context) {
  final user = FirebaseAuthService.instance.currentUser;
  final google = context.watch<GoogleServicesBundle>();
  
  if (user == null) {
    return SignInButton();
  }
  
  // Utilisateur connecté Firebase
  final isGpgReady = google.identity.status == IdentityStatus.authenticated;
  
  return AccountInfo(
    displayName: isGpgReady 
        ? google.identity.displayName 
        : user.email?.split('@').first ?? 'Utilisateur',
    avatarUrl: isGpgReady ? google.identity.avatarUrl : null,
    showGpgBadge: !isGpgReady, // Badge "Profil incomplet"
  );
}
```

---

## 🔄 Flux Complets

### Flux de Connexion
```
1. Utilisateur clique "Se connecter"
   ↓
2. FirebaseAuthService.signInWithGoogle()
   ↓
3. Firebase Auth réussie → Token JWT obtenu
   ↓
4. Tentative GoogleIdentityService.signIn() (best effort)
   ↓
5a. GPG réussie → Avatar/DisplayName disponibles
5b. GPG échouée → Fallback sur email Firebase
   ↓
6. UI mise à jour (StreamBuilder sur Firebase)
   ↓
7. Synchronisation cloud déclenchée (onPlayerConnected)
```

### Flux de Déconnexion
```
1. Utilisateur clique "Se déconnecter"
   ↓
2. FirebaseAuthService.signOut()
   ↓
3. Tentative GoogleIdentityService.signOut() (best effort)
   ↓
4. UI mise à jour (StreamBuilder sur Firebase)
   ↓
5. État local nettoyé
```

---

## 📱 Implémentation par Composant

### `AccountInfoCard`
**Responsabilité** : Afficher les informations du compte connecté

```dart
// Source de vérité : Firebase
StreamBuilder(
  stream: FirebaseAuthService.instance.authStateChanges(),
  builder: (context, snapshot) {
    final user = FirebaseAuthService.instance.currentUser;
    
    if (user == null) {
      return _buildSignInButton(); // Bouton "Se connecter"
    }
    
    return _buildAccountInfo(user); // Infos compte (avec GPG si dispo)
  },
)
```

### `StartScreen`
**Responsabilité** : Menu principal avec gestion connexion

```dart
Future<void> _onAccountButtonPressed() async {
  final user = FirebaseAuthService.instance.currentUser;
  
  if (user == null) {
    // Pas connecté → Connexion Firebase + GPG
    await _signIn();
  } else {
    // Déjà connecté → Menu utilisateur
    _showAccountMenu();
  }
}
```

### `WorldsScreen`
**Responsabilité** : Liste des mondes avec sync cloud

```dart
// Vérification Firebase pour sync cloud
final user = FirebaseAuthService.instance.currentUser;
if (user != null) {
  await GamePersistenceOrchestrator.instance
      .syncAllWorldsFromCloud(playerId: user.uid);
}
```

---

## 🚫 Anti-Patterns à Éviter

### ❌ Anti-Pattern 1 : Vérifier GPG pour l'état connecté
```dart
// ❌ NE PAS FAIRE
final google = context.read<GoogleServicesBundle>();
if (google.identity.status == IdentityStatus.authenticated) {
  // Logique métier basée sur GPG
}
```

### ❌ Anti-Pattern 2 : Bloquer sur échec GPG
```dart
// ❌ NE PAS FAIRE
await FirebaseAuthService.instance.signInWithGoogle();
await google.identity.signIn(); // Peut échouer et bloquer

// ✅ FAIRE
await FirebaseAuthService.instance.signInWithGoogle();
try {
  await google.identity.signIn();
} catch (e) {
  // Non bloquant
}
```

### ❌ Anti-Pattern 3 : Utiliser Player ID pour le backend
```dart
// ❌ NE PAS FAIRE
final playerId = google.identity.playerId;
await api.saveWorld(playerId: playerId);

// ✅ FAIRE
final uid = FirebaseAuthService.instance.currentUser?.uid;
await api.saveWorld(playerId: uid);
```

---

## 🔍 Identités dans le Projet

| Identité | Source | Usage | Obligatoire |
|----------|--------|-------|-------------|
| **Firebase UID** | Firebase Auth | Backend API, Cloud sync | ✅ Oui |
| **Email** | Firebase Auth | Fallback displayName | ✅ Oui |
| **Player ID** | Google Play Games | Social, Leaderboards | ❌ Non |
| **Display Name** | Google Play Games | UI cosmétique | ❌ Non |
| **Avatar URL** | Google Play Games | UI cosmétique | ❌ Non |
| **Partie ID (UUID)** | Généré localement | Identité monde | ✅ Oui |

---

## 📊 Matrice de Décision

| Situation | Firebase | GPG | Action |
|-----------|----------|-----|--------|
| Utilisateur non connecté | ❌ | ❌ | Afficher bouton "Se connecter" |
| Firebase OK, GPG OK | ✅ | ✅ | Afficher infos complètes (avatar + nom) |
| Firebase OK, GPG KO | ✅ | ❌ | Afficher infos Firebase (email) + badge |
| Firebase KO, GPG OK | ❌ | ✅ | **Impossible** (GPG dépend de Firebase) |

---

## 🧪 Tests de Validation

### Test 1 : Connexion Firebase Seule
```
1. Connexion Firebase réussie
2. GPG échoue (simulé)
3. ✅ UI affiche email Firebase
4. ✅ Badge "Profil incomplet" visible
5. ✅ Sync cloud fonctionne (Firebase UID)
```

### Test 2 : Connexion Firebase + GPG
```
1. Connexion Firebase réussie
2. GPG réussie
3. ✅ UI affiche avatar + displayName GPG
4. ✅ Pas de badge "Profil incomplet"
5. ✅ Sync cloud fonctionne (Firebase UID)
```

### Test 3 : Déconnexion
```
1. Déconnexion Firebase
2. GPG déconnecté (best effort)
3. ✅ UI revient à "Se connecter"
4. ✅ État local nettoyé
```

---

## 📝 Messages Utilisateur

### Connexion Réussie
```
✅ "Connecté avec succès"
```

### Connexion Firebase OK, GPG KO
```
ℹ️ "Connecté (profil Google Play non disponible)"
```

### Échec Connexion
```
❌ "Connexion échouée : [raison simplifiée]"
```

### Déconnexion
```
ℹ️ "Déconnecté"
```

---

## 🔗 Fichiers Concernés

### Priorité Haute (Modifiés)
- `lib/widgets/google/account_info_card.dart`
- `lib/screens/start_screen.dart`
- `lib/services/auth/firebase_auth_service.dart`

### Priorité Moyenne (Vérifiés)
- `lib/screens/worlds_screen.dart`
- `lib/screens/google_profile_screen.dart`
- `lib/widgets/google/google_account_button.dart`

### Priorité Basse (Documentation)
- `lib/services/google/identity/google_identity_service.dart`
- `lib/services/google/google_bootstrap.dart`

---

## 📚 Références

- **Firebase Auth** : Source de vérité pour l'état connecté
- **Google Play Games** : Données cosmétiques et fonctionnalités sociales
- **Backend API** : Utilise Firebase UID uniquement
- **Cloud Sync** : Déclenché par Firebase authStateChanges

---

**Cette stratégie garantit une cohérence totale de l'authentification dans l'application.**

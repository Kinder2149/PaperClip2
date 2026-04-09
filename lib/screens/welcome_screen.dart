// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/runtime/runtime_actions.dart';
import 'main_screen.dart';
import 'profile_screen.dart';
import '../services/google/google_bootstrap.dart';
import '../services/auth/firebase_auth_service.dart';
import '../utils/logger.dart';

/// Écran d'accueil affiché uniquement lors de la première utilisation
/// (quand aucune entreprise n'existe)
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final Logger _logger = Logger.forComponent('ui-welcome');
  final TextEditingController _enterpriseNameController = TextEditingController();
  String? _enterpriseNameError;
  bool _isCreating = false;

  @override
  void dispose() {
    _enterpriseNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateEnterprise() async {
    final name = _enterpriseNameController.text.trim();
    
    // Validation du nom
    if (name.isEmpty) {
      setState(() {
        _enterpriseNameError = "Veuillez entrer un nom pour votre entreprise";
      });
      return;
    }
    
    if (name.length < 3) {
      setState(() {
        _enterpriseNameError = "Le nom doit contenir au moins 3 caractères";
      });
      return;
    }
    
    if (name.length > 30) {
      setState(() {
        _enterpriseNameError = "Le nom ne peut pas dépasser 30 caractères";
      });
      return;
    }
    
    final validChars = RegExp(r"^[a-zA-Z0-9\s\-_.\']+$");
    if (!validChars.hasMatch(name)) {
      setState(() {
        _enterpriseNameError = "Le nom contient des caractères non autorisés";
      });
      return;
    }
    
    // Création de l'entreprise
    setState(() {
      _isCreating = true;
      _enterpriseNameError = null;
    });
    
    try {
      final runtimeActions = context.read<RuntimeActions>();
      await runtimeActions.createNewEnterpriseAndStartAutoSave(name);
      runtimeActions.startSession();
      
      if (!mounted) return;
      
      // Navigation vers le jeu principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (kDebugMode) _logger.debug('Erreur création entreprise: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isCreating = false;
        _enterpriseNameError = "Erreur lors de la création de l'entreprise";
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      if (kDebugMode) _logger.debug('[WelcomeScreen] Connexion Google demandée');
      
      // Connexion Firebase
      await FirebaseAuthService.instance.signInWithGoogle();
      
      // Tentative GPG (best effort)
      try {
        final google = context.read<GoogleServicesBundle>();
        await google.identity.signIn();
        if (kDebugMode) _logger.debug('[WelcomeScreen] GPG connecté avec succès');
      } catch (e) {
        if (kDebugMode) _logger.debug('[WelcomeScreen] GPG échec (non bloquant): $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecté avec succès'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion échouée: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple[900]!,
              Colors.deepPurple[700]!,
              Colors.purple[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Icon(
                  Icons.business,
                  size: 100,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 40),
                
                // Titre
                Text(
                  "BIENVENUE",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Sous-titre
                Text(
                  "Créez votre empire de trombones",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                
                // Champ de saisie du nom d'entreprise
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _enterpriseNameController,
                    enabled: !_isCreating,
                    decoration: InputDecoration(
                      hintText: "Nom de votre entreprise",
                      border: InputBorder.none,
                      errorText: _enterpriseNameError,
                      prefixIcon: const Icon(Icons.business_center),
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      if (_enterpriseNameError != null) {
                        setState(() {
                          _enterpriseNameError = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _handleCreateEnterprise(),
                  ),
                ),
                const SizedBox(height: 15),
                
                // Exemples
                Text(
                  "Exemples : PaperClip Corp, TromboTech, ClipMaster Inc.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Bouton Créer l'entreprise
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _handleCreateEnterprise,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: Colors.deepPurple[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'CRÉER MON ENTREPRISE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Séparateur
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OU",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Bouton Google Dynamique (Connexion ou Profil)
                StreamBuilder(
                  stream: FirebaseAuthService.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final isConnected = FirebaseAuthService.instance.currentUser != null;
                    final googleIdentity = context.watch<GoogleServicesBundle>().identity;
                    final avatarUrl = googleIdentity.avatarUrl;
                    
                    if (isConnected) {
                      // Bouton "Mon Profil" avec avatar
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isCreating ? null : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: Colors.deepPurple[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Avatar miniature
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.deepPurple[100],
                                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null || avatarUrl.isEmpty
                                    ? Icon(Icons.person, size: 16, color: Colors.deepPurple[900])
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'MON PROFIL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Bouton "Se connecter avec Google"
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isCreating ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: const Text(
                            'SE CONNECTER AVEC GOOGLE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                
                // Note dynamique
                StreamBuilder(
                  stream: FirebaseAuthService.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final isConnected = FirebaseAuthService.instance.currentUser != null;
                    
                    return Text(
                      isConnected
                          ? "Accédez à votre profil pour gérer votre compte"
                          : "La connexion Google n'est pas obligatoire\npour commencer à jouer",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

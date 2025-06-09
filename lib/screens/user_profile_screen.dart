import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user/user_manager.dart';
import '../services/user/user_profile.dart';
import '../services/user/google_auth_service.dart';
import '../services/file/file_service.dart'; // Import du FileService
import '../widgets/resource_widgets.dart';
import '../models/game_config.dart'; // Ajout de l'import pour GameMode
import '../widgets/app_bar/widget_appbar_jeu.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late UserManager _userManager;
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Obtenez l'instance au lieu d'en créer une nouvelle
    _userManager = Provider.of<UserManager>(context, listen: false);
    _userManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utilisation du widget AppBar personnalisé
      appBar: WidgetAppBarJeu(
        titleBuilder: (context) => const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        showLevelIndicator: false,
        onSettingsPressed: () {
          // Action pour le bouton paramètres
        },
      ),
      body: ValueListenableBuilder<UserProfile?>(
        valueListenable: _userManager.profileChanged,
        builder: (context, profile, child) {
          if (profile == null) {
            return _buildCreateProfileForm();
          } else {
            return _buildProfileDetails(profile);
          }
        },
      ),
    );
  }

  Widget _buildCreateProfileForm() {
    final TextEditingController nameController = TextEditingController();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Créer votre profil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'affichage',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _createProfile(nameController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Créer mon profil',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _createWithGoogle(),
                  icon: const Icon(Icons.g_mobiledata), // Remplacé par une icône standard car Google logo peut ne pas être dans les assets
                  label: const Text('Continuer avec Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetails(UserProfile profile) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Photo de profil
            GestureDetector(
              onTap: () => _pickProfileImage(),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: _getProfileImage(profile),
                child: profile.profileImagePath == null && profile.profileImageUrl == null
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez pour changer la photo',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Nom du profil
            Text(
              profile.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            // Statut de connexion Google
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: profile.googleId != null ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    profile.googleId != null ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: profile.googleId != null ? Colors.green[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile.googleId != null
                        ? 'Connecté à Google'
                        : 'Non connecté à Google',
                    style: TextStyle(
                      color: profile.googleId != null ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Statistiques du profil
            _buildStatisticsCard(profile),

            const SizedBox(height: 24),

            // Lier à Google
            if (profile.googleId == null)
              ElevatedButton.icon(
                onPressed: () => _linkToGoogle(),
                icon: const Icon(Icons.g_mobiledata), // Remplacé par une icône standard
                label: const Text('Lier à Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

            const SizedBox(height: 16),

            // Synchroniser
            if (profile.googleId != null)
              OutlinedButton.icon(
                onPressed: () => _syncWithCloud(),
                icon: const Icon(Icons.sync),
                label: const Text('Synchroniser avec le cloud'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(UserProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Globales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            _buildStatRow(
              'Parties créées',
              (profile.infiniteSaveIds.length + profile.competitiveSaveIds.length).toString(),
            ),
            _buildStatRow(
              'Parties compétitives',
              '${profile.competitiveSaveIds.length}/3',
            ),
            _buildStatRow(
              'Parties infinies',
              profile.infiniteSaveIds.length.toString(),
            ),
            _buildStatRow(
              'Meilleur score',
              profile.globalStats['bestScore']?.toString() ?? '0',
            ),
            _buildStatRow(
              'Total trombones',
              _formatNumber(profile.globalStats['totalPaperclips'] ?? 0),
            ),
            _buildStatRow(
              'Argent gagné',
              _formatMoney(profile.globalStats['totalMoney'] ?? 0),
            ),
            _buildStatRow(
              'Niveau max atteint',
              profile.globalStats['maxLevel']?.toString() ?? '1',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Formatage des nombres
  String _formatNumber(dynamic value) {
    if (value is int && value > 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value is int && value > 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  // Formatage monétaire
  String _formatMoney(dynamic value) {
    return '\$${_formatNumber(value)}';
  }

  // Récupérer l'image de profil
  ImageProvider? _getProfileImage(UserProfile profile) {
    if (profile.profileImageUrl != null) {
      return NetworkImage(profile.profileImageUrl!);
    } else if (profile.profileImagePath != null) {
      return FileImage(File(profile.profileImagePath!));
    }
    return null;
  }

  // Actions
  Future<void> _createProfile(String name) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userManager.createProfile(name);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // signInWithGoogle retourne un bool indiquant le succès de l'authentification
      final success = await _authService.signInWithGoogle();
      if (success == true) {
        await _userManager.createProfile(_authService.username ?? 'Joueur Google', isOAuthUser: true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _linkToGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userManager.linkProfileToGoogle();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil lié à Google avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWithCloud() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userManager.syncWithCloud();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synchronisation réussie'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Utilise le FileService pour sélectionner une image de profil
  Future<void> _pickProfileImage() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Utiliser le FileService pour choisir une image
      final imagePath = await FileService.pickSingleFile(
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        dialogTitle: 'Choisir une image de profil',
      );
      
      if (imagePath != null) {
        // Convertir le chemin de fichier en objet File
        final File imageFile = File(imagePath);
        
        // Utiliser le UserManager pour uploader l'image
        await _userManager.uploadProfileImage(imageFile);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image de profil mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
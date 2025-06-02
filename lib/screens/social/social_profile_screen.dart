// lib/screens/social/social_profile_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../services/user/user_manager.dart';
import '../../services/user/user_profile.dart';
import '../../models/game_config.dart';
import '../../widgets/app_bar/widget_appbar_jeu.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../../models/game_config.dart';

class SocialProfileScreen extends StatefulWidget {
  const SocialProfileScreen({Key? key}) : super(key: key);

  @override
  State<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  bool _isLoading = false;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  UserProfile? _currentProfile;

  // Liste pour stocker les avatars prédéfinis
  List<String> _predefineAvatars = [];
  // Option de l'avatar sélectionné
  String? _selectedPredefinedAvatar;
  // Pour l'affichage de l'avatar sélectionné
  bool _isUsingPredefinedAvatar = false;


  // Options de visibilité
  bool _isProfilePublic = true;
  Map<String, dynamic> _privacySettings = {
    'showTotalPaperclips': true,
    'showLevel': true,
    'showMoney': true,
    'showEfficiency': true,
    'showUpgrades': true,
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPredefinedAvatars();
  }


  // Méthode pour charger la liste des avatars prédéfinis
  Future<void> _loadPredefinedAvatars() async {
    try {
      // Obtenir la liste des assets dans le dossier profile_avatars
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Filtrer les assets pour ne garder que les avatars
      final avatarPaths = manifestMap.keys
          .where((String key) => key.contains('assets/profile_avatars/'))
          .toList();

      setState(() {
        _predefineAvatars = avatarPaths;
      });

      debugPrint('Avatars chargés: ${_predefineAvatars.length}');
    } catch (e) {
      debugPrint('Erreur lors du chargement des avatars: $e');
    }
  }


  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      _currentProfile = userManager.currentProfile;

      if (_currentProfile != null) {
        _displayNameController.text = _currentProfile!.displayName;
        _userIdController.text = _currentProfile!.userId;

        setState(() {
          // Vérifier la présence des clés avant d'y accéder
          if (_currentProfile!.privacySettings.containsKey('isPublic')) {
            _isProfilePublic = _currentProfile!.privacySettings['isPublic'] as bool? ?? true;
          } else {
            _isProfilePublic = true; // Valeur par défaut
          }

          // Vérifier si l'utilisateur utilise un avatar prédéfini
          if (_currentProfile!.customAvatarPath != null &&
              _currentProfile!.customAvatarPath!.startsWith('assets/profile_avatars/')) {
            _selectedPredefinedAvatar = _currentProfile!.customAvatarPath;
            _isUsingPredefinedAvatar = true;
          }

          // Charger les paramètres de confidentialité existants
          if (_currentProfile!.privacySettings.isNotEmpty) {
            _privacySettings = Map<String, dynamic>.from(_currentProfile!.privacySettings);
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _saveProfileChanges() async {
    if (_currentProfile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);

      // Créer une copie mise à jour du profil
      final updatedProfile = _currentProfile!.copyWith(
        displayName: _displayNameController.text,
        customAvatarPath: _isUsingPredefinedAvatar ? _selectedPredefinedAvatar : null,
        privacySettings: {
          ..._privacySettings,
          'isPublic': _isProfilePublic,
        },
      );

      // Mettre à jour le profil
      await userManager.updateProfileObject(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Méthode pour télécharger une image depuis un fichier
  Future<void> _uploadProfileImageFromFile(File imageFile) async {
    if (_currentProfile == null) return;

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      await userManager.uploadProfileImage(imageFile);

      // Rafraîchir l'interface
      setState(() {
        _isUsingPredefinedAvatar = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Méthode pour sélectionner une image de la galerie
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _isUsingPredefinedAvatar = false;
          _selectedPredefinedAvatar = null;
        });
        await _uploadProfileImageFromFile(File(image.path));
      }
    } catch (e) {
      debugPrint('Erreur lors de la sélection d\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Méthode pour capturer une photo avec la caméra
  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _isUsingPredefinedAvatar = false;
          _selectedPredefinedAvatar = null;
        });
        await _uploadProfileImageFromFile(File(image.path));
      }
    } catch (e) {
      debugPrint('Erreur lors de la capture d\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Méthode pour afficher la galerie d'avatars prédéfinis
  void _showAvatarPicker() {
    if (_predefineAvatars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun avatar prédéfini trouvé'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un avatar'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _predefineAvatars.length,
            itemBuilder: (context, index) {
              final avatarPath = _predefineAvatars[index];
              final isSelected = avatarPath == _selectedPredefinedAvatar;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPredefinedAvatar = avatarPath;
                    _isUsingPredefinedAvatar = true;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      avatarPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
  // Méthode pour afficher la boîte de dialogue des options de photo
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Changer de photo de profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.deepPurple),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.face, color: Colors.deepPurple),
                title: const Text('Choisir un avatar prédéfini'),
                onTap: () {
                  Navigator.pop(context);
                  _showAvatarPicker();
                },
              ),
              if (_currentProfile?.profileImageUrl != null ||
                  _currentProfile?.profileImagePath != null ||
                  _isUsingPredefinedAvatar)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Supprimer la photo actuelle'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

// Méthode pour supprimer l'image de profil
  Future<void> _removeProfileImage() async {
    if (_currentProfile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);

      // Créer une copie mise à jour du profil sans image
      final updatedProfile = _currentProfile!.copyWith(
        profileImagePath: null,
        profileImageUrl: null,
        customAvatarPath: null,
      );

      // Mettre à jour le profil
      await userManager.updateProfileObject(updatedProfile);

      setState(() {
        _isUsingPredefinedAvatar = false;
        _selectedPredefinedAvatar = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  Future<void> _uploadProfileImage() async {
    if (_currentProfile == null) return;

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      await userManager.uploadProfileImage(null);

      // Rafraîchir l'interface
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_currentProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Profil non disponible'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildProfileForm(),
          const SizedBox(height: 24),
          _buildPrivacySettings(),
          const SizedBox(height: 24),
          _buildStatsPreview(),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _saveProfileChanges,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer les modifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImage() == null
                        ? Text(
                      _currentProfile!.displayName.isNotEmpty
                          ? _currentProfile!.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez pour changer de photo',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            _buildConnectionStatus(),
          ],
        ),
      ),
    );
  }
  Widget _buildConnectionStatus() {
    final isConnectedToGoogle = _currentProfile!.googleId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isConnectedToGoogle ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnectedToGoogle ? Icons.check_circle : Icons.warning,
            color: isConnectedToGoogle ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isConnectedToGoogle
                ? 'Connecté à Google Play'
                : 'Non connecté à Google Play',
            style: TextStyle(
              color: isConnectedToGoogle ? Colors.green.shade800 : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
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
              'Informations du profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'affichage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userIdController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'ID Utilisateur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fingerprint),
                helperText: 'Cet identifiant unique ne peut pas être modifié',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Profil public',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isProfilePublic,
                  onChanged: (value) {
                    setState(() {
                      _isProfilePublic = value;
                    });
                  },
                  activeColor: Colors.deepPurple,
                ),
                const Spacer(),
                Tooltip(
                  message: 'Un profil public peut être trouvé par tous les joueurs',
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
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
              'Paramètres de confidentialité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisissez quelles statistiques seront visibles par vos amis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildPrivacySwitch(
              'Afficher le nombre de trombones',
              'showTotalPaperclips',
              Icons.construction,
            ),
            _buildPrivacySwitch(
              'Afficher le niveau',
              'showLevel',
              Icons.trending_up,
            ),
            _buildPrivacySwitch(
              'Afficher l\'argent',
              'showMoney',
              Icons.attach_money,
            ),
            _buildPrivacySwitch(
              'Afficher l\'efficacité',
              'showEfficiency',
              Icons.speed,
            ),
            _buildPrivacySwitch(
              'Afficher les améliorations',
              'showUpgrades',
              Icons.upgrade,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySwitch(String label, String key, IconData icon) {
    // Vérifier si la clé existe avant d'y accéder
    final isEnabled = _privacySettings.containsKey(key)
        ? (_privacySettings[key] as bool?) ?? true
        : true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple.shade300),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                _privacySettings[key] = value;
              });
            },
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPreview() {
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
              'Aperçu du profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Voici comment votre profil apparaîtra aux autres joueurs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.deepPurple.shade100,
                        backgroundImage: _getProfileImage(),
                        child: _getProfileImage() == null
                            ? Text(
                          _currentProfile!.displayName.isNotEmpty
                              ? _currentProfile!.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayNameController.text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isProfilePublic ? 'Profil public' : 'Profil privé',
                              style: TextStyle(
                                fontSize: 14,
                                color: _isProfilePublic ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Statistiques visibles:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildVisibleStatPreview(
                    'Trombones produits: 1,234',
                    Icons.construction,
                    'showTotalPaperclips',
                  ),
                  _buildVisibleStatPreview(
                    'Niveau: 5',
                    Icons.trending_up,
                    'showLevel',
                  ),
                  _buildVisibleStatPreview(
                    'Argent: 9,876 euros',
                    Icons.attach_money,
                    'showMoney',
                  ),
                  _buildVisibleStatPreview(
                    'Efficacité: 85%',
                    Icons.speed,
                    'showEfficiency',
                  ),
                  _buildVisibleStatPreview(
                    'Améliorations: 7',
                    Icons.upgrade,
                    'showUpgrades',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibleStatPreview(String text, IconData icon, String settingKey) {
    // Vérifier si la clé existe avant d'y accéder
    final isVisible = _privacySettings.containsKey(settingKey)
        ? (_privacySettings[settingKey] as bool?) ?? true
        : true;

    return Opacity(
      opacity: isVisible ? 1.0 : 0.3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(text),
            const Spacer(),
            Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              size: 16,
              color: isVisible ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    // Si un avatar prédéfini est sélectionné, l'utiliser en priorité
    if (_isUsingPredefinedAvatar && _selectedPredefinedAvatar != null) {
      return AssetImage(_selectedPredefinedAvatar!);
    }
    // Sinon, utiliser l'image de profil existante
    else if (_currentProfile!.profileImageUrl != null) {
      return NetworkImage(_currentProfile!.profileImageUrl!);
    } else if (_currentProfile!.profileImagePath != null) {
      return FileImage(File(_currentProfile!.profileImagePath!));
    }
    return null;
  }
}
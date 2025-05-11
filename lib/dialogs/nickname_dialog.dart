// lib/dialogs/nickname_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user/user_manager.dart';
import '../services/user/user_profile.dart';

class NicknameDialog extends StatefulWidget {
  final Function(String)? onNicknameSet;
  final String? initialNickname;

  const NicknameDialog({
    Key? key,
    this.onNicknameSet,
    this.initialNickname,
  }) : super(key: key);

  @override
  _NicknameDialogState createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<NicknameDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialNickname != null && widget.initialNickname!.isNotEmpty) {
      _controller.text = widget.initialNickname!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final nickname = _controller.text.trim();

    if (nickname.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un surnom';
      });
      return;
    }

    if (nickname.length < 3) {
      setState(() {
        _errorMessage = 'Le surnom doit contenir au moins 3 caractères';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      final currentProfile = userManager.currentProfile;

      if (currentProfile != null) {
        // Mettre à jour le profil existant
        final updatedProfile = currentProfile.copyWith(
          displayName: nickname,
        );

        // Sauvegarder les modifications
        await userManager.updateProfile(updatedProfile);

        if (widget.onNicknameSet != null) {
          widget.onNicknameSet!(nickname);
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // Pas de profil existant, afficher une erreur
        setState(() {
          _errorMessage = 'Aucun profil utilisateur trouvé';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sauvegarde: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez votre surnom',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Ce surnom sera affiché aux autres joueurs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: 'Surnom',
                prefixIcon: const Icon(Icons.person),
                errorText: _errorMessage,
              ),
              maxLength: 15,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveNickname,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Enregistrer'),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
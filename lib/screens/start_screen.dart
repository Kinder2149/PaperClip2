import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../utils/update_manager.dart';
import '../main.dart';
import 'dart:io';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? _selectedSave;
  bool _isLoading = false;

  String _formatSaveName(String filename) {
    if (!filename.startsWith('save_')) return filename;

    String dateStr = filename.substring(5);
    try {
      String formattedDate = '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}';
      String formattedTime = '${dateStr.substring(8, 10)}:${dateStr.substring(10, 12)}:${dateStr.substring(12, 14)}';
      return '$formattedDate $formattedTime';
    } catch (e) {
      return filename;
    }
  }

  String _formatSaveInfo(File saveFile) {
    try {
      String size = (saveFile.lengthSync() / 1024).toStringAsFixed(1) + ' KB';
      String modified = DateTime.fromMillisecondsSinceEpoch(
          saveFile.lastModifiedSync().millisecondsSinceEpoch
      ).toString().split('.')[0];
      return 'Taille: $size\nDernière modification: $modified';
    } catch (e) {
      return 'Erreur de lecture du fichier';
    }
  }

  Future<Map<String, dynamic>?> _readSaveInfo(String filename) async {
    try {
      final directory = await context.read<GameState>().customSaveDirectory;
      if (directory == null) return null;

      final file = File('$directory/$filename.json');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      return {
        'fileInfo': _formatSaveInfo(file),
        'saveData': content,
      };
    } catch (e) {
      print('Erreur lors de la lecture de la sauvegarde: $e');
      return null;
    }
  }

  void _showSaveInfo(String filename) async {
    final saveInfo = await _readSaveInfo(filename);
    if (!mounted || saveInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatSaveName(filename)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(saveInfo['fileInfo'] as String),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _loadSave(filename);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Charger'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteSave(filename),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Supprimer',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSave(String filename) async {
    setState(() => _isLoading = true);

    try {
      final success = await context.read<GameState>().importSave(filename);
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainGame()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSave(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la sauvegarde "$filename" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<GameState>().deleteSave(filename);
      if (mounted) {
        Navigator.pop(context); // Ferme la boîte de dialogue d'info
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sauvegarde supprimée')),
        );
        setState(() {}); // Rafraîchit la liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
              Colors.deepPurple[400]!,
              Colors.deepPurple[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icone.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Paperclip Game',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'v${UpdateManager.CURRENT_VERSION}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Nouvelle partie et dossier de sauvegarde
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainGame()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Nouvelle Partie'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.read<GameState>().selectSaveDirectory(),
                      icon: const Icon(Icons.folder),
                      label: const Text('Dossier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Consumer<GameState>(
                  builder: (context, gameState, child) {
                    return Text(
                      'Dossier de sauvegarde :\n${gameState.customSaveDirectory ?? "Dossier par défaut"}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Sauvegardes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Liste des sauvegardes
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FutureBuilder<List<String>>(
                    future: context.read<GameState>().listSaves(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Aucune sauvegarde trouvée',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final save = snapshot.data![index];
                          final isSelected = save == _selectedSave;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            child: ListTile(
                              title: Text(
                                _formatSaveName(save),
                                style: const TextStyle(color: Colors.white),
                              ),
                              leading: const Icon(
                                Icons.save,
                                color: Colors.white,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _showSaveInfo(save),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteSave(save),
                                  ),
                                ],
                              ),
                              onTap: () => _loadSave(save),
                              selected: isSelected,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
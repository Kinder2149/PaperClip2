import 'dart:convert';
import 'package:shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

class StockageService {
  static const String CLE_SAUVEGARDE = 'sauvegarde_jeu';
  static const String CLE_CACHE = 'cache_jeu';
  static const String CLE_DERNIERE_SAUVEGARDE = 'derniere_sauvegarde';
  
  final SharedPreferences _prefs;
  
  StockageService(this._prefs);
  
  static Future<StockageService> initialiser() async {
    final prefs = await SharedPreferences.getInstance();
    return StockageService(prefs);
  }

  // Sauvegarde du jeu
  Future<void> sauvegarderJeu(Map<String, dynamic> etatJeu) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final donnees = {
      'etat': etatJeu,
      'timestamp': timestamp,
      'checksum': _genererChecksum(etatJeu),
    };
    
    // Sauvegarde dans SharedPreferences
    await _prefs.setString(CLE_SAUVEGARDE, jsonEncode(donnees));
    await _prefs.setInt(CLE_DERNIERE_SAUVEGARDE, timestamp);
    
    // Sauvegarde dans un fichier
    await _sauvegarderDansFichier(donnees);
  }

  // Chargement de la sauvegarde
  Future<Map<String, dynamic>?> chargerSauvegarde() async {
    try {
      // Essayer de charger depuis SharedPreferences
      final donneesBrutes = _prefs.getString(CLE_SAUVEGARDE);
      if (donneesBrutes != null) {
        final donnees = jsonDecode(donneesBrutes) as Map<String, dynamic>;
        if (_verifierChecksum(donnees['etat'], donnees['checksum'])) {
          return donnees['etat'];
        }
      }
      
      // Si échec, essayer de charger depuis le fichier
      return await _chargerDepuisFichier();
    } catch (e) {
      print('Erreur lors du chargement de la sauvegarde: $e');
      return null;
    }
  }

  // Gestion du cache
  Future<void> mettreEnCache(String cle, dynamic donnees) async {
    final cache = _prefs.getString(CLE_CACHE) ?? '{}';
    final cacheMap = jsonDecode(cache) as Map<String, dynamic>;
    cacheMap[cle] = donnees;
    await _prefs.setString(CLE_CACHE, jsonEncode(cacheMap));
  }

  dynamic recupererDuCache(String cle) {
    try {
      final cache = _prefs.getString(CLE_CACHE) ?? '{}';
      final cacheMap = jsonDecode(cache) as Map<String, dynamic>;
      return cacheMap[cle];
    } catch (e) {
      print('Erreur lors de la récupération du cache: $e');
      return null;
    }
  }

  // Sauvegarde dans un fichier
  Future<void> _sauvegarderDansFichier(Map<String, dynamic> donnees) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sauvegarde.json');
      await file.writeAsString(jsonEncode(donnees));
    } catch (e) {
      print('Erreur lors de la sauvegarde dans le fichier: $e');
    }
  }

  // Chargement depuis un fichier
  Future<Map<String, dynamic>?> _chargerDepuisFichier() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sauvegarde.json');
      if (await file.exists()) {
        final contenu = await file.readAsString();
        final donnees = jsonDecode(contenu) as Map<String, dynamic>;
        if (_verifierChecksum(donnees['etat'], donnees['checksum'])) {
          return donnees['etat'];
        }
      }
    } catch (e) {
      print('Erreur lors du chargement depuis le fichier: $e');
    }
    return null;
  }

  // Génération et vérification du checksum
  String _genererChecksum(Map<String, dynamic> donnees) {
    final bytes = utf8.encode(jsonEncode(donnees));
    return sha256.convert(bytes).toString();
  }

  bool _verifierChecksum(Map<String, dynamic> donnees, String checksum) {
    return _genererChecksum(donnees) == checksum;
  }

  // Nettoyage du cache
  Future<void> nettoyerCache() async {
    await _prefs.remove(CLE_CACHE);
  }
} 
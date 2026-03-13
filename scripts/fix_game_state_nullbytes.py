#!/usr/bin/env python3
"""
Script de correction automatique pour game_state.dart
Nettoie les null bytes et applique les corrections critiques
"""

import sys
import re
from pathlib import Path

def clean_null_bytes(content: str) -> str:
    """Supprime les caractères null bytes du contenu"""
    return content.replace('\x00', '')

def apply_correction_1(content: str) -> str:
    """Correction #1: Renforcer setPartieId avec logs et exceptions"""
    
    old_pattern = r'''  // Défini explicitement l'identifiant technique de la partie \(utilisé lors du chargement\)
  void setPartieId\(String id\) \{
    // Enforce UUID v4 format \(cloud-first invariant: identité technique stricte\)
    final uuidV4 = RegExp\(r'\^[0-9a-fA-F]\{8\}-[0-9a-fA-F]\{4\}-4[0-9a-fA-F]\{3\}-[89abAB][0-9a-fA-F]\{3\}-[0-9a-fA-F]\{12\} \?\$'\);
    if \(uuidV4\.hasMatch\(id\)\) \{
      _partieId = id;
    \} else \{
      // Ignorer les identifiants non conformes \(aucune création implicite ici\)
    \}
  \}'''
    
    new_code = '''  // Défini explicitement l'identifiant technique de la partie (utilisé lors du chargement)
  void setPartieId(String id) {
    // Enforce UUID v4 format (cloud-first invariant: identité technique stricte)
    final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$');
    if (uuidV4.hasMatch(id)) {
      // CORRECTION: Logger le changement d'identité pour traçabilité
      if (kDebugMode && _partieId != null && _partieId != id) {
        print('[GameState] ⚠️ Changement de partieId détecté: $_partieId → $id');
      }
      _partieId = id;
    } else {
      // CORRECTION: Logger l'erreur au lieu d'ignorer silencieusement
      if (kDebugMode) {
        print('[GameState] ❌ Tentative d\\'assignation d\\'un partieId invalide (non UUID v4): "$id"');
        print('[GameState] Stack trace:');
        print(StackTrace.current);
      }
      // CORRECTION: Lever une exception en mode debug pour détecter les bugs
      throw ArgumentError('[GameState] partieId doit être un UUID v4 valide, reçu: "$id"');
    }
  }'''
    
    if re.search(old_pattern, content, re.MULTILINE):
        content = re.sub(old_pattern, new_code, content, flags=re.MULTILINE)
        print("✅ Correction #1 appliquée: setPartieId renforcé")
    else:
        print("⚠️ Correction #1: Pattern non trouvé, recherche alternative...")
        # Pattern simplifié
        simple_pattern = r'void setPartieId\(String id\) \{[^}]+\}'
        if re.search(simple_pattern, content, re.DOTALL):
            print("⚠️ Méthode setPartieId trouvée mais pattern différent - correction manuelle requise")
    
    return content

def apply_correction_2(content: str) -> str:
    """Correction #2: Corriger applySnapshot pour utiliser setPartieId"""
    
    old_pattern = r'''    // ID technique \(UUID\) si présent dans les métadonnées du snapshot
    final metaPartieId = metadata\['partieId'\] as String\?;
    if \(_partieId == null && metaPartieId != null && metaPartieId\.isNotEmpty\) \{
      _partieId = metaPartieId;
    \}'''
    
    new_code = '''    // CORRECTION CRITIQUE: Toujours écraser le partieId lors du chargement d'un snapshot
    // et utiliser setPartieId() pour validation UUID v4
    final metaPartieId = metadata['partieId'] as String?;
    if (metaPartieId != null && metaPartieId.isNotEmpty) {
      // CORRECTION: Utiliser setPartieId() au lieu d'assignation directe
      // Cela garantit la validation UUID v4 et la traçabilité
      try {
        setPartieId(metaPartieId);
      } catch (e) {
        // Si le partieId du snapshot est invalide, logger et continuer
        if (kDebugMode) {
          print('[GameState] ⚠️ Snapshot contient un partieId invalide: "$metaPartieId"');
          print('[GameState] Erreur: $e');
        }
        // Ne pas bloquer le chargement, mais signaler le problème
      }
    }'''
    
    if re.search(old_pattern, content, re.MULTILINE):
        content = re.sub(old_pattern, new_code, content, flags=re.MULTILINE)
        print("✅ Correction #2 appliquée: applySnapshot corrigé")
    else:
        print("⚠️ Correction #2: Pattern non trouvé - correction manuelle requise")
    
    return content

def main():
    # Chemin du fichier
    file_path = Path(__file__).parent.parent / 'lib' / 'models' / 'game_state.dart'
    
    if not file_path.exists():
        print(f"❌ Fichier non trouvé: {file_path}")
        sys.exit(1)
    
    print(f"📂 Lecture du fichier: {file_path}")
    
    # Lire le contenu
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ Erreur de lecture: {e}")
        sys.exit(1)
    
    # Vérifier la présence de null bytes
    null_count = content.count('\x00')
    if null_count > 0:
        print(f"⚠️ {null_count} null bytes détectés - nettoyage en cours...")
        content = clean_null_bytes(content)
        print("✅ Null bytes supprimés")
    
    # Créer une sauvegarde
    backup_path = file_path.with_suffix('.dart.backup')
    try:
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"💾 Sauvegarde créée: {backup_path}")
    except Exception as e:
        print(f"⚠️ Impossible de créer la sauvegarde: {e}")
    
    # Appliquer les corrections
    print("\n🔧 Application des corrections...")
    content = apply_correction_1(content)
    content = apply_correction_2(content)
    
    # Écrire le fichier corrigé
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"\n✅ Fichier corrigé écrit: {file_path}")
        print("\n📋 Prochaines étapes:")
        print("1. Vérifier les corrections dans game_state.dart")
        print("2. Appliquer la correction #3 dans game_persistence_orchestrator.dart")
        print("3. Exécuter les tests de validation")
    except Exception as e:
        print(f"❌ Erreur d'écriture: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()

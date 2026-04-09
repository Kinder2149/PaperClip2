#!/usr/bin/env python3
"""
Script de nettoyage automatique de GameMode pour CHANTIER-01
Supprime toutes les références à GameMode dans le projet PaperClip2
"""

import os
import re
from pathlib import Path

# Répertoire racine du projet
PROJECT_ROOT = Path(__file__).parent.parent
LIB_DIR = PROJECT_ROOT / "lib"
TEST_DIR = PROJECT_ROOT / "test"

# Fichiers à traiter
FILES_TO_CLEAN = [
    # Models
    "lib/models/game_state.dart",
    "lib/models/save_game.dart",
    "lib/models/save_metadata.dart",
    
    # Services
    "lib/services/persistence/game_persistence_orchestrator.dart",
    "lib/services/persistence/game_persistence_mapper.dart",
    "lib/services/persistence/local_game_persistence.dart",
    "lib/services/persistence/save_aggregator.dart",
    "lib/services/game_runtime_coordinator.dart",
    "lib/services/save_migration_service.dart",
    "lib/services/save_game.dart",
    "lib/services/runtime/runtime_actions.dart",
    "lib/services/save_system/local_save_game_manager.dart",
    "lib/services/save_system/save_game_manager.dart",
    "lib/services/save_system/save_validator.dart",
    "lib/services/cloud/models/cloud_world_detail.dart",
    
    # Screens & Widgets
    "lib/screens/start_screen.dart",
    "lib/screens/google_profile_screen.dart",
    "lib/dialogs/metal_crisis_dialog.dart",
    "lib/widgets/metal_crisis_dialog.dart",
    "lib/widgets/new_game/new_game_dialog.dart",
    "lib/widgets/appbar/game_appbar.dart",
    "lib/widgets/appbar/appbar_actions.dart",
    "lib/widgets/indicators/competitive_mode_indicator.dart",
    
    # Core
    "lib/core/constants/constantes.dart",
]

def clean_gamemode_references(file_path: Path) -> bool:
    """Nettoie les références à GameMode dans un fichier"""
    if not file_path.exists():
        print(f"⚠️  Fichier non trouvé: {file_path}")
        return False
    
    content = file_path.read_text(encoding='utf-8')
    original_content = content
    
    # Patterns à supprimer ou remplacer
    patterns = [
        # Imports GameMode
        (r"import.*GameMode.*;\n", ""),
        (r",\s*GameMode\s*(?=\})", ""),  # Dans les imports show
        
        # Déclarations de champs
        (r"\s*GameMode\s+_gameMode\s*=\s*GameMode\.\w+;\n", ""),
        (r"\s*DateTime\?\s+_competitiveStartTime;\n", ""),
        (r"\s*final\s+GameMode\s+gameMode;\n", ""),
        
        # Getters
        (r"\s*GameMode\s+get\s+gameMode\s*=>\s*_gameMode;\n", ""),
        (r"\s*DateTime\?\s+get\s+competitiveStartTime\s*=>\s*_competitiveStartTime;\n", ""),
        
        # Méthodes competitivePlayTime
        (r"\s*Duration\s+get\s+competitivePlayTime\s*\{[^}]+\}\n", ""),
        
        # Paramètres de fonction
        (r",?\s*GameMode\s+gameMode", ""),
        (r",?\s*required\s+this\.gameMode", ""),
        (r"gameMode:\s*GameMode\.\w+,?\n", ""),
        (r"gameMode:\s*\w+\.gameMode,?\n", ""),
        
        # Assignations
        (r"\s*_gameMode\s*=\s*[^;]+;\n", ""),
        (r"\s*_competitiveStartTime\s*=\s*[^;]+;\n", ""),
        
        # Conditions
        (r"if\s*\(\s*_gameMode\s*==\s*GameMode\.\w+\s*\)\s*\{[^}]*\}\n", ""),
        (r"if\s*\(\s*\w+\.gameMode\s*==\s*GameMode\.\w+\s*\)\s*\{[^}]*\}\n", ""),
        
        # Dans JSON/Maps
        (r"'gameMode':\s*[^,\n]+,?\n", ""),
        (r"\"gameMode\":\s*[^,\n]+,?\n", ""),
        
        # Commentaires
        (r"//.*[Mm]ode de jeu.*\n", ""),
        (r"//.*[Cc]omp[ée]titif.*\n", ""),
    ]
    
    for pattern, replacement in patterns:
        content = re.sub(pattern, replacement, content)
    
    # Nettoyage des lignes vides multiples
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    if content != original_content:
        file_path.write_text(content, encoding='utf-8')
        print(f"✅ Nettoyé: {file_path.relative_to(PROJECT_ROOT)}")
        return True
    else:
        print(f"ℹ️  Aucun changement: {file_path.relative_to(PROJECT_ROOT)}")
        return False

def main():
    print("🚀 Démarrage du nettoyage GameMode...")
    print(f"📁 Répertoire projet: {PROJECT_ROOT}")
    print()
    
    cleaned_count = 0
    
    for file_rel_path in FILES_TO_CLEAN:
        file_path = PROJECT_ROOT / file_rel_path
        if clean_gamemode_references(file_path):
            cleaned_count += 1
    
    print()
    print(f"✨ Nettoyage terminé: {cleaned_count} fichiers modifiés")
    print()
    print("⚠️  IMPORTANT: Vérifiez manuellement les fichiers suivants:")
    print("  - lib/models/game_state.dart (logique métier complexe)")
    print("  - lib/services/persistence/game_persistence_orchestrator.dart")
    print("  - Tests unitaires dans test/")

if __name__ == "__main__":
    main()

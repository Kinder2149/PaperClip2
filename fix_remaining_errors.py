#!/usr/bin/env python3
"""
Script pour corriger les erreurs restantes dans game_persistence_orchestrator.dart
"""

import re

file_path = r'lib\services\persistence\game_persistence_orchestrator.dart'

# Lire le fichier
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remplacer state.gameName par state.enterpriseName
content = re.sub(r'state\.gameName', 'state.enterpriseName', content)

# 2. Supprimer les références à gameMode dans SaveGame
# Supprimer le paramètre gameMode: dans les constructeurs SaveGame
content = re.sub(r',\s*gameMode:\s*state\.gameMode', '', content)
content = re.sub(r',\s*gameMode:\s*[a-zA-Z_]+\.gameMode', '', content)
content = re.sub(r'gameMode:\s*state\.gameMode,?\s*', '', content)
content = re.sub(r'gameMode:\s*[a-zA-Z_]+\.gameMode,?\s*', '', content)

# 3. Supprimer l'import de VersionConflictException
content = re.sub(
    r"import 'package:paperclip2/services/cloud/exceptions/version_conflict_exception\.dart';\n",
    '',
    content
)

# 4. Supprimer les blocs catch pour VersionConflictException
# On va simplement supprimer tout le bloc on VersionConflictException
content = re.sub(
    r'\s*on VersionConflictException catch \(e\) \{[^}]*\}',
    '',
    content,
    flags=re.DOTALL
)

# 5. Corriger les méthodes setPartieId qui n'existent plus
content = re.sub(r'state\.setPartieId\([^)]+\);?', '// setPartieId removed in CHANTIER-01', content)
content = re.sub(r'try \{ state\.setPartieId\([^)]+\); \} catch \(_\) \{\}', '// setPartieId removed', content)

# Écrire le fichier
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Corrections supplémentaires effectuées!")
print("Erreurs corrigées:")
print("  - state.gameName → state.enterpriseName")
print("  - Suppression références gameMode")
print("  - Suppression VersionConflictException")
print("  - Suppression setPartieId()")

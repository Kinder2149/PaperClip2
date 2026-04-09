#!/usr/bin/env python3
"""
Script pour corriger les dernières erreurs
"""

import re

file_path = r'lib\services\persistence\game_persistence_orchestrator.dart'

# Lire le fichier
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Corrections ligne par ligne
for i, line in enumerate(lines):
    # Ligne 175 : deleteById(enterpriseId: enterpriseId) -> deleteById(enterpriseId: partieId)
    if i == 174 and 'deleteById(enterpriseId: enterpriseId)' in line:
        lines[i] = line.replace('deleteById(enterpriseId: enterpriseId)', 'deleteById(enterpriseId: partieId)')
    
    # Lignes avec gameMode: GameMode.XXX ou gameMode: xxx.gameMode
    if 'gameMode:' in line and ('GameMode.' in line or '.gameMode' in line):
        # Supprimer toute la ligne si c'est juste un paramètre gameMode
        if re.match(r'\s*gameMode:\s*', line.strip()):
            lines[i] = ''
        # Sinon supprimer juste le paramètre gameMode
        else:
            lines[i] = re.sub(r',?\s*gameMode:\s*[^,\)]+', '', line)
    
    # Supprimer les comparaisons avec gameMode
    if '.gameMode ==' in line or 'meta.gameMode' in line or 'save.gameMode' in line:
        # Commenter la ligne
        if not line.strip().startswith('//'):
            lines[i] = '// ' + line
    
    # Supprimer gameModeEnum
    if 'gameModeEnum' in line:
        lines[i] = '// ' + line
    
    # Corriger failedWorldIds -> failedEnterpriseIds
    if 'failedWorldIds' in line:
        lines[i] = line.replace('failedWorldIds', 'failedEnterpriseIds')

# Écrire le fichier
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ Corrections finales effectuées!")
print("Erreurs corrigées:")
print("  - enterpriseId non défini")
print("  - Suppression gameMode/GameMode")
print("  - Suppression gameModeEnum")
print("  - failedWorldIds → failedEnterpriseIds")

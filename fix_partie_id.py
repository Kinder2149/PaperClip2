#!/usr/bin/env python3
"""
Script pour remplacer toutes les références à partieId par enterpriseId
dans game_persistence_orchestrator.dart
"""

import re

file_path = r'lib\services\persistence\game_persistence_orchestrator.dart'

# Lire le fichier
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remplacements à effectuer
replacements = [
    # Variables locales et paramètres
    (r'\bpartieId\b(?!:)', 'enterpriseId'),  # partieId comme variable, pas comme clé de map
    # Paramètres nommés dans les appels de méthodes (sauf dans les logs)
    (r"'partieId':", "'enterpriseId':"),  # Clés de map dans les logs
    # Commentaires
    (r'partieId\s*:', 'enterpriseId:'),  # Dans les signatures de paramètres
]

# Appliquer les remplacements
for pattern, replacement in replacements:
    content = re.sub(pattern, replacement, content)

# Corrections spécifiques pour les méthodes qui ont encore le mauvais nom de paramètre
# pullCloudById et cloudStatusById et deleteCloudById gardent partieId comme nom de paramètre
# car ils sont des wrappers legacy
content = re.sub(
    r'Future<CloudWorldDetail\?> pullCloudById\(\{\s*required String enterpriseId,',
    'Future<CloudWorldDetail?> pullCloudById({\n    required String partieId,',
    content
)

content = re.sub(
    r'Future<CloudStatus> cloudStatusById\(\{\s*required String enterpriseId,',
    'Future<CloudStatus> cloudStatusById({\n    required String partieId,',
    content
)

content = re.sub(
    r'Future<void> deleteCloudById\(\{\s*required String enterpriseId,',
    'Future<void> deleteCloudById({\n    required String partieId,',
    content
)

# Écrire le fichier
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Remplacements effectués avec succès!")
print("Vérifiez le fichier et lancez 'flutter analyze' pour valider.")

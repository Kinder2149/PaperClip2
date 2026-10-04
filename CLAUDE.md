## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` to keep the graph current

## Hygiène git (règle uniforme, tous appareils)

**Début de mission, avant tout travail**
1. S'il y a du travail non enregistré : s'arrêter, montrer à Kinder quels fichiers et depuis quand, et le laisser choisir (enregistrer, mettre de côté ou abandonner). Ne jamais le jeter soi-même.
2. Récupérer l'état du dépôt en ligne.
3. Si la copie est simplement en retard : la mettre à jour. Si la copie et le dépôt en ligne ont chacun du nouveau (divergence) : s'arrêter, expliquer, ne rien mélanger.

**Pendant la mission**
4. Travailler sur une branche à part, jamais directement sur la branche principale.
5. Ne fusionner dans la branche principale qu'après l'accord explicite de Kinder dans la conversation.

**Fin de mission**
6. Après fusion : supprimer la branche (copie locale, et copie en ligne si elle existe encore). Ne jamais toucher à une branche dont le nom commence par `archive/` : c'est de l'archivage.
7. Si la suppression en ligne est impossible depuis cet appareil : donner à Kinder la commande exacte à lancer, sans réessayer en boucle.
8. Ne jamais supprimer une branche non fusionnée sans décision de Kinder, branche par branche.

import 'package:flutter/material.dart';

/// Dialogue: renommer un monde. Retourne le nouveau nom (trim) ou null.
Future<String?> showRenameWorldDialog(BuildContext context, {required String initialName}) {
  final controller = TextEditingController(text: initialName);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Renommer le monde'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Nouveau nom'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Renommer')),
      ],
    ),
  );
}

/// Dialogue: confirmer la suppression du monde. Retourne true si confirmé.
Future<bool> showConfirmDeleteWorldDialog(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer ce monde ?'),
      content: const Text('Supprime la copie locale et la sauvegarde cloud (si présente).'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
      ],
    ),
  );
  return confirm == true;
}

/// Dialogue: lister et choisir un backup à restaurer.
/// Le paramètre [items] est une liste de triplets (title, subtitle, id) affichés.
Future<void> showRestoreWorldDialog(
  BuildContext context, {
  required List<RestoreItem> items,
  required Future<void> Function(RestoreItem picked) onPick,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restaurer une sauvegarde'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (c, i) {
            final b = items[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.restore_outlined),
              title: Text(b.title),
              subtitle: Text(b.subtitle ?? ''),
              onTap: () async {
                Navigator.of(ctx).pop();
                await onPick(b);
              },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
    ),
  );
}

/// Modèle simple utilisé par le dialogue de restauration.
class RestoreItem {
  final String id;
  final String title;
  final String? subtitle;
  const RestoreItem({required this.id, required this.title, this.subtitle});
}

/// Expose un helper pour construire des items à partir d'un nom de backup et d'un timestamp.
RestoreItem buildRestoreItem({required String backupName, required DateTime timestamp}) {
  return RestoreItem(
    id: backupName,
    title: backupName.split('|').last,
    subtitle: timestamp.toLocal().toString().split('.').first,
  );
}

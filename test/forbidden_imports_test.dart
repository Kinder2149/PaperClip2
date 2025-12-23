import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Forbidden imports guard', () {
    test('No new imports of services/save_system outside allowlist', () {
      final projectRoot = Directory.current.path.replaceAll('\\', '/');
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib/ directory should exist');

      // Allowlist temporaire (à réduire au fil du nettoyage)
      final allowlist = <String>{
        'lib/services/save_system/', // le dossier legacy lui-même
        'lib/services/persistence/game_persistence_orchestrator.dart',
        'lib/services/auto_save_service.dart',
        'lib/screens/save_load_screen.dart',
        'lib/services/save_migration_service.dart',
      };

      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;

        final relPath = entity.path.replaceAll('\\', '/');
        final relative = relPath.startsWith(projectRoot)
            ? relPath.substring(projectRoot.length + 1)
            : relPath;

        final isAllowed = allowlist.any((allowed) => relative.startsWith(allowed));
        if (isAllowed) continue;

        final content = entity.readAsStringSync();
        if (content.contains("import '../services/save_system/")
            || content.contains("import 'package:paperclip2/services/save_system/")
            || content.contains("import 'services/save_system/")) {
          violations.add(relative);
        }
      }

      if (violations.isNotEmpty) {
        fail('Forbidden import detected in files:\n - ' + violations.join('\n - '));
      }
    });
  });
}
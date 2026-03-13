// tools/guardrails/check_ui_imports.dart
// Simple anti-regression guard: forbid UI screens from importing orchestrators/runtime directly.
// Exit code 1 if any forbidden import is found.

import 'dart:io';

final forbiddenPatterns = <RegExp>[
  // Direct orchestrators/runtime that must not be pulled by UI
  RegExp(r"import\s+['\"][^'\"]*services/persistence/game_persistence_orchestrator\.dart['\"]"),
  RegExp(r"import\s+['\"][^'\"]*services/auto_save_service\.dart['\"]"),
  RegExp(r"import\s+['\"][^'\"]*services/game_runtime_coordinator\.dart['\"]"),
  RegExp(r"import\s+['\"][^'\"]*services/runtime/[^'\"]+\.dart['\"]"),
  // Managers (gameplay) must not be imported by UI screens
  RegExp(r"import\s+['\"][^'\"]*\/managers\/[^'\"]+\.dart['\"]"),
];

// Allowed exceptions (exact file paths under lib/screens) if needed
final allowedExceptions = <String>{};

void main(List<String> args) {
  final projectRoot = Directory.current;
  final libDir = Directory('${projectRoot.path}${Platform.pathSeparator}lib');
  final screensDir = Directory('${libDir.path}${Platform.pathSeparator}screens');
  if (!screensDir.existsSync()) {
    stdout.writeln('No lib/screens directory found. Skipping.');
    return;
  }

  final violations = <String>[];

  for (final entity in screensDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    // Build a repo-relative-ish path for display
    final relPath = entity.path.replaceFirst(projectRoot.path + Platform.pathSeparator, '');
    if (allowedExceptions.contains(relPath.replaceAll('\\', '/'))) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final re in forbiddenPatterns) {
        if (re.hasMatch(line)) {
          violations.add('$relPath:${i + 1}: $line');
        }
      }
    }
  }

  // Additional anti-regression: forbid recreating local pause flags anywhere in lib/**
  // Specifically block the introduction of a field/variable named _isPaused
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final text = entity.readAsStringSync();
    if (RegExp(r"(^|\s)_isPaused\b").hasMatch(text)) {
      final rel = entity.path.replaceFirst(projectRoot.path + Platform.pathSeparator, '');
      violations.add('$rel: contains forbidden local pause flag "_isPaused"');
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('[Guardrails] OK: no forbidden imports in lib/screens and no local _isPaused flags');
    return;
  }

  stderr.writeln('[Guardrails] Forbidden imports detected in UI screens:');
  for (final v in violations) {
    stderr.writeln(' - $v');
  }
  // Non-zero exit so CI fails
  exit(1);
}

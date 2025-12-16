class GameDataCompat {
  static Map<String, dynamic> normalizeLegacyGameData(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);

    _aliasMap(normalized, canonicalKey: 'playerManager', aliases: const ['player']);
    _aliasMap(normalized, canonicalKey: 'resourceManager', aliases: const ['resources']);
    _aliasMap(normalized, canonicalKey: 'marketManager', aliases: const ['market']);
    _aliasMap(normalized, canonicalKey: 'levelSystem', aliases: const ['level']);
    _aliasMap(normalized, canonicalKey: 'missionSystem', aliases: const ['missions']);

    return normalized;
  }

  static Map<String, dynamic> normalizeSnapshotCore(Map<String, dynamic> rawCore) {
    final normalized = Map<String, dynamic>.from(rawCore);

    _aliasMap(normalized, canonicalKey: 'playerManager', aliases: const ['player']);
    _aliasMap(normalized, canonicalKey: 'resourceManager', aliases: const ['resources']);
    _aliasMap(normalized, canonicalKey: 'marketManager', aliases: const ['market']);
    _aliasMap(normalized, canonicalKey: 'levelSystem', aliases: const ['level']);
    _aliasMap(normalized, canonicalKey: 'missionSystem', aliases: const ['missions']);

    return normalized;
  }

  static void _aliasMap(
    Map<String, dynamic> target, {
    required String canonicalKey,
    required List<String> aliases,
  }) {
    final canonical = target[canonicalKey];
    if (canonical is Map) {
      target[canonicalKey] = Map<String, dynamic>.from(canonical);
      return;
    }

    for (final alias in aliases) {
      final value = target[alias];
      if (value is Map) {
        target[canonicalKey] = Map<String, dynamic>.from(value);
        return;
      }
    }
  }
}

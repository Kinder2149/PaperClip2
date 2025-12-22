abstract class GameCloudSaveAdapter {
  /// Save compressed JSON data into the given slot (single-slot policy recommended).
  /// The data must be a compressed JSON (e.g., gzip). Conflict policy is LWW at
  /// the adapter level (last write wins).
  Future<void> saveCompressed({required String slot, required List<int> compressedJson});

  /// Load compressed JSON data from the given slot. Returns null if nothing exists.
  Future<List<int>?> loadCompressed({required String slot});
}

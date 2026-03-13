class RuntimeMetaRegistry {
  static final RuntimeMetaRegistry instance = RuntimeMetaRegistry._internal();
  RuntimeMetaRegistry._internal();

  DateTime? _lastActiveAt;
  DateTime? _lastOfflineAppliedAt;
  String? _offlineSpecVersion;

  DateTime? get lastActiveAt => _lastActiveAt;
  DateTime? get lastOfflineAppliedAt => _lastOfflineAppliedAt;
  String? get offlineSpecVersion => _offlineSpecVersion;

  void setLastActiveAt(DateTime value) {
    _lastActiveAt = value;
  }

  void setLastOfflineAppliedAt(DateTime value) {
    _lastOfflineAppliedAt = value;
  }

  void setOfflineSpecVersion(String value) {
    _offlineSpecVersion = value;
  }

  void reset() {
    _lastActiveAt = null;
    _lastOfflineAppliedAt = null;
    _offlineSpecVersion = null;
  }
}

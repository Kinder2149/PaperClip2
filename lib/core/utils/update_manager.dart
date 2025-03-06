// lib/core/utils/update_manager.dart
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class UpdateManager {
  static const String CURRENT_VERSION = "1.0.1";
  static const String LAST_VERSION_KEY = "last_seen_version";
  static const String REMOTE_MIN_VERSION_KEY = "min_required_version";
  static const String REMOTE_LATEST_VERSION_KEY = "latest_version";
  static const String REMOTE_RELEASE_NOTES_KEY = "release_notes";

  static final UpdateManager _instance = UpdateManager._internal();
  factory UpdateManager() => _instance;
  UpdateManager._internal();

  String? _currentVersion;
  String? _latestVersion;
  String? _minRequiredVersion;
  Map<String, dynamic>? _releaseNotes;
  bool _initialized = false;

  // Initialize with app's current version
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Get the current version from PackageInfo
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // Initialize Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default values
      await remoteConfig.setDefaults({
        REMOTE_MIN_VERSION_KEY: _currentVersion,
        REMOTE_LATEST_VERSION_KEY: _currentVersion,
        REMOTE_RELEASE_NOTES_KEY: '{}',
      });

      // Fetch and activate remote config values
      await remoteConfig.fetchAndActivate();

      // Get values from remote config
      _minRequiredVersion = remoteConfig.getString(REMOTE_MIN_VERSION_KEY);
      _latestVersion = remoteConfig.getString(REMOTE_LATEST_VERSION_KEY);

      try {
        _releaseNotes = Map<String, dynamic>.from(
          Map.castFrom(
            jsonDecode(remoteConfig.getString(REMOTE_RELEASE_NOTES_KEY)),
          ),
        );
      } catch (e) {
        _releaseNotes = {};
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing UpdateManager: $e');
    }
  }

  // Check if the current version is the minimum required
  bool isUpdateRequired() {
    if (!_initialized || _currentVersion == null || _minRequiredVersion == null) {
      return false;
    }

    return _compareVersions(_currentVersion!, _minRequiredVersion!) < 0;
  }

  // Check if there's a newer version available
  bool isUpdateAvailable() {
    if (!_initialized || _currentVersion == null || _latestVersion == null) {
      return false;
    }

    return _compareVersions(_currentVersion!, _latestVersion!) < 0;
  }

  // Get the latest version
  String getLatestVersion() {
    return _latestVersion ?? _currentVersion ?? CURRENT_VERSION;
  }

  // Get release notes for the latest version
  String? getReleaseNotes() {
    if (_releaseNotes == null || _latestVersion == null) return null;

    return _releaseNotes![_latestVersion];
  }

  // Compare two version strings
  int _compareVersions(String version1, String version2) {
    List<int> v1Parts = version1.split('.').map(int.parse).toList();
    List<int> v2Parts = version2.split('.').map(int.parse).toList();

    // Ensure both lists have the same length
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);

    // Compare each part
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }

    return 0; // Versions are equal
  }

  // Show update dialog if necessary
  Future<void> checkForUpdates(BuildContext context) async {
    if (!_initialized) await initialize();

    // Check if a required update is needed
    if (isUpdateRequired()) {
      _showRequiredUpdateDialog(context);
      return;
    }

    // Check if an optional update is available
    if (isUpdateAvailable()) {
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString(LAST_VERSION_KEY) ?? '';

      // Show the dialog only if the user hasn't seen it for this version
      if (lastVersion != _latestVersion) {
        _showOptionalUpdateDialog(context);

        // Save that the user has seen this version's update dialog
        await prefs.setString(LAST_VERSION_KEY, _latestVersion!);
      }
    }
  }

  // Dialog for required updates
  void _showRequiredUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mise à jour requise'),
          content: Text(
              'Une mise à jour est nécessaire pour continuer à utiliser l\'application. '
                  'Veuillez mettre à jour vers la version ${_latestVersion}.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Mettre à jour'),
              onPressed: () {
                // Logic to open app store/play store
                // This is a placeholder - implement based on your needs
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog for optional updates
  void _showOptionalUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mise à jour disponible'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('La version ${_latestVersion} est disponible.'),
              const SizedBox(height: 8),
              Text(getReleaseNotes() ?? 'Nouvelles fonctionnalités et corrections de bugs.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Plus tard'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Mettre à jour'),
              onPressed: () {
                // Logic to open app store/play store
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
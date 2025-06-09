// lib/services/api/analytics_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_client.dart';

/// Service d'analytique utilisant le backend personnalisé
/// Remplace les fonctionnalités de Firebase Analytics et Crashlytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  // Client API
  final ApiClient _apiClient = ApiClient();
  
  // Informations sur l'appareil et l'application
  String? _deviceModel;
  String? _deviceId;
  String? _osVersion;
  String? _appVersion;
  String? _buildNumber;
  
  // Constructeur interne
  AnalyticsService._internal();
  
  // Flag indiquant si le service est en mode silencieux (pas d'envoi au backend)
  bool _silentMode = false;

  // Initialisation du service
  Future<void> initialize({bool userAuthenticated = false}) async {
    try {
      debugPrint('Initialisation du service d\'analytics (auth: $userAuthenticated)');
      
      // Toujours charger les infos locales
      await _loadDeviceInfo();
      await _loadAppInfo();
      
      // Si l'utilisateur n'est pas authentifié, utiliser le mode silencieux
      _silentMode = !userAuthenticated;
      
      // Logger l'ouverture de l'application uniquement si nous ne sommes pas en mode silencieux
      if (!_silentMode) {
        logAppOpen();
      } else {
        debugPrint('Mode silencieux activé pour les analytics - les événements ne seront pas envoyés au backend');
      }
      
      debugPrint('Service d\'analytics initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du service d\'analytics: $e');
      // Activer le mode silencieux en cas d'erreur
      _silentMode = true;
    }
  }
  
  // Chargement des informations sur l'appareil
  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceModel = androidInfo.model;
        _deviceId = androidInfo.id;
        _osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceModel = iosInfo.model;
        _deviceId = iosInfo.identifierForVendor;
        _osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des informations sur l\'appareil: $e');
    }
  }
  
  // Chargement des informations sur l'application
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    } catch (e) {
      debugPrint('Erreur lors du chargement des informations sur l\'application: $e');
    }
  }
  
  // Enregistrement d'un événement
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    try {
      // Ne pas envoyer d'événements si en mode silencieux
      if (_silentMode) {
        debugPrint('[Analytics silencieux] Événement: $eventName, Paramètres: $parameters');
        return;
      }
      
      final eventData = {
        'event_name': eventName,
        'parameters': parameters ?? {},
        'user_id': userId,
        'device_info': {
          'model': _deviceModel,
          'id': _deviceId,
          'os_version': _osVersion,
        },
        'app_info': {
          'version': _appVersion,
          'build_number': _buildNumber,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Envoyer l'événement en mode non-bloquant
      _apiClient.post(
        '/analytics/events',
        body: eventData,
        requiresAuth: userId != null,
      ).catchError((e) {
        debugPrint('Erreur lors de l\'enregistrement de l\'événement: $e');
      });
    } catch (e) {
      // Ne pas bloquer l'application si l'enregistrement échoue
      debugPrint('Erreur lors de la préparation de l\'événement: $e');
    }
  }
  
  // Enregistrement d'un crash
  Future<void> recordCrash(
    dynamic exception,
    StackTrace stack, {
    String? reason,
    Map<String, dynamic>? metadata,
    String? userId,
  }) async {
    try {
      // Toujours enregistrer localement les crashes, même en mode silencieux
      debugPrint('CRASH: ${exception.toString()}');
      debugPrint('REASON: ${reason ?? "Non spécifié"}');
      debugPrint('STACK TRACE: ${stack.toString().split("\n").take(10).join("\n")}...');
      
      // Ne pas envoyer au serveur si en mode silencieux
      if (_silentMode) {
        debugPrint('[Analytics silencieux] Crash enregistré localement uniquement');
        return;
      }
      
      final crashData = {
        'exception': exception.toString(),
        'stack_trace': stack.toString(),
        'reason': reason,
        'metadata': metadata ?? {},
        'user_id': userId,
        'device_info': {
          'model': _deviceModel,
          'id': _deviceId,
          'os_version': _osVersion,
        },
        'app_info': {
          'version': _appVersion,
          'build_number': _buildNumber,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Envoyer le rapport de crash en mode non-bloquant
      _apiClient.post(
        '/analytics/crashes',
        body: crashData,
        requiresAuth: userId != null,
      ).catchError((e) {
        debugPrint('Erreur lors de l\'enregistrement du crash: $e');
      });
    } catch (e) {
      // Ne pas bloquer l'application si l'enregistrement échoue
      debugPrint('Erreur lors de la préparation du rapport de crash: $e');
    }
  }
  
  // Alias pour recordCrash pour compatibilité avec le code migré
  Future<void> recordError(
    dynamic exception,
    StackTrace stack, {
    String? reason,
    Map<String, dynamic>? metadata,
    String? userId,
    bool fatal = false,
  }) async {
    return recordCrash(
      exception,
      stack,
      reason: reason,
      metadata: metadata != null ? {...metadata, 'fatal': fatal} : {'fatal': fatal},
      userId: userId,
    );
  }
  
  // Enregistrement d'une erreur Flutter
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    return recordError(
      details.exception,
      details.stack ?? StackTrace.empty,
      reason: 'Flutter framework error',
      metadata: {
        'context': details.context?.toString(),
        'library': details.library,
        'silent': details.silent,
      },
    );
  }
  
  // Log d'ouverture de l'application
  Future<void> logAppOpen() async {
    return logEvent('app_open');
  }
  
  // Activation/désactivation de la collecte d'analytiques
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _apiClient.post(
        '/analytics/config',
        body: {'collection_enabled': enabled},
      );
    } catch (e) {
      debugPrint('Erreur lors de la configuration de la collecte d\'analytiques: $e');
    }
  }
  
  // Définition d'un utilisateur
  Future<void> setUserId(String userId) async {
    try {
      await _apiClient.post(
        '/analytics/set-user',
        body: {'user_id': userId},
      );
    } catch (e) {
      debugPrint('Erreur lors de la définition de l\'utilisateur: $e');
    }
  }
  
  // Définition de propriétés utilisateur
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      await _apiClient.post(
        '/analytics/user-properties',
        body: {'properties': properties},
      );
    } catch (e) {
      debugPrint('Erreur lors de la définition des propriétés utilisateur: $e');
    }
  }
  
  // Obtention des statistiques d'événements
  Future<Map<String, dynamic>> getEventStats({
    String? eventName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (eventName != null) {
        queryParams['event_name'] = eventName;
      }
      
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      
      final data = await _apiClient.get(
        '/analytics/stats',
        queryParams: queryParams,
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention des statistiques d\'événements: $e');
      return {};
    }
  }
}

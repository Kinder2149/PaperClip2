import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/utils/logger.dart';

/// CORRECTION AUDIT APPROFONDI #3: Gestionnaire centralisé du CloudPort
/// pour éviter les race conditions lors de la configuration.
/// 
/// Ce manager garantit qu'une seule configuration CloudPort est active à la fois
/// et empêche les reconfigurations concurrentes depuis plusieurs endroits.
class CloudPortManager {
  static final CloudPortManager _instance = CloudPortManager._internal();
  static CloudPortManager get instance => _instance;
  
  CloudPortManager._internal();
  
  static final Logger _logger = Logger.forComponent('cloud_port');
  
  CloudPersistencePort? _currentPort;
  bool _isConfiguring = false;
  String _lastReason = 'none';
  DateTime? _lastConfiguredAt;
  
  /// Retourne true si le CloudPort actif n'est pas NOOP
  bool get isActive => _currentPort != null && _currentPort is! NoopCloudPersistenceAdapter;
  
  /// Retourne le type du port actuel
  String get currentPortType => _currentPort?.runtimeType.toString() ?? 'null';
  
  /// Configure le CloudPort de manière thread-safe
  /// 
  /// [port] : Le nouveau port à configurer
  /// [reason] : La raison de la configuration (pour logs et debugging)
  /// 
  /// Retourne true si la configuration a réussi, false si une configuration était déjà en cours
  Future<bool> setPort(CloudPersistencePort port, {required String reason}) async {
    // Mutex pour éviter les configurations concurrentes
    if (_isConfiguring) {
      _logger.warn('[CloudPortManager] Configuration déjà en cours, skip', code: 'cloud_port_busy', ctx: {
        'requestedPort': port.runtimeType.toString(),
        'reason': reason,
        'currentPort': currentPortType,
      });
      return false;
    }
    
    _isConfiguring = true;
    try {
      final previousPort = currentPortType;
      final isChange = previousPort != port.runtimeType.toString();
      
      _logger.info('[CloudPortManager] setPort: ${port.runtimeType}', code: 'cloud_port_set', ctx: {
        'reason': reason,
        'previousPort': previousPort,
        'isChange': isChange,
        'timeSinceLastConfig': _lastConfiguredAt != null 
          ? DateTime.now().difference(_lastConfiguredAt!).inSeconds.toString() + 's'
          : 'never',
      });
      
      _currentPort = port;
      _lastReason = reason;
      _lastConfiguredAt = DateTime.now();
      
      // Appliquer la configuration à l'orchestrateur
      GamePersistenceOrchestrator.instance.setCloudPort(port);
      
      return true;
    } finally {
      _isConfiguring = false;
    }
  }
  
  /// Active le CloudPort (CloudPersistenceAdapter)
  /// CORRECTION AUDIT P0 #2: Retourne true si activation réussie, false sinon
  /// Permet à l'appelant de vérifier atomiquement le résultat
  Future<bool> activate({required String reason}) async {
    try {
      print('🔥🔥🔥 [CloudPortManager] activate() called | reason=$reason 🔥🔥🔥');
      
      // Import dynamique pour éviter les dépendances circulaires
      print('🔥🔥🔥 [CloudPortManager] Creating active port instance 🔥🔥🔥');
      final CloudPersistencePort activePort = await _createActivePort();
      
      print('🔥🔥🔥 [CloudPortManager] Calling setPort() | portType=${activePort.runtimeType} 🔥🔥🔥');
      final success = await setPort(activePort, reason: reason);
      
      print('🔥🔥🔥 [CloudPortManager] setPort() result | success=$success 🔥🔥🔥');
      print('🔥🔥🔥 [CloudPortManager] Checking isActive | _currentPort=${_currentPort?.runtimeType} isActive=$isActive currentPortNull=${_currentPort == null} isNoop=${_currentPort is NoopCloudPersistenceAdapter} 🔥🔥🔥');
      
      // Vérification double pour garantir que le port est bien actif
      if (success && isActive) {
        print('🔥🔥🔥 [CloudPortManager] Activation successful | currentPortType=$currentPortType 🔥🔥🔥');
        return true;
      }
      
      // Port configuré mais pas actif (NOOP détecté)
      print('🔥🔥🔥 [CloudPortManager] Port configuré mais NOOP détecté | portType=$currentPortType reason=$reason success=$success isActive=$isActive 🔥🔥🔥');
      return false;
    } catch (e, stack) {
      print('🔥🔥🔥 [CloudPortManager] ERREUR activation | reason=$reason error=$e stack=${stack.toString().substring(0, 200)} 🔥🔥🔥');
      return false;
    }
  }
  
  /// Désactive le CloudPort (NoopCloudPersistenceAdapter)
  Future<bool> deactivate({required String reason}) async {
    return setPort(NoopCloudPersistenceAdapter(), reason: reason);
  }
  
  /// Crée une instance de CloudPersistenceAdapter
  Future<CloudPersistencePort> _createActivePort() async {
    return CloudPersistenceAdapter();
  }
  
  /// Retourne les informations de diagnostic du CloudPort
  Map<String, dynamic> getDiagnostics() {
    return {
      'isActive': isActive,
      'currentPortType': currentPortType,
      'lastReason': _lastReason,
      'lastConfiguredAt': _lastConfiguredAt?.toIso8601String() ?? 'never',
      'isConfiguring': _isConfiguring,
    };
  }
  
  /// CORRECTION #4: Exécution atomique d'une opération si CloudPort actif
  /// 
  /// Cette méthode garantit que la vérification isActive et l'exécution de l'opération
  /// sont atomiques, évitant ainsi les race conditions.
  /// 
  /// [operation] : L'opération à exécuter si le port est actif
  /// [onInactive] : La valeur à retourner si le port est inactif
  /// 
  /// Retourne le résultat de l'opération ou la valeur onInactive
  Future<T> executeIfActive<T>({
    required Future<T> Function() operation,
    required T Function() onInactive,
  }) async {
    // Première vérification
    if (!isActive) {
      _logger.warn('[CloudPortManager] executeIfActive: port inactif', code: 'cloud_port_inactive');
      return onInactive();
    }
    
    // Vérification atomique juste avant exécution
    final port = _currentPort;
    if (port == null || port is NoopCloudPersistenceAdapter) {
      _logger.warn('[CloudPortManager] executeIfActive: port NOOP détecté', code: 'cloud_port_noop', ctx: {
        'portType': port?.runtimeType.toString() ?? 'null',
      });
      return onInactive();
    }
    
    // Exécuter l'opération
    return await operation();
  }
}

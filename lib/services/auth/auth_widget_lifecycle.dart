// lib/services/auth/auth_widget_lifecycle.dart

import 'package:flutter/material.dart';
import '../api/auth_service.dart';

/// Mixin pour gérer correctement le cycle de vie des widgets pendant l'authentification
/// Ce mixin évite les erreurs liées à l'appel de setState sur un widget démonté
mixin AuthWidgetLifecycleMixin<T extends StatefulWidget> on State<T> {
  bool _isDisposed = false;
  bool _isAuthenticating = false;

  /// Indique si le widget actuel est démonté
  bool get isDisposed => _isDisposed;

  /// Indique si une authentification est en cours
  bool get isAuthenticating => _isAuthenticating;

  /// Remplacer cette méthode pour exécuter des actions supplémentaires après l'authentification
  /// Par exemple, naviguer vers une autre page
  void onAuthenticationSuccess() {}

  /// Remplacer cette méthode pour exécuter des actions supplémentaires en cas d'échec d'authentification
  void onAuthenticationFailure(Object error) {
    if (!_isDisposed) {
      debugPrint('Erreur d\'authentification: $error');
    }
  }

  /// Effectuer une connexion Google de manière sécurisée en gérant le cycle de vie du widget
  Future<bool> safeSignInWithGoogle({bool silent = false}) async {
    if (_isDisposed) {
      debugPrint('Tentative d\'authentification sur un widget démonté');
      return false;
    }

    try {
      setState(() => _isAuthenticating = true);
      
      // Utiliser skipStateUpdate pour éviter les mises à jour de l'état sur un widget potentiellement démonté
      final result = await AuthService().signInWithGoogle(
        silent: silent, 
        skipStateUpdate: true
      );
      
      if (!_isDisposed) {
        setState(() => _isAuthenticating = false);
        
        if (result) {
          onAuthenticationSuccess();
        }
      }
      
      return result;
    } catch (e) {
      if (!_isDisposed) {
        setState(() => _isAuthenticating = false);
        onAuthenticationFailure(e);
      }
      
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Widget qui écoute les changements d'état d'authentification
/// et reconstruire uniquement les parties concernées de l'interface
class AuthStateListener extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, bool) builder;

  const AuthStateListener({
    super.key,
    required this.child,
    required this.builder,
  });

  @override
  State<AuthStateListener> createState() => _AuthStateListenerState();
}

class _AuthStateListenerState extends State<AuthStateListener> {
  @override
  Widget build(BuildContext context) {
    // Utiliser ValueListenableBuilder pour n'écouter que les changements d'authentification
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService().authStateChanged, 
      builder: (context, isAuthenticated, child) {
        return widget.builder(context, isAuthenticated);
      },
      child: widget.child,
    );
  }
}

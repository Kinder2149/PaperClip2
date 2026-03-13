import 'package:cloud_functions/cloud_functions.dart';

/// Service unique encapsulant Firebase Cloud Functions (Callable)
/// Objectif: centraliser tous les appels serveur via Functions callable,
/// sans introduire de logique métier.
class FirebaseCallableService {
  FirebaseCallableService._();
  static final FirebaseCallableService instance = FirebaseCallableService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Appel générique d'une Function callable.
  /// - functionName: nom de la fonction déployée côté Firebase
  /// - payload: charge utile sérialisable (Map<String, dynamic> recommandé)
  /// Retourne la donnée décodée (payload) telle que renvoyée par la Function.
  Future<dynamic> call(String functionName, {Object? payload, HttpsCallableOptions? options}) async {
    final callable = _functions.httpsCallable(functionName, options: options);
    final result = await callable.call(payload);
    return result.data;
  }
}

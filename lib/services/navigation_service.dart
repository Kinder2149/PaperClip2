import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey;

  const NavigationService(this.navigatorKey);

  BuildContext? get currentContext => navigatorKey.currentContext;

  Future<T?> push<T>(Route<T> route) {
    return navigatorKey.currentState?.push(route) ?? Future.value(null);
  }

  Future<T?> pushReplacement<T, TO>(Route<T> route, {TO? result}) {
    return navigatorKey.currentState?.pushReplacement(route, result: result) ?? Future.value(null);
  }
}

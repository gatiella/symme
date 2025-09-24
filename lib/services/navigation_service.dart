import 'package:flutter/material.dart';

class NavigationService {
  // Import the global navigator key from main.dart
  static GlobalKey<NavigatorState>? _navigatorKey;

  // Initialize with the navigator key from main.dart
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static GlobalKey<NavigatorState> get navigatorKey {
    if (_navigatorKey == null) {
      throw Exception(
        'NavigationService not initialized. Call NavigationService.initialize() first.',
      );
    }
    return _navigatorKey!;
  }

  static BuildContext? get currentContext => _navigatorKey?.currentContext;

  static Future<T?>? push<T extends Object?>(Widget page) {
    return _navigatorKey?.currentState?.push<T>(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static Future<T?>? pushReplacement<T extends Object?, TO extends Object?>(
    Widget page,
  ) {
    return _navigatorKey?.currentState?.pushReplacement<T, TO>(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void pop<T extends Object?>([T? result]) {
    return _navigatorKey?.currentState?.pop<T>(result);
  }

  static Future<T?>? pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _navigatorKey?.currentState?.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  static void popUntil(bool Function(Route<dynamic>) predicate) {
    return _navigatorKey?.currentState?.popUntil(predicate);
  }
}

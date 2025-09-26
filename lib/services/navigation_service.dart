import 'package:flutter/material.dart';

class NavigationService {
<<<<<<< HEAD
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
=======
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void initialize() {
    // No initialization needed for this simple service
  }

  static BuildContext get currentContext => navigatorKey.currentContext!;

  static Future<T?>? push<T extends Object?>(
    Widget page,
  ) {
    return navigatorKey.currentState?.push<T>(
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static Future<T?>? pushReplacement<T extends Object?, TO extends Object?>(
    Widget page,
  ) {
<<<<<<< HEAD
    return _navigatorKey?.currentState?.pushReplacement<T, TO>(
=======
    return navigatorKey.currentState?.pushReplacement<T, TO>(
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void pop<T extends Object?>([T? result]) {
<<<<<<< HEAD
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
=======
    return navigatorKey.currentState?.pop<T>(result);
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
  }
}

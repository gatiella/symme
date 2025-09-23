import 'package:flutter/material.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void initialize() {
    // No initialization needed for this simple service
  }

  static BuildContext get currentContext => navigatorKey.currentContext!;

  static Future<T?>? push<T extends Object?>(
    Widget page,
  ) {
    return navigatorKey.currentState?.push<T>(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static Future<T?>? pushReplacement<T extends Object?, TO extends Object?>(
    Widget page,
  ) {
    return navigatorKey.currentState?.pushReplacement<T, TO>(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void pop<T extends Object?>([T? result]) {
    return navigatorKey.currentState?.pop<T>(result);
  }
}

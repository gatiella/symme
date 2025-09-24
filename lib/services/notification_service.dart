import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:symme/main.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static bool _initialMessageHandled = false;
  
  // Initialize notification service
  static Future<void> initialize() async {
    try {
      print('Initializing notification service...');
      
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized || 
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted notification permissions');
        
        // Initialize local notifications
        await _initializeLocalNotifications();
        
        // Get and store FCM token
        await _getFCMToken();
        
        // Setup message handlers (but NOT initial message here)
        _setupMessageHandlers();
        
        print('Notification service initialized successfully');
      } else {
        print('User declined or has not granted notification permissions');
      }
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  // Call this method AFTER your navigation is ready (e.g., in main.dart after MaterialApp is built)
  static Future<void> handleInitialMessage() async {
    if (_initialMessageHandled) return;
    
    try {
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      
      if (initialMessage != null) {
        print('App opened from terminated state with message: ${initialMessage.messageId}');
        print('Message data: ${initialMessage.data}');
        
        // Wait a bit to ensure navigation is fully ready
        await Future.delayed(const Duration(milliseconds: 500));
        
        _handleMessageOpenedApp(initialMessage);
      }
      
      _initialMessageHandled = true;
    } catch (e) {
      print('Error handling initial message: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  // Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'messages_channel',
      'Message Notifications',
      description: 'Notifications for new messages',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Get and store FCM token - THIS IS THE METHOD YOUR AUTH SERVICE CALLS
  static Future<String?> getFCMToken() async {
    try {
      if (_fcmToken != null) {
        print('Returning cached FCM token');
        return _fcmToken;
      }
      
      _fcmToken = await _messaging.getToken();
      print('FCM Token obtained: ${_fcmToken?.substring(0, 20)}...');
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: ${newToken.substring(0, 20)}...');
      });
      
      return _fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Internal method for initial token setup
  static Future<String?> _getFCMToken() async {
    return await getFCMToken();
  }

  // Setup message handlers (without initial message)
  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app from background: ${message.messageId}');
      _handleMessageOpenedApp(message);
    });

    // NOTE: getInitialMessage() is now handled separately in handleInitialMessage()
  }

  // Show local notification when app is in foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'messages_channel',
        'Message Notifications',
        channelDescription: 'Notifications for new messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF00BCD4), // Your app's primary color
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        details,
        payload: json.encode(message.data),
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Handle notification tap
  static void _handleNotificationTap(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        print('Notification tapped with data: $data');
        
        // Navigate to appropriate screen based on notification data
        _navigateFromNotification(data);
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  // Handle message when app is opened from notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.data}');
    _navigateFromNotification(message.data);
  }

  // Navigate to appropriate screen based on notification data
static void _navigateFromNotification(Map<String, dynamic> data) {
  try {
    final type = data['type'] as String?;
    
    if (type == 'message') {
      final senderId = data['senderId'] as String?;
      if (senderId != null) {
        // Navigate to chat screen with sender using the global navigator key
        print('Navigating to chat with: $senderId');
        
        // Get the current context from the navigator
        final BuildContext? context = navigatorKey.currentContext;
        
        if (context != null) {
          // Option 1: Using named routes
          navigatorKey.currentState?.pushNamed(
            '/chat',
            arguments: {'senderId': senderId},
          );
          
          // Option 2: Direct navigation (alternative to named routes)
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => ChatScreen(senderId: senderId),
          //   ),
          // );
        } else {
          print('Navigator context is null, cannot navigate');
        }
      }
    } else if (type == 'contact_request') {
      final requesterId = data['requesterId'] as String?;
      if (requesterId != null) {
        print('Navigating to contact request from: $requesterId');
        navigatorKey.currentState?.pushNamed(
          '/contact-requests',
          arguments: {'requesterId': requesterId},
        );
      }
    }
    // Add more notification types as needed
    
  } catch (e) {
    print('Error navigating from notification: $e');
  }
}

  // Send push notification to a specific user
  static Future<bool> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Replace with your actual FCM server key
      const String serverKey = 'YOUR_FCM_SERVER_KEY_HERE';
      
      final Map<String, dynamic> notification = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': data ?? {},
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: json.encode(notification),
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully');
        return true;
      } else {
        print('Failed to send push notification: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  // Get current FCM token
  static String? get fcmToken => _fcmToken;

  // Refresh FCM token
  static Future<String?> refreshFCMToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      return await getFCMToken();
    } catch (e) {
      print('Error refreshing FCM token: $e');
      return _fcmToken; // Return existing token if refresh fails
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('All notifications cleared');
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // Clear specific notification
  static Future<void> clearNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      print('Notification $id cleared');
    } catch (e) {
      print('Error clearing notification $id: $e');
    }
  }

  // Handle background message (static method for Firebase)
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    
    // Process the message here if needed
    // For example, you could update local database, etc.
    
    // The notification will be handled automatically by FCM
    // unless you need custom processing
  }
}
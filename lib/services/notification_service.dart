import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:symme/main.dart';
import 'package:symme/models/call.dart';
import 'package:symme/screens/call_screen.dart';
import 'package:symme/services/call_manager.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;
  static bool _initialMessageHandled = false;

  // Your service account JSON - store this securely in production
  static const String _serviceAccountJson = '''
{



}''';

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
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null) {
        print(
          'App opened from terminated state with message: ${initialMessage.messageId}',
        );
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

    // Create both message and call notification channels
    await _createNotificationChannel();
    await _createCallNotificationChannel();
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
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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

      // Check if it's a call notification
      final isCallNotification = message.data['type'] == 'incoming_call';

      AndroidNotificationDetails androidDetails;

      if (isCallNotification) {
        // Create call notification with action buttons
        androidDetails = const AndroidNotificationDetails(
          'calls_channel',
          'Call Notifications',
          channelDescription: 'Notifications for incoming calls',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00BCD4),
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          actions: [
            AndroidNotificationAction(
              'answer_call',
              'Answer',
              showsUserInterface: true,
            ),
            AndroidNotificationAction('decline_call', 'Decline'),
          ],
        );
      } else {
        // Create regular message notification
        androidDetails = const AndroidNotificationDetails(
          'messages_channel',
          'Message Notifications',
          channelDescription: 'Notifications for new messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00BCD4),
          enableVibration: true,
          category: AndroidNotificationCategory.message,
        );
      }

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical, // For calls
      );

      final NotificationDetails details = NotificationDetails(
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

  static Future<void> _createCallNotificationChannel() async {
    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'calls_channel',
      'Call Notifications',
      description: 'Notifications for incoming calls',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(callChannel);
  }

  // Handle notification tap
  static void _handleNotificationTap(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        print('Notification tapped with data: $data');

        // Handle call notification actions
        if (response.actionId == 'answer_call') {
          print('User chose to answer call');
          _handleCallAction(data, 'answer');
        } else if (response.actionId == 'decline_call') {
          print('User chose to decline call');
          _handleCallAction(data, 'decline');
        } else {
          // Regular notification tap - navigate to appropriate screen
          _navigateFromNotification(data);
        }
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  // Add this new method to handle call actions
  static void _handleCallAction(Map<String, dynamic> data, String action) {
    try {
      final callId = data['callId'] as String?;
      final callerId = data['callerId'] as String?;
      final callTypeString = data['callType'] as String?;

      if (callId != null && callerId != null && callTypeString != null) {
        final callType = callTypeString == 'video'
            ? CallType.video
            : CallType.audio;

        final call = Call(
          id: callId,
          callerId: callerId,
          receiverId: '',
          type: callType,
          status: CallStatus.incoming,
          timestamp: DateTime.now(),
          callerName: callerId,
        );

        if (action == 'answer') {
          // Answer the call through CallManager
          CallManager.instance.answerCall(call).catchError((e) {
            print('Error answering call from notification: $e');
          });
        } else if (action == 'decline') {
          // Decline the call through CallManager
          CallManager.instance.declineCall(call).catchError((e) {
            print('Error declining call from notification: $e');
          });
        }
      }
    } catch (e) {
      print('Error handling call action: $e');
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

      if (type == 'incoming_call') {
        // Handle incoming call notification
        final callId = data['callId'] as String?;
        final callerId = data['callerId'] as String?;
        final callTypeString = data['callType'] as String?;

        if (callId != null && callerId != null && callTypeString != null) {
          print('Opening app for incoming call: $callId from $callerId');

          // Convert string back to CallType enum
          final callType = callTypeString == 'video'
              ? CallType.video
              : CallType.audio;

          // Create a Call object for the notification
          final call = Call(
            id: callId,
            callerId:
                callerId, // This should be the user ID, but we're using secure ID for now
            receiverId: '', // Will be filled by CallManager
            type: callType,
            status: CallStatus.incoming,
            timestamp: DateTime.now(),
            callerName: callerId, // Using secure ID as display name
          );

          // Navigate to call screen or trigger CallManager to handle it
          // You might want to use CallManager.instance to handle this
          final BuildContext? context = navigatorKey.currentContext;
          if (context != null) {
            // Option 1: Navigate directly to call screen
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => CallScreen(call: call, isIncoming: true),
              ),
            );

            // Option 2: Or trigger CallManager (preferred)
            // CallManager.instance.handleNotificationCall(call);
          }
        }
      } else if (type == 'message') {
        final senderId = data['senderId'] as String?;
        if (senderId != null) {
          print('Navigating to chat with: $senderId');
          final BuildContext? context = navigatorKey.currentContext;
          if (context != null) {
            navigatorKey.currentState?.pushNamed(
              '/chat',
              arguments: {'senderId': senderId},
            );
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
    } catch (e) {
      print('Error navigating from notification: $e');
    }
  }

  // UPDATED: Send push notification using service account
  static Future<bool> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get access token using service account
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        print('Failed to get access token');
        return false;
      }

      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'data':
              data?.map((key, value) => MapEntry(key, value.toString())) ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'messages_channel',
              'sound': 'default',
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default', 'content-available': 1},
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/symme-a0f87/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully');
        return true;
      } else {
        print(
          'Failed to send push notification: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  // Get OAuth2 access token using service account
  static Future<String?> _getAccessToken() async {
    try {
      final serviceAccount = ServiceAccountCredentials.fromJson(
        _serviceAccountJson,
      );
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = http.Client();
      try {
        final credentials = await obtainAccessCredentialsViaServiceAccount(
          serviceAccount,
          scopes,
          client,
        );

        return credentials.accessToken.data;
      } finally {
        client.close();
      }
    } catch (e) {
      print('Error getting access token: $e');
      return null;
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
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Handling background message: ${message.messageId}');

    // Process the message here if needed
    // For example, you could update local database, etc.

    // The notification will be handled automatically by FCM
    // unless you need custom processing
  }
}

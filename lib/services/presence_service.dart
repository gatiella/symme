// services/presence_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';

class PresenceService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static StreamSubscription<DatabaseEvent>? _presenceSubscription;
  static StreamSubscription<DatabaseEvent>? _connectionSubscription;
  static Timer? _heartbeatTimer;
  static bool _isInitialized = false;

  // Online threshold - users are considered offline after 2 minutes of inactivity
  static const int _onlineThresholdMinutes = 2;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Monitor connection state
      _monitorConnection(currentUser.uid);

      // Start presence updates
      await _startPresenceUpdates(currentUser.uid);

      _isInitialized = true;
      print('Presence service initialized');
    } catch (e) {
      print('Error initializing presence service: $e');
    }
  }

  static void _monitorConnection(String userId) {
    final connectedRef = _database.ref('.info/connected');

    _connectionSubscription = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;

      if (connected) {
        print('Connected to Firebase');
        _setUserOnline(userId);
        _startHeartbeat(userId);
      } else {
        print('Disconnected from Firebase');
        _heartbeatTimer?.cancel();
      }
    });
  }

  static Future<void> _startPresenceUpdates(String userId) async {
    // Set user online
    await _setUserOnline(userId);

    // Setup offline trigger when app disconnects
    final userPresenceRef = _database.ref('presence/$userId');
    await userPresenceRef.onDisconnect().update({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });

    // Start periodic heartbeat
    _startHeartbeat(userId);
  }

  static void _startHeartbeat(String userId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _setUserOnline(userId),
    );
  }

  static Future<void> _setUserOnline(String userId) async {
    try {
      final userSecureId = await StorageService.getUserSecureId();
      if (userSecureId == null) return;

      await _database.ref('presence/$userId').update({
        'online': true,
        'lastSeen': ServerValue.timestamp,
        'secureId': userSecureId,
      });
    } catch (e) {
      print('Error setting user online: $e');
    }
  }

  static Future<void> setUserOffline() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _database.ref('presence/${currentUser.uid}').update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });

      _heartbeatTimer?.cancel();
    } catch (e) {
      print('Error setting user offline: $e');
    }
  }

  // Check if a specific user is online
  static Future<bool> isUserOnline(String userId) async {
    try {
      final snapshot = await _database.ref('presence/$userId').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return false;

      final isOnline = data['online'] as bool? ?? false;
      if (!isOnline) return false;

      // Check last seen time
      final lastSeen = data['lastSeen'] as int?;
      if (lastSeen == null) return false;

      final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
      final timeDiff = DateTime.now().difference(lastSeenTime);

      // Consider offline if last seen more than threshold
      return timeDiff.inMinutes < _onlineThresholdMinutes;
    } catch (e) {
      print('Error checking user online status: $e');
      return false;
    }
  }

  // Get user's last seen time
  static Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final snapshot = await _database.ref('presence/$userId').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return null;

      final lastSeen = data['lastSeen'] as int?;
      if (lastSeen == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(lastSeen);
    } catch (e) {
      print('Error getting user last seen: $e');
      return null;
    }
  }

  // Listen to user's online status changes
  static Stream<bool> listenToUserPresence(String userId) {
    final controller = StreamController<bool>();

    final presenceRef = _database.ref('presence/$userId');
    StreamSubscription<DatabaseEvent>? subscription;

    subscription = presenceRef.onValue.listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data == null) {
          controller.add(false);
          return;
        }

        final isOnline = data['online'] as bool? ?? false;
        if (!isOnline) {
          controller.add(false);
          return;
        }

        // Check last seen time
        final lastSeen = data['lastSeen'] as int?;
        if (lastSeen == null) {
          controller.add(false);
          return;
        }

        final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
        final timeDiff = DateTime.now().difference(lastSeenTime);

        controller.add(timeDiff.inMinutes < _onlineThresholdMinutes);
      },
      onError: (error) {
        print('Error listening to presence: $error');
        controller.add(false);
      },
    );

    controller.onCancel = () {
      subscription?.cancel();
    };

    return controller.stream;
  }

  // Get all online users (for debugging)
  static Future<Map<String, Map<String, dynamic>>> getOnlineUsers() async {
    try {
      final snapshot = await _database.ref('presence').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return {};

      final onlineUsers = <String, Map<String, dynamic>>{};
      final now = DateTime.now();

      data.forEach((userId, userData) {
        final userMap = userData as Map<dynamic, dynamic>;
        final isOnline = userMap['online'] as bool? ?? false;
        final lastSeen = userMap['lastSeen'] as int?;

        if (isOnline && lastSeen != null) {
          final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
          final timeDiff = now.difference(lastSeenTime);

          if (timeDiff.inMinutes < _onlineThresholdMinutes) {
            onlineUsers[userId.toString()] = {
              'online': true,
              'lastSeen': lastSeenTime,
              'secureId': userMap['secureId'],
            };
          }
        }
      });

      return onlineUsers;
    } catch (e) {
      print('Error getting online users: $e');
      return {};
    }
  }

  // Check if user is online by secure ID
  static Future<bool> isUserOnlineBySecureId(String secureId) async {
    try {
      // First find the user ID from secure ID
      final users = await getOnlineUsers();

      for (final entry in users.entries) {
        final userData = entry.value;
        if (userData['secureId'] == secureId) {
          return true; // Already filtered for online users
        }
      }

      return false;
    } catch (e) {
      print('Error checking user online by secure ID: $e');
      return false;
    }
  }

  static void dispose() {
    _heartbeatTimer?.cancel();
    _presenceSubscription?.cancel();
    _connectionSubscription?.cancel();
    _isInitialized = false;
  }
}

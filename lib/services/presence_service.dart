import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';

class PresenceService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static StreamSubscription<DatabaseEvent>? _connectionSubscription;
  static Timer? _heartbeatTimer;
  static bool _isInitialized = false;
  static String? _currentUserId;

  // Online threshold - users are considered offline after 3 minutes of inactivity
  static const int _onlineThresholdMinutes = 3;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      _currentUserId = currentUser.uid;
      print('Initializing presence service for user: $_currentUserId');

      // Monitor connection state
      _monitorConnection();

      _isInitialized = true;
      print('Presence service initialized');
    } catch (e) {
      print('Error initializing presence service: $e');
    }
  }

  static void _monitorConnection() {
    final connectedRef = _database.ref('.info/connected');

    _connectionSubscription = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      print('Firebase connection status: $connected');

      if (connected && _currentUserId != null) {
        print('Connected to Firebase - setting user online');
        _setUserOnline();
        _setupOnDisconnect();
        _startHeartbeat();
      } else {
        print('Disconnected from Firebase');
        _heartbeatTimer?.cancel();
      }
    });
  }

  static Future<void> _setupOnDisconnect() async {
    if (_currentUserId == null) return;

    try {
      // Set up what happens when user disconnects
      final userPresenceRef = _database.ref('presence/$_currentUserId');
      await userPresenceRef.onDisconnect().update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
        'disconnectedAt': ServerValue.timestamp,
      });
      print('OnDisconnect handler set up');
    } catch (e) {
      print('Error setting up onDisconnect: $e');
    }
  }

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        print('Heartbeat - updating presence');
        _setUserOnline();
      },
    );
    print('Heartbeat timer started');
  }

  static Future<void> _setUserOnline() async {
    if (_currentUserId == null) return;

    try {
      final userSecureId = await StorageService.getUserSecureId();
      if (userSecureId == null) {
        print('No secure ID found, cannot set user online');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _database.ref('presence/$_currentUserId').set({
        'online': true,
        'lastSeen': now,
        'secureId': userSecureId,
        'updatedAt': ServerValue.timestamp,
      });
      print('User set online with lastSeen: $now');
    } catch (e) {
      print('Error setting user online: $e');
    }
  }

  static Future<void> setUserOffline() async {
    if (_currentUserId == null) return;

    try {
      await _database.ref('presence/$_currentUserId').update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
        'offlineAt': ServerValue.timestamp,
      });

      _heartbeatTimer?.cancel();
      print('User set offline manually');
    } catch (e) {
      print('Error setting user offline: $e');
    }
  }

  // Check if a specific user is online
  static Future<bool> isUserOnline(String userId) async {
    try {
      final snapshot = await _database.ref('presence/$userId').once();
      if (!snapshot.snapshot.exists) {
        print('No presence data for user: $userId');
        return false;
      }

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final isOnline = data['online'] as bool? ?? false;
      final lastSeen = data['lastSeen'] as int?;

      print('User $userId - online: $isOnline, lastSeen: $lastSeen');

      if (!isOnline || lastSeen == null) return false;

      // Check if last seen is within threshold
      final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
      final timeDiff = DateTime.now().difference(lastSeenTime);
      final isRecentlyActive = timeDiff.inMinutes < _onlineThresholdMinutes;

      print('Time difference: ${timeDiff.inMinutes} minutes, threshold: $_onlineThresholdMinutes');
      return isRecentlyActive;
    } catch (e) {
      print('Error checking user online status: $e');
      return false;
    }
  }

  // Check if user is online by secure ID
  static Future<bool> isUserOnlineBySecureId(String secureId) async {
    try {
      // Query all users to find the one with matching secure ID
      final snapshot = await _database.ref('presence').once();
      if (!snapshot.snapshot.exists) return false;

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final userData = entry.value as Map<dynamic, dynamic>;
        final userSecureId = userData['secureId'] as String?;

        if (userSecureId == secureId) {
          final userId = entry.key as String;
          return await isUserOnline(userId);
        }
      }

      return false;
    } catch (e) {
      print('Error checking user online by secure ID: $e');
      return false;
    }
  }

  // Listen to user's online status changes
  static Stream<bool> listenToUserPresence(String userId) {
    final controller = StreamController<bool>.broadcast();

    final presenceRef = _database.ref('presence/$userId');
    StreamSubscription<DatabaseEvent>? subscription;

    subscription = presenceRef.onValue.listen(
      (event) {
        if (!event.snapshot.exists) {
          controller.add(false);
          return;
        }

        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final isOnline = data['online'] as bool? ?? false;
        final lastSeen = data['lastSeen'] as int?;

        if (!isOnline || lastSeen == null) {
          controller.add(false);
          return;
        }

        final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
        final timeDiff = DateTime.now().difference(lastSeenTime);
        final isRecentlyActive = timeDiff.inMinutes < _onlineThresholdMinutes;

        controller.add(isRecentlyActive);
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

  // Get user's last seen time
  static Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final snapshot = await _database.ref('presence/$userId/lastSeen').once();
      final lastSeen = snapshot.snapshot.value as int?;

      if (lastSeen == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(lastSeen);
    } catch (e) {
      print('Error getting user last seen: $e');
      return null;
    }
  }

  static void dispose() {
    print('Disposing presence service');
    _heartbeatTimer?.cancel();
    _connectionSubscription?.cancel();
    if (_currentUserId != null) {
      setUserOffline();
    }
    _isInitialized = false;
    _currentUserId = null;
  }
}
// services/call_service.dart - Fixed version
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:symme/services/firebase_auth_service.dart';
<<<<<<< HEAD
import 'package:symme/services/notification_service.dart';
=======
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
import '../models/call.dart';
import '../services/storage_service.dart';
import '../services/presence_service.dart';

class CallService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final StreamController<Call> _incomingCallController =
<<<<<<< HEAD
      StreamController.broadcast();
  static final StreamController<Map<String, dynamic>> _callSignalController =
      StreamController.broadcast();
=======
  StreamController.broadcast();
  static final StreamController<Map<String, dynamic>> _callSignalController =
  StreamController.broadcast();
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

  static Stream<Call> get incomingCalls => _incomingCallController.stream;
  static Stream<Map<String, dynamic>> get callSignals =>
      _callSignalController.stream;

  static StreamSubscription<DatabaseEvent>? _callsSubscription;
  static StreamSubscription<DatabaseEvent>? _signalsSubscription;

  // Track processed calls and signals to prevent duplicates
  static final Set<String> _processedCalls = <String>{};
  static final Set<String> _processedSignals = <String>{};

  // Track pending calls for timeout handling
  static final Map<String, Timer> _pendingCallTimers = {};

  static Future<void> initialize() async {
    await PresenceService.initialize();

    // Clear processed sets on initialize
    _processedCalls.clear();
    _processedSignals.clear();

    await _listenForCalls();
    await _listenForCallSignals();
  }

  static Future<void> _listenForCalls() async {
    try {
      // Cancel existing subscription first
      await _callsSubscription?.cancel();

      final currentUserId = await StorageService.getUserId();
      if (currentUserId == null) return;

      _callsSubscription = _database
          .ref('calls')
          .orderByChild('receiverId')
          .equalTo(currentUserId)
          .onValue
          .listen(
            (event) {
<<<<<<< HEAD
              if (event.snapshot.exists) {
                final data = event.snapshot.value as Map<dynamic, dynamic>;

                data.forEach((callId, callData) {
                  final callIdStr = callId.toString();

                  // Skip if already processed
                  if (_processedCalls.contains(callIdStr)) {
                    return;
                  }

                  if (callData is Map<dynamic, dynamic>) {
                    final status = callData['status'] as String?;

                    if (status == 'incoming') {
                      try {
                        final call = Call.fromJson(
                          Map<String, dynamic>.from(callData),
                        );

                        // Mark as processed before adding to stream
                        _processedCalls.add(callIdStr);

                        _incomingCallController.add(call);
                        _setIncomingCallTimeout(callIdStr);
                        print('Added incoming call: $callIdStr');
                      } catch (e) {
                        print('Error parsing incoming call: $e');
                      }
                    } else if (status == 'connected' ||
                        status == 'declined' ||
                        status == 'ended') {
                      _cancelCallTimeout(callIdStr);
                      // Remove from processed when call ends
                      _processedCalls.remove(callIdStr);
                    }
                  }
                });
              }
            },
            onError: (error) {
              print('Error listening for calls: $error');
            },
          );
=======
          if (event.snapshot.exists) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;

            data.forEach((callId, callData) {
              final callIdStr = callId.toString();

              // Skip if already processed
              if (_processedCalls.contains(callIdStr)) {
                return;
              }

              if (callData is Map<dynamic, dynamic>) {
                final status = callData['status'] as String?;

                if (status == 'incoming') {
                  try {
                    final call = Call.fromJson(
                      Map<String, dynamic>.from(callData),
                    );

                    // Mark as processed before adding to stream
                    _processedCalls.add(callIdStr);

                    _incomingCallController.add(call);
                    _setIncomingCallTimeout(callIdStr);
                    print('Added incoming call: $callIdStr');
                  } catch (e) {
                    print('Error parsing incoming call: $e');
                  }
                } else if (status == 'connected' ||
                    status == 'declined' ||
                    status == 'ended') {
                  _cancelCallTimeout(callIdStr);
                  // Remove from processed when call ends
                  _processedCalls.remove(callIdStr);
                }
              }
            });
          }
        },
        onError: (error) {
          print('Error listening for calls: $error');
        },
      );
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
    } catch (e) {
      print('Error setting up call listener: $e');
    }
  }

  static Future<void> _listenForCallSignals() async {
    try {
      // Cancel existing subscription first
      await _signalsSubscription?.cancel();

      final currentUserId = await StorageService.getUserId();
      if (currentUserId == null) return;

      _signalsSubscription = _database
          .ref('call_signals')
          .orderByChild('receiverId')
          .equalTo(currentUserId)
          .onValue
          .listen(
            (event) {
<<<<<<< HEAD
              if (event.snapshot.exists) {
                final data = event.snapshot.value as Map<dynamic, dynamic>;

                data.forEach((signalId, signalData) async {
                  final signalIdStr = signalId.toString();

                  if (_processedSignals.contains(signalIdStr)) {
                    return;
                  }

                  if (signalData is Map) {
                    // Changed from Map<dynamic, dynamic>
                    try {
                      _processedSignals.add(signalIdStr);

                      // Safe conversion to Map<String, dynamic>
                      final signal = <String, dynamic>{};
                      signalData.forEach((key, value) {
                        signal[key.toString()] = value;
                      });

                      // Ensure required fields exist with safe defaults
                      if (!signal.containsKey('type') ||
                          !signal.containsKey('callId')) {
                        print('Invalid signal structure: $signal');
                        return;
                      }

                      // Ensure data field is properly formatted
                      if (!signal.containsKey('data') ||
                          signal['data'] == null) {
                        signal['data'] = <String, dynamic>{};
                      } else if (signal['data'] is Map &&
                          signal['data'] is! Map<String, dynamic>) {
                        final rawData = signal['data'] as Map;
                        signal['data'] = <String, dynamic>{};
                        rawData.forEach((key, value) {
                          signal['data'][key.toString()] = value;
                        });
                      }

                      _callSignalController.add(signal);
                      print(
                        'Received call signal: ${signal['type']} for call ${signal['callId']}',
                      );

                      await _database.ref('call_signals/$signalIdStr').remove();
                    } catch (e) {
                      print('Error processing call signal: $e');
                    }
                  }
                });
              }
            },
            onError: (error) {
              print('Error listening for call signals: $error');
            },
          );
=======
          if (event.snapshot.exists) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;

          data.forEach((signalId, signalData) async {
              final signalIdStr = signalId.toString();

              if (_processedSignals.contains(signalIdStr)) {
                return;
              }

              if (signalData is Map) { // Changed from Map<dynamic, dynamic>
                try {
                  _processedSignals.add(signalIdStr);

                  // Safe conversion to Map<String, dynamic>
                  final signal = <String, dynamic>{};
                  signalData.forEach((key, value) {
                    signal[key.toString()] = value;
                  });

                  // Ensure required fields exist with safe defaults
                  if (!signal.containsKey('type') ||
                      !signal.containsKey('callId')) {
                    print('Invalid signal structure: $signal');
                    return;
                  }

                  // Ensure data field is properly formatted
                  if (!signal.containsKey('data') || signal['data'] == null) {
                    signal['data'] = <String, dynamic>{};
                  } else if (signal['data'] is Map && signal['data'] is! Map<String, dynamic>) {
                    final rawData = signal['data'] as Map;
                    signal['data'] = <String, dynamic>{};
                    rawData.forEach((key, value) {
                      signal['data'][key.toString()] = value;
                    });
                  }

                  _callSignalController.add(signal);
                  print('Received call signal: ${signal['type']} for call ${signal['callId']}');

                  await _database.ref('call_signals/$signalIdStr').remove();
                } catch (e) {
                  print('Error processing call signal: $e');
                }
              }
            });
          }
        },
        onError: (error) {
          print('Error listening for call signals: $error');
        },
      );
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
    } catch (e) {
      print('Error setting up call signals listener: $e');
    }
  }

  static Future<Call?> initiateCall({
    required String receiverSecureId,
    required CallType callType,
  }) async {
    try {
      print('Initiating call to secure ID: $receiverSecureId');

      final currentUserId = await StorageService.getUserId();
      final currentUserSecureId = await StorageService.getUserSecureId();

      if (currentUserId == null || currentUserSecureId == null) {
        print(
          'ERROR: Missing current user data - userId: $currentUserId, secureId: $currentUserSecureId',
        );
        throw Exception('User not authenticated');
      }

      print('Current user: $currentUserId, secure ID: $currentUserSecureId');

      // Check if receiver is online FIRST
      print('Checking if receiver is online...');
      final isOnline = await PresenceService.isUserOnlineBySecureId(
        receiverSecureId,
      );
      if (!isOnline) {
        print('Receiver is not online: $receiverSecureId');
        throw Exception('User is not available for calls right now');
      }
      print('Receiver is online, proceeding with call');

      // Get receiver user data
      Map<String, dynamic>? receiverData;
      String? receiverUserId;

      try {
        receiverData = await FirebaseAuthService.getUserBySecureId(
          receiverSecureId,
        );
        receiverUserId = receiverData != null
            ? receiverData['userId'] as String?
            : null;
        print('Found receiver via FirebaseAuthService: $receiverUserId');
      } catch (e) {
        print('Error getting user from FirebaseAuthService: $e');
      }

      if (receiverUserId == null) {
        print('ERROR: Receiver not found for secure ID: $receiverSecureId');
        throw Exception('User not found');
      }

      // Check if receiver is currently in a call
      final hasActiveCall = await _isUserInCall(receiverUserId);
      if (hasActiveCall) {
        print('Receiver is already in a call');
        throw Exception('User is currently in another call');
      }

      final callId = DateTime.now().millisecondsSinceEpoch.toString();
      print('Creating call with ID: $callId');

      final call = Call(
        id: callId,
        callerId: currentUserId,
        receiverId: receiverUserId,
        type: callType,
        status: CallStatus.outgoing,
        timestamp: DateTime.now(),
        callerName: currentUserSecureId,
        receiverName: receiverSecureId,
      );

      // Save call record to Realtime Database with incoming status for receiver
      print('Saving call record to Realtime Database...');
      final callData = call.toJson();
      callData['status'] = 'incoming'; // Receiver sees it as incoming
      await _database.ref('calls/$callId').set(callData);
      print('Call record saved successfully');

      // Set timeout for outgoing call (30 seconds)
      _setOutgoingCallTimeout(callId);

      // Send the call signal immediately with proper data structure
      print('Sending call signal...');
      final signalSent = await sendCallSignal(
        receiverId: receiverUserId,
        callId: callId,
        type: 'offer',
<<<<<<< HEAD
        data: <String, dynamic>{},
=======
        data: <String, dynamic>{}, // Ensure data is never null
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        callType: callType,
      );

      if (!signalSent) {
        print('Warning: Failed to send initial call signal');
      }

<<<<<<< HEAD
      // ADD THIS: Send push notification for incoming call
      try {
        await _sendCallNotification(
          receiverUserId: receiverUserId,
          callerSecureId: currentUserSecureId,
          callId: callId,
          callType: callType,
        );
      } catch (e) {
        print('Warning: Failed to send call notification: $e');
      }

=======
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      return call;
    } catch (e) {
      print('Error initiating call: $e');
      rethrow;
    }
  }

<<<<<<< HEAD
  // ADD THIS NEW METHOD to call_service.dart
  static Future<void> _sendCallNotification({
    required String receiverUserId,
    required String callerSecureId,
    required String callId,
    required CallType callType,
  }) async {
    try {
      // Get receiver's FCM token from Firebase
      final receiverSnapshot = await _database
          .ref('users/$receiverUserId/fcmToken')
          .once();
      final fcmToken = receiverSnapshot.snapshot.value as String?;

      if (fcmToken == null) {
        print('No FCM token found for receiver: $receiverUserId');
        return;
      }

      // Create call notification
      final callTypeText = callType == CallType.video
          ? 'Video call'
          : 'Voice call';
      final title = '$callTypeText from $callerSecureId';
      final body = 'Tap to answer';

      final success = await NotificationService.sendPushNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: {
          'type': 'incoming_call',
          'callId': callId,
          'callerId': callerSecureId,
          'callType': callType.toString().split('.').last,
          'action': 'incoming_call',
        },
      );

      if (success) {
        print('Call notification sent successfully');
      } else {
        print('Failed to send call notification');
      }
    } catch (e) {
      print('Error sending call notification: $e');
    }
  }

=======
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
  static Future<bool> _isUserInCall(String userId) async {
    try {
      // Check if user has any active calls as receiver
      final receiverCallsSnapshot = await _database
          .ref('calls')
          .orderByChild('receiverId')
          .equalTo(userId)
          .once();

      if (receiverCallsSnapshot.snapshot.exists) {
        final data =
<<<<<<< HEAD
            receiverCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
=======
        receiverCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        for (final callData in data.values) {
          if (callData is Map<dynamic, dynamic>) {
            final status = callData['status'] as String?;
            if (status == 'incoming' ||
                status == 'connecting' ||
                status == 'connected') {
              return true;
            }
          }
        }
      }

      // Check if user has any active calls as caller
      final callerCallsSnapshot = await _database
          .ref('calls')
          .orderByChild('callerId')
          .equalTo(userId)
          .once();

      if (callerCallsSnapshot.snapshot.exists) {
        final data =
<<<<<<< HEAD
            callerCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
=======
        callerCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        for (final callData in data.values) {
          if (callData is Map<dynamic, dynamic>) {
            final status = callData['status'] as String?;
            if (status == 'outgoing' ||
                status == 'connecting' ||
                status == 'connected') {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking if user is in call: $e');
      return false;
    }
  }

  static void _setOutgoingCallTimeout(String callId) {
    _pendingCallTimers[callId] = Timer(const Duration(seconds: 30), () async {
      print('Outgoing call timeout for call: $callId');
      await _handleCallTimeout(callId, isOutgoing: true);
    });
  }

  static void _setIncomingCallTimeout(String callId) {
    _pendingCallTimers[callId] = Timer(const Duration(seconds: 30), () async {
      print('Incoming call timeout for call: $callId');
      await _handleCallTimeout(callId, isOutgoing: false);
    });
  }

  static void _cancelCallTimeout(String callId) {
    final timer = _pendingCallTimers.remove(callId);
    timer?.cancel();
    print('Cancelled timeout for call: $callId');
  }

  static Future<void> _handleCallTimeout(
<<<<<<< HEAD
    String callId, {
    required bool isOutgoing,
  }) async {
=======
      String callId, {
        required bool isOutgoing,
      }) async {
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
    try {
      final status = isOutgoing ? 'no_answer' : 'missed';

      await _database.ref('calls/$callId').update({
        'status': status,
        'endedAt': ServerValue.timestamp,
        'timeoutReason': isOutgoing ? 'no_answer' : 'missed',
      });

      print('Call $callId marked as $status due to timeout');
      _pendingCallTimers.remove(callId);
      _processedCalls.remove(callId); // Remove from processed set

      // If it was an outgoing call, notify through call signals that it timed out
      if (isOutgoing) {
        try {
          final callSnapshot = await _database.ref('calls/$callId').once();
          if (callSnapshot.snapshot.exists) {
            final callData =
<<<<<<< HEAD
                callSnapshot.snapshot.value as Map<dynamic, dynamic>;
=======
            callSnapshot.snapshot.value as Map<dynamic, dynamic>;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
            final receiverId = callData['receiverId'] as String;

            await sendCallSignal(
              receiverId: receiverId,
              callId: callId,
              type: 'timeout',
              data: {'reason': 'no_answer'},
              callType: CallType.values.firstWhere(
<<<<<<< HEAD
                (e) => e.toString().split('.').last == callData['type'],
=======
                    (e) => e.toString().split('.').last == callData['type'],
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
                orElse: () => CallType.audio,
              ),
            );
          }
        } catch (e) {
          print('Error sending timeout signal: $e');
        }
      }
    } catch (e) {
      print('Error handling call timeout: $e');
    }
  }

  static Future<bool> answerCall(String callId) async {
    try {
      _cancelCallTimeout(callId);

      await _database.ref('calls/$callId').update({
        'status': CallStatus.connecting.toString().split('.').last,
        'answeredAt': ServerValue.timestamp,
      });

      print('Call answered: $callId');
      return true;
    } catch (e) {
      print('Error answering call: $e');
      return false;
    }
  }

  static Future<bool> declineCall(String callId) async {
    try {
      _cancelCallTimeout(callId);

      await _database.ref('calls/$callId').update({
        'status': CallStatus.declined.toString().split('.').last,
        'endedAt': ServerValue.timestamp,
      });

      // Remove from processed sets
      _processedCalls.remove(callId);

      print('Call declined: $callId');
      return true;
    } catch (e) {
      print('Error declining call: $e');
      return false;
    }
  }

  static Future<bool> endCall(String callId, {int? duration}) async {
    try {
      _cancelCallTimeout(callId);

      final updateData = <String, dynamic>{
        'status': CallStatus.ended.toString().split('.').last,
        'endedAt': ServerValue.timestamp,
      };

      if (duration != null) {
        updateData['duration'] = duration;
      }

      await _database.ref('calls/$callId').update(updateData);

      // Remove from processed sets
      _processedCalls.remove(callId);

      print('Call ended: $callId');
      return true;
    } catch (e) {
      print('Error ending call: $e');
      return false;
    }
  }

  static Future<bool> sendCallSignal({
    required String receiverId,
    required String callId,
    required String type,
    required Map<String, dynamic> data,
    required CallType callType,
  }) async {
    try {
      final currentUserId = await StorageService.getUserId();
      if (currentUserId == null) return false;

      final signalId = DateTime.now().millisecondsSinceEpoch.toString();
      final signalData = {
        'senderId': currentUserId,
        'receiverId': receiverId,
        'callId': callId,
        'type': type,
        'data': data ?? <String, dynamic>{}, // Ensure data is never null
        'callType': callType.toString().split('.').last,
        'timestamp': ServerValue.timestamp,
      };

      await _database.ref('call_signals/$signalId').set(signalData);
      print('Call signal sent: $type for call $callId');
      return true;
    } catch (e) {
      print('Error sending call signal: $e');
      return false;
    }
  }

  // ... (rest of the methods remain the same)

  static Future<List<Call>> getRecentCalls({int limit = 50}) async {
    try {
      final currentUserId = await StorageService.getUserId();
      if (currentUserId == null) return [];

      final allCalls = <Call>[];

      // Get calls where user is caller
      final callerCallsSnapshot = await _database
          .ref('calls')
          .orderByChild('callerId')
          .equalTo(currentUserId)
          .limitToLast(limit)
          .once();

      if (callerCallsSnapshot.snapshot.exists) {
        final data =
<<<<<<< HEAD
            callerCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
=======
        callerCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        data.forEach((callId, callData) {
          if (callData is Map<dynamic, dynamic>) {
            try {
              final call = Call.fromJson(Map<String, dynamic>.from(callData));
              allCalls.add(call);
            } catch (e) {
              print('Error parsing call data: $e');
            }
          }
        });
      }

      // Get calls where user is receiver
      final receiverCallsSnapshot = await _database
          .ref('calls')
          .orderByChild('receiverId')
          .equalTo(currentUserId)
          .limitToLast(limit)
          .once();

      if (receiverCallsSnapshot.snapshot.exists) {
        final data =
<<<<<<< HEAD
            receiverCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
=======
        receiverCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        data.forEach((callId, callData) {
          if (callData is Map<dynamic, dynamic>) {
            try {
              final call = Call.fromJson(Map<String, dynamic>.from(callData));
              allCalls.add(call);
            } catch (e) {
              print('Error parsing call data: $e');
            }
          }
        });
      }

      // Sort by timestamp and return limited results
      allCalls.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allCalls.take(limit).toList();
    } catch (e) {
      print('Error getting recent calls: $e');
      return [];
    }
  }

  static Future<void> markCallAsMissed(String callId) async {
    try {
      _cancelCallTimeout(callId);

      await _database.ref('calls/$callId').update({
        'status': CallStatus.missed.toString().split('.').last,
        'endedAt': ServerValue.timestamp,
      });

      _processedCalls.remove(callId);
    } catch (e) {
      print('Error marking call as missed: $e');
    }
  }

  static Future<void> clearCallHistory() async {
    try {
      final currentUserId = await StorageService.getUserId();
      if (currentUserId == null) return;

      // Get all calls for this user and delete them
      final callerCallsSnapshot = await _database
          .ref('calls')
          .orderByChild('callerId')
          .equalTo(currentUserId)
          .once();

      if (callerCallsSnapshot.snapshot.exists) {
        final data =
<<<<<<< HEAD
            callerCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
=======
        callerCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        for (final callId in data.keys) {
          await _database.ref('calls/$callId').remove();
        }
      }

      final receiverCallsSnapshot = await _database
          .ref('calls')
          .orderByChild('receiverId')
          .equalTo(currentUserId)
          .once();

      if (receiverCallsSnapshot.snapshot.exists) {
        final data =
<<<<<<< HEAD
            receiverCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
=======
        receiverCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        for (final callId in data.keys) {
          await _database.ref('calls/$callId').remove();
        }
      }

      // Clear processed sets
      _processedCalls.clear();
      _processedSignals.clear();

      print('Call history cleared');
    } catch (e) {
      print('Error clearing call history: $e');
    }
  }

  static Future<void> cleanupOldCalls() async {
    try {
      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;

      final allCallsSnapshot = await _database.ref('calls').once();

      if (allCallsSnapshot.snapshot.exists) {
        final data = allCallsSnapshot.snapshot.value as Map<dynamic, dynamic>;

        for (final entry in data.entries) {
          final callData = entry.value as Map<dynamic, dynamic>;
          final timestamp = callData['timestamp'] as int?;

          if (timestamp != null && timestamp < thirtyDaysAgo) {
            await _database.ref('calls/${entry.key}').remove();
            _processedCalls.remove(entry.key.toString());
          }
        }
      }

      print('Old calls cleanup completed');
    } catch (e) {
      print('Error cleaning up old calls: $e');
    }
  }

  static Future<String> getUserCallStatus(String secureId) async {
    try {
      final isOnline = await PresenceService.isUserOnlineBySecureId(secureId);
      if (!isOnline) {
        return 'Offline';
      }

      return 'Online';
    } catch (e) {
      print('Error getting user call status: $e');
      return 'Unknown';
    }
  }

  static void dispose() {
    // Cancel all pending timers
    for (final timer in _pendingCallTimers.values) {
      timer.cancel();
    }
    _pendingCallTimers.clear();

    // Clear processed sets
    _processedCalls.clear();
    _processedSignals.clear();

    _callsSubscription?.cancel();
    _signalsSubscription?.cancel();
    _incomingCallController.close();
    _callSignalController.close();

    PresenceService.dispose();
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/message.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import 'dart:async';
import '../models/call.dart';
import '../services/firebase_auth_service.dart';

class FirebaseMessageService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

// Send encrypted message - FIXED VERSION with better error handling
  static Future<bool> sendMessage({
    required String receiverSecureId,
    required String content,
    required MessageType type,
    int? expiresInSeconds,
  }) async {
    try {
      final sender = _auth.currentUser;
      if (sender == null) {
        print('ERROR: No authenticated user found');
        return false;
      }

      final receiverData = await FirebaseAuthService.getUserBySecureId(
        receiverSecureId,
      );
      if (receiverData == null) {
        print('ERROR: Receiver not found for secure ID: $receiverSecureId');
        return false;
      }

      final receiverPublicKey = receiverData['publicKey'] as String?;
      final receiverId = receiverData['userId'] as String?;

      if (receiverPublicKey == null || receiverId == null) {
        print(
          'ERROR: Missing receiver data - publicKey: $receiverPublicKey, userId: $receiverId',
        );
        return false;
      }

      final senderSecureId = await StorageService.getUserSecureId();
      if (senderSecureId == null) {
        print('ERROR: Sender secure ID is null');
        return false;
      }

      print('Starting message encryption...');
      // 1. Encrypt message for the RECEIVER
      final encryptionResult = CryptoService.encryptMessage(
        content,
        receiverPublicKey,
      );

      final messageId = CryptoService.generateMessageId();
      final now = DateTime.now();
      final expirationSeconds =
          expiresInSeconds ?? (7 * 24 * 60 * 60); // 7 days default

      // 2. Create the message payload for the RECEIVER (encrypted)
      final receiverMessage = Message(
        id: messageId,
        senderId: sender.uid,
        receiverId: receiverId,
        content: encryptionResult['encryptedMessage']!,
        type: type,
        timestamp: now,
        isEncrypted: true, // Mark as encrypted for receiver
        expiresInSeconds: expirationSeconds,
      );

      final receiverMessageData = receiverMessage.toJson();
      receiverMessageData['encryptedCombination'] =
      encryptionResult['encryptedCombination'];
      receiverMessageData['iv'] = encryptionResult['iv'];
      receiverMessageData['senderSecureId'] = senderSecureId;
      receiverMessageData['receiverSecureId'] = receiverSecureId;
      receiverMessageData['expiresAt'] = now
          .add(Duration(seconds: expirationSeconds))
          .millisecondsSinceEpoch;

      // 3. Create the message payload for the SENDER (unencrypted)
      final senderMessage = Message(
        id: messageId,
        senderId: sender.uid,
        receiverId: receiverId,
        content: content, // Store original content for the sender
        type: type,
        timestamp: now,
        isEncrypted: false, // Mark as NOT encrypted for sender
        expiresInSeconds: expirationSeconds,
      );
      final senderMessageData = senderMessage.toJson();
      senderMessageData['senderSecureId'] = senderSecureId;
      senderMessageData['receiverSecureId'] = receiverSecureId;
      senderMessageData['expiresAt'] = now
          .add(Duration(seconds: expirationSeconds))
          .millisecondsSinceEpoch;

      print('Attempting to write messages to database...');
      // 4. Atomically write both messages to the database
      try {
        await Future.wait([
          // Write encrypted message to receiver's path
          _database
              .child('messages/$receiverId/${sender.uid}/$messageId')
              .set(receiverMessageData),
          // Write unencrypted message to sender's path
          _database
              .child('messages/${sender.uid}/$receiverId/$messageId')
              .set(senderMessageData),
        ]);
        print('Messages written to database successfully');
      } catch (e) {
        print('ERROR writing messages to database: $e');
        return false;
      }

      // 5. Update chat room for both users (with error handling)
      final lastMessageForChat = senderMessage.copyWith();
      try {
        print('Updating chat rooms...');
        await Future.wait([
          _updateChatRoom(
            sender.uid,
            receiverId,
            lastMessageForChat,
            receiverSecureId,
          ),
          _updateChatRoom(
            receiverId,
            sender.uid,
            lastMessageForChat,
            senderSecureId,
          ),
        ]);
        print('Chat rooms updated successfully');
      } catch (e) {
        print('WARNING: Chat room update failed (message still sent): $e');
        // Don't return false here - message was sent successfully
        // Chat room update failure is not critical
      }

      print('Message sent successfully!');
      return true;
    } catch (e, stackTrace) {
      print('ERROR sending message: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
  // Fixed getMessages method in FirebaseMessageService
  static Stream<List<Message>> getMessages(String otherUserSecureId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _getUserBySecureId(otherUserSecureId).asStream().asyncExpand((
      otherUserData,
    ) {
      if (otherUserData == null) return Stream.value(<Message>[]);

      final otherUserId = otherUserData['userId'] as String;

      // Listen to messages in the current user's chat path
      return _database.child('messages/${currentUser.uid}/$otherUserId').onValue.asyncMap((
        event,
      ) async {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return <Message>[];

        final messages = <Message>[];
        final privateKey = await StorageService.getUserPrivateKey();
        final currentUserId = await StorageService.getUserId();

        for (final messageEntry in data.entries) {
          try {
            final messageData = Map<String, dynamic>.from(messageEntry.value);

            print('Processing message: ${messageEntry.key}');
            print('Message data keys: ${messageData.keys.toList()}');
            print('IsEncrypted: ${messageData['isEncrypted']}');
            print(
              'SenderId: ${messageData['senderId']}, CurrentUserId: $currentUserId',
            );

            // Check if this message needs decryption
            // A message needs decryption if:
            // 1. It's marked as encrypted AND
            // 2. The current user is NOT the sender (receiver needs to decrypt)
            final needsDecryption =
                messageData['isEncrypted'] == true &&
                messageData['senderId'] != currentUserId;

            if (needsDecryption) {
              print('Message needs decryption');

              if (privateKey != null &&
                  messageData['encryptedCombination'] != null) {
                print('Attempting decryption...');
                print(
                  'Encrypted content length: ${messageData['content']?.length}',
                );
                print(
                  'Encrypted combination length: ${messageData['encryptedCombination']?.length}',
                );

                // Use the proper decryption method
                final decryptedContent =
                    CryptoService.decryptMessageWithCombination(
                      messageData['content'],
                      messageData['encryptedCombination'],
                      privateKey,
                    );

                if (decryptedContent != null) {
                  print(
                    'Decryption successful: ${decryptedContent.substring(0, math.min(20, decryptedContent.length))}...',
                  );
                  messageData['content'] = decryptedContent;
                  // Keep isEncrypted as true for display purposes, but content is now readable
                } else {
                  print('Decryption failed');
                  messageData['content'] =
                      '[Encrypted Message - Decryption Failed]';
                }
              } else {
                print(
                  'Missing decryption requirements - privateKey: ${privateKey != null}, encryptedCombination: ${messageData['encryptedCombination'] != null}',
                );
                messageData['content'] = '[Encrypted Message - Missing Keys]';
              }
            } else {
              print(
                'Message does not need decryption (sender copy or not encrypted)',
              );
            }

            // Parse the message
            final message = Message.fromJson(messageData);
            messages.add(message);
            print('Message added successfully');
          } catch (e, stackTrace) {
            print('Error parsing message ${messageEntry.key}: $e');
            print('Stack trace: $stackTrace');
            print('Raw message data: ${messageEntry.value}');

            // Add a placeholder for failed messages with more info
            final errorMessage = Message(
              id: messageEntry.key,
              senderId: 'unknown',
              receiverId: currentUser.uid,
              content:
                  '[Message parsing failed: ${e.toString().length > 50 ? "${e.toString().substring(0, 50)}..." : e.toString()}]',
              type: MessageType.text,
              timestamp: DateTime.now(),
              isEncrypted: false,
            );
            messages.add(errorMessage);
          }
        }

        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        print('Returning ${messages.length} messages');
        return messages;
      });
    });
  }

  // Helper method to get user by secure ID
  static Future<Map<String, dynamic>?> _getUserBySecureId(
    String secureId,
  ) async {
    return await FirebaseAuthService.getUserBySecureId(secureId);
  }

  // FIXED: Updated chat room update method to handle secure ID display properly
  static Future<void> _updateChatRoom(
    String userId1,
    String userId2,
    Message lastMessage,
    String otherUserSecureId,
  ) async {
    try {
      final chatRoomId = CryptoService.generateRoomId(userId1, userId2);

      // Get the other user's data for display
      final otherUserData = await FirebaseAuthService.getUserBySecureId(
        otherUserSecureId,
      );
      final displayName = otherUserData?['secureId'] ?? otherUserSecureId;

      await _database.child('chatRooms/$userId1/$userId2').update({
        'roomId': chatRoomId,
        'otherUserSecureId': otherUserSecureId,
        'displayName': displayName, // Add display name
        'lastMessage': lastMessage.type == MessageType.text
            ? lastMessage.content.length > 50
                  ? '${lastMessage.content.substring(0, 50)}...'
                  : lastMessage.content
            : '[${lastMessage.type.name}]',
        'lastMessageTime': lastMessage.timestamp.millisecondsSinceEpoch,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating chat room: $e');
    }
  }

  // Mark message as read
  static Future<void> markMessageAsRead(
    String messageId,
    String otherUserId,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _database
          .child('messages/${currentUser.uid}/$otherUserId/$messageId')
          .update({'isRead': true});
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Clean up expired messages
  static Future<void> cleanupExpiredMessages() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await _database
          .child('messages/${currentUser.uid}')
          .once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final now = DateTime.now().millisecondsSinceEpoch;

        for (final chatEntry in data.entries) {
          final chatData = chatEntry.value as Map<dynamic, dynamic>;

          for (final messageEntry in chatData.entries) {
            final messageData = messageEntry.value as Map<dynamic, dynamic>;
            final expiresAt = messageData['expiresAt'] as int?;

            if (expiresAt != null && now > expiresAt) {
              try {
                await _database
                    .child(
                      'messages/${currentUser.uid}/${chatEntry.key}/${messageEntry.key}',
                    )
                    .remove();
              } catch (e) {
                print('Error deleting expired message ${messageEntry.key}: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up expired messages: $e');
    }
  }

  // FIXED: Get chat rooms with proper secure ID display
  static Stream<List<Map<String, dynamic>>> getChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _database.child('chatRooms/${currentUser.uid}').onValue.asyncMap((
      event,
    ) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Map<String, dynamic>>[];

      final chatRooms = <Map<String, dynamic>>[];

      for (final entry in data.entries) {
        try {
          final chatData = entry.value as Map<dynamic, dynamic>;
          final otherUserId = entry.key as String;
          final otherUserSecureId = chatData['otherUserSecureId'] as String?;

          if (otherUserSecureId != null) {
            // Get other user's current info
            final otherUserData = await FirebaseAuthService.getUserBySecureId(
              otherUserSecureId,
            );

            chatRooms.add({
              'otherUserId': otherUserId,
              'otherUserSecureId': otherUserSecureId,
              'displayName': otherUserData?['secureId'] ?? otherUserSecureId,
              'lastMessage': chatData['lastMessage'],
              'lastMessageTime': chatData['lastMessageTime'],
              'roomId': chatData['roomId'],
              'isOnline': otherUserData?['isActive'] ?? false,
              'lastSeen': otherUserData?['lastSeen'],
            });
          }
        } catch (e) {
          print('Error processing chat room: $e');
        }
      }

      chatRooms.sort((a, b) {
        final aTime = a['lastMessageTime'] as int? ?? 0;
        final bTime = b['lastMessageTime'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return chatRooms;
    });
  }

  // Delete message
  static Future<bool> deleteMessage(
    String messageId,
    String otherUserId,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      await _database
          .child('messages/${currentUser.uid}/$otherUserId/$messageId')
          .remove();
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // Clear all messages in a chat
  static Future<bool> clearChat(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      await _database
          .child('messages/${currentUser.uid}/$otherUserId')
          .remove();

      await _database
          .child('chatRooms/${currentUser.uid}/$otherUserId')
          .remove();

      return true;
    } catch (e) {
      print('Error clearing chat: $e');
      return false;
    }
  }

  // ===== REALTIME DATABASE CALL SIGNAL METHODS =====

  static Future<bool> sendCallSignal({
    required String receiverId,
    required String callId,
    required String type,
    required Map<String, dynamic> data,
    required CallType callType,
  }) async {
    try {
      print('Sending call signal: $type for call $callId to $receiverId');

      final currentUserId = await StorageService.getUserId();
      if (currentUserId == null) {
        print('No current user ID to send call signal');
        return false;
      }

      String actualReceiverId = receiverId;

      // If receiverId looks like a secure ID, convert it to user ID
      if (receiverId.length == 12 &&
          RegExp(r'^[A-Z0-9]+$').hasMatch(receiverId)) {
        print('Converting secure ID to user ID: $receiverId');
        final receiverData = await FirebaseAuthService.getUserBySecureId(
          receiverId,
        );
        if (receiverData != null) {
          actualReceiverId = receiverData['userId'] as String;
          print('Found user ID: $actualReceiverId');
        } else {
          print('Could not find user for secure ID: $receiverId');
          return false;
        }
      }

      final signalId = DateTime.now().millisecondsSinceEpoch.toString();
      final signalData = {
        'senderId': currentUserId,
        'receiverId': actualReceiverId,
        'callId': callId,
        'type': type,
        'data': data,
        'callType': callType.toString().split('.').last,
        'timestamp': ServerValue.timestamp,
      };

      await _database.child('call_signals/$signalId').set(signalData);
      print('Call signal sent successfully: $type');
      return true;
    } catch (e) {
      print('Error sending call signal: $e');
      return false;
    }
  }

  static Stream<Map<String, dynamic>> listenForCallSignals() {
    print('Setting up call signals listener');

    final StreamController<Map<String, dynamic>> controller =
        StreamController<Map<String, dynamic>>.broadcast();

    StreamSubscription<DatabaseEvent>? subscription;

    // Get current user ID first
    StorageService.getUserId()
        .then((currentUserId) {
          if (currentUserId == null) {
            print('No current user ID for call signals');
            controller.close();
            return;
          }

          print('Listening for call signals for user: $currentUserId');

          subscription = _database
              .child('call_signals')
              .orderByChild('receiverId')
              .equalTo(currentUserId)
              .onValue
              .listen(
                (event) {
                  if (event.snapshot.exists) {
                    final data = event.snapshot.value as Map<dynamic, dynamic>;

                    data.forEach((signalId, signalData) async {
                      if (signalData is Map<dynamic, dynamic>) {
                        try {
                          final signal = Map<String, dynamic>.from(signalData);
                          print(
                            'Received call signal: ${signal['type']} for call ${signal['callId']}',
                          );

                          controller.add(signal);

                          // Delete the signal after processing
                          await _database
                              .child('call_signals/$signalId')
                              .remove();
                        } catch (e) {
                          print('Error processing call signal: $e');
                        }
                      }
                    });
                  }
                },
                onError: (error) {
                  print('Error in call signals stream: $error');
                  controller.addError(error);
                },
              );
        })
        .catchError((error) {
          print('Error getting user ID for call signals: $error');
          controller.addError(error);
        });

    // Handle stream disposal
    controller.onCancel = () {
      subscription?.cancel();
      print('Call signals listener cancelled');
    };

    return controller.stream;
  }

  static Future<void> cleanupExpiredCallSignals() async {
    try {
      final oneHourAgo = DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch;

      final snapshot = await _database.child('call_signals').once();

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

        for (final entry in data.entries) {
          final signalData = entry.value as Map<dynamic, dynamic>;
          final timestamp = signalData['timestamp'] as int?;

          if (timestamp != null && timestamp < oneHourAgo) {
            await _database.child('call_signals/${entry.key}').remove();
          }
        }
      }

      print('Cleaned up expired call signals');
    } catch (e) {
      print('Error cleaning up expired call signals: $e');
    }
  }

  static Future<void> cleanupFailedCalls() async {
    try {
      final currentUserId = await StorageService.getUserId();
      if (currentUserId == null) return;

      final tenMinutesAgo = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;

      final snapshot = await _database.child('call_signals').once();

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

        for (final entry in data.entries) {
          final signalData = entry.value as Map<dynamic, dynamic>;
          final senderId = signalData['senderId'] as String?;
          final type = signalData['type'] as String?;
          final timestamp = signalData['timestamp'] as int?;

          if (senderId == currentUserId &&
              type == 'offer' &&
              timestamp != null &&
              timestamp < tenMinutesAgo) {
            await _database.child('call_signals/${entry.key}').remove();
          }
        }
      }

      print('Cleaned up failed call attempts');
    } catch (e) {
      print('Error cleaning up failed calls: $e');
    }
  }
}

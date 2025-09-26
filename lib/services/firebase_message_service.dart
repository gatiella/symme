<<<<<<< HEAD
=======

>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/message.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart'; // Add this
import 'dart:async';
import '../models/call.dart';
import '../services/firebase_auth_service.dart';

class FirebaseMessageService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send encrypted message - FIXED VERSION with proper encryption
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

      // Get receiver data
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
      // Encrypt message for the RECEIVER
      final encryptionResult = CryptoService.encryptMessage(
        content,
        receiverPublicKey,
      );

      final messageId = CryptoService.generateMessageId();
      final now = DateTime.now();
<<<<<<< HEAD
      final expirationSeconds =
          expiresInSeconds ?? (7 * 24 * 60 * 60); // 7 days default
=======
      final expirationSeconds = expiresInSeconds ?? (7 * 24 * 60 * 60); // 7 days default
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

      // Create encrypted message for RECEIVER (stored encrypted in database)
      final receiverMessageData = {
        'id': messageId,
        'senderId': sender.uid,
        'receiverId': receiverId,
<<<<<<< HEAD
        'content':
            encryptionResult['encryptedMessage']!, // Store encrypted content
=======
        'content': encryptionResult['encryptedMessage']!, // Store encrypted content
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        'type': type.index,
        'timestamp': now.millisecondsSinceEpoch,
        'isRead': false,
        'isDelivered': true,
        'isEncrypted': true,
        'encryptedCombination': encryptionResult['encryptedCombination'],
        'iv': encryptionResult['iv'],
        'senderSecureId': senderSecureId,
        'receiverSecureId': receiverSecureId,
        'expiresInSeconds': expirationSeconds,
<<<<<<< HEAD
        'expiresAt': now
            .add(Duration(seconds: expirationSeconds))
            .millisecondsSinceEpoch,
=======
        'expiresAt': now.add(Duration(seconds: expirationSeconds)).millisecondsSinceEpoch,
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      };

      // Create unencrypted message for SENDER (for their own viewing)
      final senderMessageData = {
        'id': messageId,
        'senderId': sender.uid,
        'receiverId': receiverId,
        'content': content, // Store original content for sender
        'type': type.index,
        'timestamp': now.millisecondsSinceEpoch,
        'isRead': true, // Mark as read for sender
        'isDelivered': true,
        'isEncrypted': false, // Not encrypted for sender's view
        'senderSecureId': senderSecureId,
        'receiverSecureId': receiverSecureId,
        'expiresInSeconds': expirationSeconds,
<<<<<<< HEAD
        'expiresAt': now
            .add(Duration(seconds: expirationSeconds))
            .millisecondsSinceEpoch,
      };

      print('Writing messages to database...');
      try {
        // Write both messages atomically
        await Future.wait([
          // Write encrypted message to receiver's inbox
          _database
              .child('messages/$receiverId/${sender.uid}/$messageId')
              .set(receiverMessageData),
          // Write unencrypted message to sender's outbox
          _database
              .child('messages/${sender.uid}/$receiverId/$messageId')
              .set(senderMessageData),
        ]);

        print('Messages written successfully');

        // Verify the write
        final verifySnapshot = await _database
            .child('messages/${sender.uid}/$receiverId/$messageId')
            .once();

        if (!verifySnapshot.snapshot.exists) {
          throw Exception('Message write verification failed');
        }
      } catch (e) {
        print('Error writing messages to database: $e');
        throw Exception('Failed to save message: $e');
      }
=======
        'expiresAt': now.add(Duration(seconds: expirationSeconds)).millisecondsSinceEpoch,
      };

        print('Writing messages to database...');
        try {
          // Write both messages atomically
          await Future.wait([
            // Write encrypted message to receiver's inbox
            _database
                .child('messages/$receiverId/${sender.uid}/$messageId')
                .set(receiverMessageData),
            // Write unencrypted message to sender's outbox
            _database
                .child('messages/${sender.uid}/$receiverId/$messageId')
                .set(senderMessageData),
          ]);
          
          print('Messages written successfully');
          
          // Verify the write
          final verifySnapshot = await _database
              .child('messages/${sender.uid}/$receiverId/$messageId')
              .once();
          
          if (!verifySnapshot.snapshot.exists) {
            throw Exception('Message write verification failed');
          }
          
        } catch (e) {
          print('Error writing messages to database: $e');
          throw Exception('Failed to save message: $e');
        }
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

      // Update chat rooms
      final lastMessageForChat = Message(
        id: messageId,
        senderId: sender.uid,
        receiverId: receiverId,
        content: content,
        type: type,
        timestamp: now,
        isEncrypted: false,
      );

      try {
        await Future.wait([
<<<<<<< HEAD
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
=======
          _updateChatRoom(sender.uid, receiverId, lastMessageForChat, receiverSecureId),
          _updateChatRoom(receiverId, sender.uid, lastMessageForChat, senderSecureId),
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        ]);
      } catch (e) {
        print('WARNING: Chat room update failed: $e');
      }

      // Send push notification to receiver
      try {
<<<<<<< HEAD
        await _sendNotificationToUser(
          receiverId,
          senderSecureId,
          content,
          type,
        );
=======
        await _sendNotificationToUser(receiverId, senderSecureId, content, type);
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      } catch (e) {
        print('WARNING: Notification sending failed: $e');
      }

      print('Message sent successfully!');
      return true;
    } catch (e, stackTrace) {
      print('ERROR sending message: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // FIXED: Improved message retrieval with proper decryption
  static Stream<List<Message>> getMessages(String otherUserSecureId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

<<<<<<< HEAD
    return _getUserBySecureId(otherUserSecureId).asStream().asyncExpand((
      otherUserData,
    ) {
=======
    return _getUserBySecureId(otherUserSecureId).asStream().asyncExpand((otherUserData) {
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      if (otherUserData == null) return Stream.value(<Message>[]);

      final otherUserId = otherUserData['userId'] as String;

<<<<<<< HEAD
      return _database.child('messages/${currentUser.uid}/$otherUserId').onValue.asyncMap((
        event,
      ) async {
=======
      return _database.child('messages/${currentUser.uid}/$otherUserId').onValue.asyncMap((event) async {
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return <Message>[];

        final messages = <Message>[];
        final privateKey = await StorageService.getUserPrivateKey();
        final currentUserId = await StorageService.getUserId();

        print('Processing ${data.length} messages...');

<<<<<<< HEAD
      for (final messageEntry in data.entries) {
            try {
              final messageData = Map<String, dynamic>.from(messageEntry.value);

=======
          for (final messageEntry in data.entries) {
            try {
              final messageData = Map<String, dynamic>.from(messageEntry.value);
              
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
              // Add null checks and defaults
              messageData['id'] = messageData['id'] ?? messageEntry.key.toString();
              messageData['senderId'] = messageData['senderId'] ?? 'unknown';
              messageData['receiverId'] = messageData['receiverId'] ?? currentUserId;
              messageData['content'] = messageData['content'] ?? '[Empty message]';
              messageData['type'] = messageData['type'] ?? 0;
              messageData['timestamp'] = messageData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
              messageData['isRead'] = messageData['isRead'] ?? false;
              messageData['isDelivered'] = messageData['isDelivered'] ?? true;
              messageData['isEncrypted'] = messageData['isEncrypted'] ?? false;
<<<<<<< HEAD

=======
              
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
              print('Processing message ID: ${messageEntry.key}');
              print('Message isEncrypted: ${messageData['isEncrypted']}');
              print('Message senderId: ${messageData['senderId']}, currentUserId: $currentUserId');

<<<<<<< HEAD
              // FIXED: Decrypt message if it's encrypted AND we're the receiver
              if (messageData['isEncrypted'] == true && messageData['senderId'] != currentUserId) {
                print('Message needs decryption...');

                if (privateKey != null && messageData['encryptedCombination'] != null && messageData['iv'] != null) {
                  try {
                    final decryptedContent = CryptoService.decryptMessageWithCombination(
                      messageData['content'],
                      messageData['encryptedCombination'],
                      privateKey,
                    );

                    if (decryptedContent != null && decryptedContent.isNotEmpty) {
                      messageData['content'] = decryptedContent;
                      messageData['isEncrypted'] = false; // Mark as decrypted for display
                      print('✅ Decryption successful');
                    } else {
                      messageData['content'] = '[Failed to decrypt message]';
                      print('❌ Decryption returned null/empty');
                    }
                  } catch (e) {
                    messageData['content'] = '[Decryption error]';
                    print('❌ Decryption exception: $e');
                  }
                } else {
                  messageData['content'] = '[Missing decryption data]';
                  print('❌ Missing privateKey, encryptedCombination, or IV');
                  print('privateKey exists: ${privateKey != null}');
                  print('encryptedCombination exists: ${messageData['encryptedCombination'] != null}');
                  print('iv exists: ${messageData['iv'] != null}');
                }
              }

              // Create message object
              final message = Message.fromJson(messageData);
              messages.add(message);
            } catch (e, stackTrace) {
              print('Error parsing message ${messageEntry.key}: $e');
              print('Stack trace: $stackTrace');
              // Add error placeholder
              messages.add(Message(
                id: messageEntry.key.toString(),
                senderId: 'error',
                receiverId: currentUser.uid,
                content: '[Message parsing failed]',
                type: MessageType.text,
                timestamp: DateTime.now(),
                isEncrypted: false,
              ));
            }
          }
=======
            // Decrypt message if needed (when current user is the receiver and message is encrypted)
            if (messageData['isEncrypted'] == true && messageData['senderId'] != currentUserId) {
              print('Message needs decryption...');
              
              if (privateKey != null && messageData['encryptedCombination'] != null) {
                try {
                  final decryptedContent = CryptoService.decryptMessageWithCombination(
                    messageData['content'],
                    messageData['encryptedCombination'],
                    privateKey,
                  );

                  if (decryptedContent != null && decryptedContent.isNotEmpty) {
                    messageData['content'] = decryptedContent;
                    print('✅ Decryption successful');
                  } else {
                    messageData['content'] = '[Failed to decrypt message]';
                    print('❌ Decryption returned null/empty');
                  }
                } catch (e) {
                  messageData['content'] = '[Decryption error: $e]';
                  print('❌ Decryption exception: $e');
                }
              } else {
                messageData['content'] = '[Missing decryption keys]';
                print('❌ Missing privateKey or encryptedCombination');
              }
            } else {
              print('ℹ️ Message doesn\'t need decryption (sender copy or unencrypted)');
            }

            // Create message object
            final message = Message.fromJson(messageData);
            messages.add(message);

          } catch (e, stackTrace) {
            print('Error parsing message ${messageEntry.key}: $e');
            print('Stack trace: $stackTrace');
            
            // Add error placeholder
            messages.add(Message(
              id: messageEntry.key.toString(),
              senderId: 'error',
              receiverId: currentUser.uid,
              content: '[Message parsing failed]',
              type: MessageType.text,
              timestamp: DateTime.now(),
              isEncrypted: false,
            ));
          }
        }

>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        // Sort messages by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        print('Returning ${messages.length} processed messages');
        return messages;
      });
    });
  }

  // Helper method to get user by secure ID
<<<<<<< HEAD
  static Future<Map<String, dynamic>?> _getUserBySecureId(
    String secureId,
  ) async {
=======
  static Future<Map<String, dynamic>?> _getUserBySecureId(String secureId) async {
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
    return await FirebaseAuthService.getUserBySecureId(secureId);
  }

  // FIXED: Updated chat room update method
  static Future<void> _updateChatRoom(
    String userId1,
    String userId2,
    Message lastMessage,
    String otherUserSecureId,
  ) async {
    try {
      final chatRoomId = CryptoService.generateRoomId(userId1, userId2);

      // Get display name for other user
<<<<<<< HEAD
      final otherUserData = await FirebaseAuthService.getUserBySecureId(
        otherUserSecureId,
      );
=======
      final otherUserData = await FirebaseAuthService.getUserBySecureId(otherUserSecureId);
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      final displayName = otherUserData?['secureId'] ?? otherUserSecureId;

      // Create preview of last message
      String lastMessagePreview;
      if (lastMessage.type == MessageType.text) {
        lastMessagePreview = lastMessage.content.length > 50
            ? '${lastMessage.content.substring(0, 50)}...'
            : lastMessage.content;
      } else {
        lastMessagePreview = '[${lastMessage.type.name.toUpperCase()}]';
      }

      await _database.child('chatRooms/$userId1/$userId2').update({
        'roomId': chatRoomId,
        'otherUserSecureId': otherUserSecureId,
        'displayName': displayName,
        'lastMessage': lastMessagePreview,
        'lastMessageTime': lastMessage.timestamp.millisecondsSinceEpoch,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating chat room: $e');
    }
  }

  // NEW: Send push notification to user
  static Future<void> _sendNotificationToUser(
<<<<<<< HEAD
    String receiverId,
    String senderSecureId,
=======
    String receiverId, 
    String senderSecureId, 
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
    String messageContent,
    MessageType messageType,
  ) async {
    try {
      // Get receiver's FCM token
<<<<<<< HEAD
      final receiverSnapshot = await _database
          .child('users/$receiverId/fcmToken')
          .once();
      final fcmToken = receiverSnapshot.snapshot.value as String?;

=======
      final receiverSnapshot = await _database.child('users/$receiverId/fcmToken').once();
      final fcmToken = receiverSnapshot.snapshot.value as String?;
      
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      if (fcmToken == null) {
        print('No FCM token found for receiver');
        return;
      }

      // Create notification payload
      String notificationTitle = 'New message from $senderSecureId';
      String notificationBody;
<<<<<<< HEAD

      if (messageType == MessageType.text) {
        // For notifications, show a preview but don't decrypt (for privacy)
        notificationBody = messageContent.length > 100
            ? '${messageContent.substring(0, 100)}...'
=======
      
      if (messageType == MessageType.text) {
        // For notifications, show a preview but don't decrypt (for privacy)
        notificationBody = messageContent.length > 100 
            ? '${messageContent.substring(0, 100)}...' 
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
            : messageContent;
      } else {
        notificationBody = 'Sent a ${messageType.name}';
      }

<<<<<<< HEAD
      // UPDATED: Use the new sendPushNotification method
          final success = await NotificationService.sendPushNotification(
          token: fcmToken,
          title: notificationTitle,
          body: notificationBody,
          data: {
            'type': 'message',
            'senderId': senderSecureId,
            'receiverId': receiverId,
            'messageType': messageType.name,
            'action': 'open_chat', // Add this for proper navigation
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
      if (success) {
        print('Push notification sent successfully');
      } else {
        print('Failed to send push notification');
      }
=======
      // Send notification via your notification service
      await NotificationService.sendPushNotification(
        token: fcmToken,
        title: notificationTitle,
        body: notificationBody,
        data: {
          'type': 'message',
          'senderId': senderSecureId,
          'receiverId': receiverId,
          'messageType': messageType.name,
        },
      );

>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Mark message as read
<<<<<<< HEAD
  static Future<void> markMessageAsRead(
    String messageId,
    String otherUserId,
  ) async {
=======
  static Future<void> markMessageAsRead(String messageId, String otherUserId) async {
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
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
<<<<<<< HEAD
      final snapshot = await _database
          .child('messages/${currentUser.uid}')
          .once();
=======
      final snapshot = await _database.child('messages/${currentUser.uid}').once();
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
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
<<<<<<< HEAD
                    .child(
                      'messages/${currentUser.uid}/${chatEntry.key}/${messageEntry.key}',
                    )
=======
                    .child('messages/${currentUser.uid}/${chatEntry.key}/${messageEntry.key}')
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
                    .remove();
                print('Deleted expired message: ${messageEntry.key}');
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

  // Get chat rooms with proper secure ID display
  static Stream<List<Map<String, dynamic>>> getChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

<<<<<<< HEAD
    return _database.child('chatRooms/${currentUser.uid}').onValue.asyncMap((
      event,
    ) async {
=======
    return _database.child('chatRooms/${currentUser.uid}').onValue.asyncMap((event) async {
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Map<String, dynamic>>[];

      final chatRooms = <Map<String, dynamic>>[];

      for (final entry in data.entries) {
        try {
          final chatData = entry.value as Map<dynamic, dynamic>;
          final otherUserId = entry.key as String;
          final otherUserSecureId = chatData['otherUserSecureId'] as String?;

          if (otherUserSecureId != null) {
<<<<<<< HEAD
            final otherUserData = await FirebaseAuthService.getUserBySecureId(
              otherUserSecureId,
            );
=======
            final otherUserData = await FirebaseAuthService.getUserBySecureId(otherUserSecureId);
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

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

      // Sort by last message time
      chatRooms.sort((a, b) {
        final aTime = a['lastMessageTime'] as int? ?? 0;
        final bTime = b['lastMessageTime'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return chatRooms;
    });
  }

  // Delete message
<<<<<<< HEAD
  static Future<bool> deleteMessage(
    String messageId,
    String otherUserId,
  ) async {
=======
  static Future<bool> deleteMessage(String messageId, String otherUserId) async {
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
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
<<<<<<< HEAD
      await _database
          .child('messages/${currentUser.uid}/$otherUserId')
          .remove();
      await _database
          .child('chatRooms/${currentUser.uid}/$otherUserId')
          .remove();
=======
      await _database.child('messages/${currentUser.uid}/$otherUserId').remove();
      await _database.child('chatRooms/${currentUser.uid}/$otherUserId').remove();
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      return true;
    } catch (e) {
      print('Error clearing chat: $e');
      return false;
    }
  }

  // ===== CALL SIGNAL METHODS (UNCHANGED) =====
<<<<<<< HEAD

=======
  
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
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

<<<<<<< HEAD
      if (receiverId.length == 12 &&
          RegExp(r'^[A-Z0-9]+$').hasMatch(receiverId)) {
        print('Converting secure ID to user ID: $receiverId');
        final receiverData = await FirebaseAuthService.getUserBySecureId(
          receiverId,
        );
=======
      if (receiverId.length == 12 && RegExp(r'^[A-Z0-9]+$').hasMatch(receiverId)) {
        print('Converting secure ID to user ID: $receiverId');
        final receiverData = await FirebaseAuthService.getUserBySecureId(receiverId);
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
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

<<<<<<< HEAD
    final StreamController<Map<String, dynamic>> controller =
=======
    final StreamController<Map<String, dynamic>> controller = 
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
        StreamController<Map<String, dynamic>>.broadcast();

    StreamSubscription<DatabaseEvent>? subscription;

<<<<<<< HEAD
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
=======
    StorageService.getUserId().then((currentUserId) {
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
                      print('Received call signal: ${signal['type']} for call ${signal['callId']}');

                      controller.add(signal);

                      await _database.child('call_signals/$signalId').remove();
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
    }).catchError((error) {
      print('Error getting user ID for call signals: $error');
      controller.addError(error);
    });
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

    controller.onCancel = () {
      subscription?.cancel();
      print('Call signals listener cancelled');
    };

    return controller.stream;
  }

  static Future<void> cleanupExpiredCallSignals() async {
    try {
<<<<<<< HEAD
      final oneHourAgo = DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch;
=======
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
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

<<<<<<< HEAD
      final tenMinutesAgo = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
=======
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch;
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
      final snapshot = await _database.child('call_signals').once();

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

        for (final entry in data.entries) {
          final signalData = entry.value as Map<dynamic, dynamic>;
          final senderId = signalData['senderId'] as String?;
          final type = signalData['type'] as String?;
          final timestamp = signalData['timestamp'] as int?;

<<<<<<< HEAD
          if (senderId == currentUserId &&
              type == 'offer' &&
              timestamp != null &&
              timestamp < tenMinutesAgo) {
=======
          if (senderId == currentUserId && type == 'offer' && timestamp != null && timestamp < tenMinutesAgo) {
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
            await _database.child('call_signals/${entry.key}').remove();
          }
        }
      }

      print('Cleaned up failed call attempts');
    } catch (e) {
      print('Error cleaning up failed calls: $e');
    }
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

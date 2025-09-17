import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import 'dart:async';

class FirebaseMessageService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send encrypted message
  static Future<bool> sendMessage({
    required String receiverSecureId,
    required String content,
    required MessageType type,
    int? expiresInSeconds,
  }) async {
    try {
      final sender = _auth.currentUser;
      if (sender == null) return false;

      // Get receiver's public key
      final receiverData = await _getUserBySecureId(receiverSecureId);
      if (receiverData == null) return false;

      final receiverPublicKey = receiverData['publicKey'] as String?;
      final receiverId = receiverData['userId'] as String?;

      // Check for null values
      if (receiverPublicKey == null || receiverId == null) {
        print(
          'Missing receiver data: publicKey=$receiverPublicKey, userId=$receiverId',
        );
        return false;
      }

      // Get sender's secure ID - add null check
      final senderSecureId = await StorageService.getUserSecureId();
      if (senderSecureId == null) {
        print('Sender secure ID is null');
        return false;
      }

      // Encrypt message
      final encryptionResult = CryptoService.encryptMessage(
        content,
        receiverData['publicKey']
            as String, // Use the correct key from your service
      );
      // Create message object
      final messageId = CryptoService.generateMessageId();
      final now = DateTime.now();
      final expirationSeconds =
          expiresInSeconds ?? (7 * 24 * 60 * 60); // 7 days default

      final message = Message(
        id: messageId,
        senderId: sender.uid,
        receiverId: receiverId,
        content: encryptionResult['encryptedMessage']!,
        type: type,
        timestamp: now,
        isEncrypted: true,
        expiresInSeconds: expirationSeconds,
      );

      // Store encrypted message in Firebase
      final messageData = message.toJson();
      messageData['encryptedCombination'] =
          encryptionResult['encryptedCombination'];
      messageData['combinationId'] = encryptionResult['combinationId'];
      messageData['iv'] = encryptionResult['iv']; // Add IV for AES decryption

      await StorageService.getUserSecureId();
      messageData['senderSecureId'] = senderSecureId;

      messageData['receiverSecureId'] = receiverSecureId;
      messageData['expiresAt'] = now
          .add(Duration(seconds: expirationSeconds))
          .millisecondsSinceEpoch;

      // Store only in sender's path (receiver will get it through real-time sync)
      await _database
          .child('messages/${sender.uid}/$receiverId/$messageId')
          .set(messageData);
      // Update chat room info
      // await _updateChatRoom(sender.uid, receiverId, message);
      //await _updateChatRoom(receiverId, sender.uid, message);

      // Store sender's copy locally with message key for decryption
      final localMessage = message.copyWith(
        content: content, // Store unencrypted for sender
      );
      await _storeMessageLocally(sender.uid, receiverId, localMessage);

      return true;
    } catch (e, stackTrace) {
      print('Error sending message: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Get messages for a chat
  static Stream<List<Message>> getMessages(String otherUserSecureId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    // Listen to messages where current user is sender OR receiver
    final sentMessagesStream = _database
        .child('messages/${currentUser.uid}')
        .orderByChild('receiverSecureId')
        .equalTo(otherUserSecureId)
        .onValue;

    final receivedMessagesStream = _database
        .child('messages')
        .orderByChild('senderSecureId')
        .equalTo(otherUserSecureId)
        .onValue;

    return sentMessagesStream.asyncMap((event) async {
      // For now, just return sent messages to test
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Message>[];

      final messages = <Message>[];
      for (final userEntry in data.entries) {
        final userData = userEntry.value as Map<dynamic, dynamic>;
        for (final messageEntry in userData.entries) {
          final messageData = messageEntry.value as Map<dynamic, dynamic>;
          try {
            final message = Message.fromJson(
              Map<String, dynamic>.from(messageData),
            );
            messages.add(message);
          } catch (e) {
            print('Error parsing message: $e');
          }
        }
      }

      return messages..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
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

      // Also update in sender's copy (only if we have permission)
      try {
        await _database
            .child('messages/$otherUserId/${currentUser.uid}/$messageId')
            .update({'isDelivered': true});
      } catch (e) {
        print('Could not update delivery status (permission issue): $e');
        // This is expected if we don't have write permission to other user's data
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Clean up expired messages (only clean current user's messages to avoid permission issues)
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
                // Delete expired message (only from current user's path)
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

  static Future<Map<String, dynamic>?> _getUserBySecureId(
    String secureId,
  ) async {
    try {
      final idSnapshot = await _database.child('secureIds/$secureId').once();
      if (!idSnapshot.snapshot.exists) {
        print('Secure ID $secureId not found');
        return null;
      }

      final idData = idSnapshot.snapshot.value as Map<dynamic, dynamic>?;
      if (idData == null) {
        print('Secure ID data is null');
        return null;
      }

      final isActive = idData['isActive'] as bool?;
      if (isActive != true) {
        print('Secure ID is not active');
        return null;
      }

      final userId = idData['userId'] as String?;
      if (userId == null) {
        print('User ID is null for secure ID $secureId');
        return null;
      }

      final userSnapshot = await _database.child('users/$userId').once();
      if (userSnapshot.snapshot.exists) {
        final userData = userSnapshot.snapshot.value as Map<dynamic, dynamic>?;
        if (userData != null) {
          final result = Map<String, dynamic>.from(userData);
          result['userId'] = userId; // Ensure userId is included
          return result;
        }
      }

      print('User data not found for user ID $userId');
      return null;
    } catch (e) {
      print('Error getting user by secure ID: $e');
      return null;
    }
  }

  static Future<void> _updateChatRoom(
    String userId1,
    String userId2,
    Message lastMessage,
  ) async {
    try {
      final chatRoomId = CryptoService.generateRoomId(userId1, userId2);

      await _database.child('chatRooms/$userId1/$userId2').update({
        'roomId': chatRoomId,
        'lastMessage': lastMessage.type == MessageType.text
            ? lastMessage.content
            : '[${lastMessage.type.name}]',
        'lastMessageTime': lastMessage.timestamp.millisecondsSinceEpoch,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating chat room: $e');
    }
  }

  static Future<void> _storeMessageLocally(
    String senderId,
    String receiverId,
    Message message,
  ) async {
    try {
      final roomId = CryptoService.generateRoomId(senderId, receiverId);
      final messages = await StorageService.getMessages(roomId);
      messages.add(message);
      await StorageService.saveMessages(roomId, messages);
    } catch (e) {
      print('Error storing message locally: $e');
    }
  }

  // Get chat rooms
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

          // Get other user's info
          final otherUserSnapshot = await _database
              .child('users/$otherUserId')
              .once();
          if (otherUserSnapshot.snapshot.exists) {
            final otherUserData =
                otherUserSnapshot.snapshot.value as Map<dynamic, dynamic>;

            chatRooms.add({
              'otherUserId': otherUserId,
              'otherUserSecureId': otherUserData['secureId'],
              'lastMessage': chatData['lastMessage'],
              'lastMessageTime': chatData['lastMessageTime'],
              'roomId': chatData['roomId'],
              'isOnline': otherUserData['isActive'] ?? false,
              'lastSeen': otherUserData['lastSeen'],
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
      // Only delete from current user's path to avoid permission issues
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
      // Only clear from current user's path to avoid permission issues
      await _database
          .child('messages/${currentUser.uid}/$otherUserId')
          .remove();

      // Also clear the chat room entry
      await _database
          .child('chatRooms/${currentUser.uid}/$otherUserId')
          .remove();

      return true;
    } catch (e) {
      print('Error clearing chat: $e');
      return false;
    }
  }
}

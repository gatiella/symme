import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../models/chat_room.dart';
import '../models/message.dart';

class StorageService {
  static const String _userSecureIdKey = 'user_secure_id';
  static const String _userPrivateKeyKey = 'user_private_key';
  static const String _userPublicKeyKey = 'user_public_key';
  static const String _contactsKey = 'contacts';
  static const String _chatRoomsKey = 'chat_rooms';
  static const String _messagesKey = 'messages';
  static const String _userIdKey = 'user_id';

  // User Identity
  static Future<String?> getUserSecureId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userSecureIdKey);
  }

  static Future<void> setUserSecureId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userSecureIdKey, id);
  }

  static Future<String?> getUserPrivateKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPrivateKeyKey);
  }

  static Future<void> setUserPrivateKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPrivateKeyKey, key);
  }

  static Future<String?> getUserPublicKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPublicKeyKey);
  }

  static Future<void> setUserPublicKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPublicKeyKey, key);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> setUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, id);
  }

  // Contacts
  static Future<List<Contact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString(_contactsKey) ?? '[]';
    final List<dynamic> contactsList = jsonDecode(contactsJson);
    return contactsList.map((c) => Contact.fromJson(c)).toList();
  }

  static Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_contactsKey, contactsJson);
  }

  // Chat Rooms
  static Future<List<ChatRoom>> getChatRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final chatRoomsJson = prefs.getString(_chatRoomsKey) ?? '[]';
    final List<dynamic> chatRoomsList = jsonDecode(chatRoomsJson);
    return chatRoomsList.map((c) => ChatRoom.fromJson(c)).toList();
  }

  static Future<void> saveChatRooms(List<ChatRoom> chatRooms) async {
    final prefs = await SharedPreferences.getInstance();
    final chatRoomsJson = jsonEncode(chatRooms.map((c) => c.toJson()).toList());
    await prefs.setString(_chatRoomsKey, chatRoomsJson);
  }

  // Messages
  static Future<List<Message>> getMessages(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('${_messagesKey}_$roomId') ?? '[]';
    final List<dynamic> messagesList = jsonDecode(messagesJson);
    return messagesList.map((m) => Message.fromJson(m)).toList();
  }

  static Future<void> saveMessages(
    String roomId,
    List<Message> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString('${_messagesKey}_$roomId', messagesJson);
  }

  // App Settings
  static Future<int> getDisappearingMessageTimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('disappearing_timer') ??
        (7 * 24 * 60 * 60); // 7 days default
  }

  static Future<void> setDisappearingMessageTimer(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('disappearing_timer', seconds);
  }

  static Future<bool> getAutoDeleteExpired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_delete_expired') ?? true;
  }

  static Future<void> setAutoDeleteExpired(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_delete_expired', enabled);
  }

  // Security Settings
  static Future<List<String>> getBlockedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('blocked_contacts') ?? [];
  }

  static Future<void> setBlockedContacts(List<String> blockedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_contacts', blockedIds);
  }

  static Future<void> blockContact(String secureId) async {
    final blocked = await getBlockedContacts();
    if (!blocked.contains(secureId)) {
      blocked.add(secureId);
      await setBlockedContacts(blocked);
    }
  }

  static Future<void> unblockContact(String secureId) async {
    final blocked = await getBlockedContacts();
    blocked.remove(secureId);
    await setBlockedContacts(blocked);
  }

  static Future<bool> isContactBlocked(String secureId) async {
    final blocked = await getBlockedContacts();
    return blocked.contains(secureId);
  }

  // Encryption Keys Management
  static Future<void> rotateEncryptionKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_key_rotation',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<int> getLastKeyRotation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_key_rotation') ?? 0;
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Clear only messages (keep contacts and settings)
  static Future<void> clearAllMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_messagesKey));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

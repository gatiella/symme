class ChatRoom {
  final String contactId;
  final String contactName;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final bool isEncrypted;
  final String roomId;

  ChatRoom({
    required this.contactId,
    required this.contactName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isEncrypted = true,
    required this.roomId,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      contactId: json['contactId'],
      contactName: json['contactName'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'],
      unreadCount: json['unreadCount'] ?? 0,
      isEncrypted: json['isEncrypted'] ?? true,
      roomId: json['roomId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactId': contactId,
      'contactName': contactName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'isEncrypted': isEncrypted,
      'roomId': roomId,
    };
  }

  ChatRoom copyWith({
    String? contactId,
    String? contactName,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    bool? isEncrypted,
    String? roomId,
  }) {
    return ChatRoom(
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      roomId: roomId ?? this.roomId,
    );
  }
}
enum MessageType { text, image, file, voice, system }

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final bool isEncrypted;
  final int? expiresInSeconds;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.isEncrypted = true,
    this.expiresInSeconds, DateTime? expiresAt,
  });

  // Replace your existing fromJson method with this:
factory Message.fromJson(Map<String, dynamic> json) {
  try {
    return Message(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      content: json['content']?.toString() ?? '[Empty message]',
      type: MessageType.values[json['type'] as int? ?? 0],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isRead: json['isRead'] as bool? ?? false,
      isDelivered: json['isDelivered'] as bool? ?? true,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
          : null,
    );
  } catch (e) {
    print('Error parsing message JSON: $e');
    print('JSON data: $json');
    
    // Return a fallback message instead of throwing
    return Message(
      id: json['id']?.toString() ?? 'error_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'error',
      receiverId: json['receiverId']?.toString() ?? '',
      content: '[Failed to parse message]',
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
      isDelivered: false,
      isEncrypted: false,
    );
  }
}
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isDelivered,
    bool? isEncrypted,
    int? expiresInSeconds,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
    );
  }

  // Replace your existing toJson method with this:
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index, // Keep as index to match your current fromJson
      'timestamp': timestamp
          .millisecondsSinceEpoch, // Store as milliseconds for Firebase
      'isRead': isRead,
      'isDelivered': isDelivered,
      'isEncrypted': isEncrypted,
      'expiresInSeconds': expiresInSeconds,
    };
  }

  bool get isExpired {
    if (expiresInSeconds == null) return false;
    return DateTime.now().difference(timestamp).inSeconds > expiresInSeconds!;
  }
}

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
    this.expiresInSeconds,
  });

  // Replace your existing fromJson method with this:
  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: json['id'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        receiverId: json['receiverId'] as String? ?? '',
        content: json['content'] as String? ?? '',
        type: json['type'] is int
            ? MessageType.values[json['type']]
            : MessageType.values.firstWhere(
                (e) => e.name == json['type'],
                orElse: () => MessageType.text,
              ),
        timestamp: json['timestamp'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
            : json['timestamp'] is String
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
        isDelivered: json['isDelivered'] as bool? ?? false,
        isEncrypted: json['isEncrypted'] as bool? ?? true,
        expiresInSeconds: json['expiresInSeconds'] as int?,
      );
    } catch (e) {
      print('Error in Message.fromJson: $e');
      print('JSON data: $json');
      rethrow;
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

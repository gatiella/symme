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
  final DateTime? expiresAt;

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
    this.expiresAt,
  });

  // Factory constructor for creating expiring messages
  factory Message.expiring({
    required String id,
    required String senderId,
    required String receiverId,
    required String content,
    required MessageType type,
    DateTime? timestamp,
    bool isRead = false,
    bool isDelivered = false,
    bool isEncrypted = true,
    required int expiresInSeconds,
  }) {
    final msgTimestamp = timestamp ?? DateTime.now();
    return Message(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      timestamp: msgTimestamp,
      isRead: isRead,
      isDelivered: isDelivered,
      isEncrypted: isEncrypted,
      expiresAt: msgTimestamp.add(Duration(seconds: expiresInSeconds)),
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'isEncrypted': isEncrypted,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
    };
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
    DateTime? expiresAt,
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
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Check if the message has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Get remaining time until expiration
  Duration? get timeUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  // Check if message expires soon (within given duration)
  bool expiresSoon([Duration threshold = const Duration(minutes: 5)]) {
    final remaining = timeUntilExpiration;
    if (remaining == null) return false;
    return remaining <= threshold && remaining > Duration.zero;
  }

  // Get expiration status as a readable string
  String get expirationStatus {
    if (expiresAt == null) return 'No expiration';
    if (isExpired) return 'Expired';
    
    final remaining = timeUntilExpiration!;
    if (remaining.inDays > 0) {
      return 'Expires in ${remaining.inDays} day(s)';
    } else if (remaining.inHours > 0) {
      return 'Expires in ${remaining.inHours} hour(s)';
    } else if (remaining.inMinutes > 0) {
      return 'Expires in ${remaining.inMinutes} minute(s)';
    } else {
      return 'Expires in ${remaining.inSeconds} second(s)';
    }
  }

  @override
  String toString() {
    return 'Message(id: $id, from: $senderId, to: $receiverId, type: $type, '
           'timestamp: $timestamp, expires: $expirationStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
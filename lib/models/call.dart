enum CallType { audio, video }

enum CallStatus {
  outgoing,
  incoming,
  connecting,
  connected,
  ended,
  declined,
  missed,
  failed,
}

class Call {
  final String id;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;
  final DateTime timestamp;
  final int? duration; // in seconds
  final String? callerName;
  final String? receiverName;
  final Map<String, dynamic>?
  metadata; // Added for storing offer data and other call info

  Call({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
    required this.timestamp,
    this.duration,
    this.callerName,
    this.receiverName,
    this.metadata, // Added parameter
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'],
      callerId: json['callerId'],
      receiverId: json['receiverId'],
      type: CallType.values.firstWhere(
        (e) => e.toString() == 'CallType.${json['type']}',
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.toString() == 'CallStatus.${json['status']}',
        orElse: () => CallStatus.ended,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      duration: json['duration'],
      callerName: json['callerName'],
      receiverName: json['receiverName'],
      metadata: json['metadata'] as Map<String, dynamic>?, // Added field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration,
      'callerName': callerName,
      'receiverName': receiverName,
      'metadata': metadata, // Added field
    };
  }

  Call copyWith({
    String? id,
    String? callerId,
    String? receiverId,
    CallType? type,
    CallStatus? status,
    DateTime? timestamp,
    int? duration,
    String? callerName,
    String? receiverName,
    Map<String, dynamic>? metadata, // Added parameter
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      callerName: callerName ?? this.callerName,
      receiverName: receiverName ?? this.receiverName,
      metadata: metadata ?? this.metadata, // Added field
    );
  }

  String get formattedDuration {
    if (duration == null) return '';

    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

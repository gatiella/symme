class Contact {
  final String publicId;
  final String name;
  final DateTime addedAt;
  final bool isOnline;
  final String? lastSeen;

  Contact({
    required this.publicId,
    required this.name,
    required this.addedAt,
    this.isOnline = false,
    this.lastSeen,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      publicId: json['publicId'],
      name: json['name'],
      addedAt: DateTime.parse(json['addedAt']),
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'name': name,
      'addedAt': addedAt.toIso8601String(),
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }

  Contact copyWith({
    String? publicId,
    String? name,
    DateTime? addedAt,
    bool? isOnline,
    String? lastSeen,
  }) {
    return Contact(
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      addedAt: addedAt ?? this.addedAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

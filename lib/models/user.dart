class AppUser {
  final String id;
  final String secureId;
  final String name;
  final String? email;
  final DateTime? createdAt;
  final bool isActive;
  final DateTime? lastSeen;
  final String? publicKey;

  AppUser({
    required this.id,
    required this.secureId,
    required this.name,
    this.email,
    this.createdAt,
    this.isActive = false,
    this.lastSeen,
    this.publicKey,
  });

  // Convert from Realtime Database
  factory AppUser.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      secureId: data['secureId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'],
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : null,
      isActive: data['isActive'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'])
          : null,
      publicKey: data['publicKey'],
    );
  }

  // Convert to Realtime Database
  Map<String, dynamic> toRealtimeDatabase() {
    final data = <String, dynamic>{
      'secureId': secureId,
      'name': name,
      'isActive': isActive,
    };

    if (email != null) data['email'] = email;
    if (createdAt != null) {
      data['createdAt'] = createdAt!.millisecondsSinceEpoch;
    }
    if (lastSeen != null) data['lastSeen'] = lastSeen!.millisecondsSinceEpoch;
    if (publicKey != null) data['publicKey'] = publicKey;

    return data;
  }

  // Keep the old Firestore method for backward compatibility
  factory AppUser.fromFirestore(dynamic doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      secureId: doc.id, // Assuming doc.id is the secureId in old structure
      name: data['name'] ?? '',
      email: data['email'],
      createdAt: DateTime.now(),
      isActive: data['isActive'] ?? false,
      lastSeen: DateTime.now(),
      publicKey: data['publicKey'],
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'secureId': secureId,
      'name': name,
      'isActive': isActive,
    };

    if (email != null) data['email'] = email;
    if (createdAt != null) {
      data['createdAt'] = createdAt!.millisecondsSinceEpoch;
    }
    if (lastSeen != null) data['lastSeen'] = lastSeen!.millisecondsSinceEpoch;
    if (publicKey != null) data['publicKey'] = publicKey;

    return data;
  }

  // Utility methods
  AppUser copyWith({
    String? id,
    String? secureId,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? isActive,
    DateTime? lastSeen,
    String? publicKey,
  }) {
    return AppUser(
      id: id ?? this.id,
      secureId: secureId ?? this.secureId,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      publicKey: publicKey ?? this.publicKey,
    );
  }

  String get displayName => name.isNotEmpty ? name : secureId;

  bool get hasPublicKey => publicKey != null && publicKey!.isNotEmpty;

  String getLastSeenText() {
    if (!isActive) {
      if (lastSeen == null) return 'Offline';

      final now = DateTime.now();
      final difference = now.difference(lastSeen!);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    }
    return 'Online';
  }

  @override
  String toString() {
    return 'AppUser(id: $id, secureId: $secureId, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

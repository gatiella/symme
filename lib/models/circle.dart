class Circle {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final List<String> members;

  Circle({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.members,
  });

  // Convert from Realtime Database
  factory Circle.fromRealtimeDatabase(Map<String, dynamic> data, String id) {
    return Circle(
      id: id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      members: List<String>.from(data['members'] ?? []),
    );
  }

  // Convert to Realtime Database
  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'name': name,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'members': members,
    };
  }

  // Keep the old Firestore methods for backward compatibility if needed
  factory Circle.fromFirestore(dynamic doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Circle(
      id: doc.id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: DateTime.now(), // Convert from Timestamp if needed
      members: List<String>.from(data['members'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'members': members,
    };
  }

  // Utility methods
  Circle copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    List<String>? members,
  }) {
    return Circle(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }

  bool isMember(String userSecureId) {
    return members.contains(userSecureId);
  }

  bool isCreator(String userSecureId) {
    return createdBy == userSecureId;
  }

  @override
  String toString() {
    return 'Circle(id: $id, name: $name, createdBy: $createdBy, members: ${members.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Circle && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

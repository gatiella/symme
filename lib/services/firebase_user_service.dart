import 'package:firebase_database/firebase_database.dart';
import 'package:symme/models/user.dart';

class FirebaseUserService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  static Future<AppUser?> getUserBySecureId(String secureId) async {
    try {
      // First, get the user ID from the secureId mapping
      final secureIdSnapshot = await _database
          .child('secureIds/$secureId')
          .once();

      if (!secureIdSnapshot.snapshot.exists) {
        print('Secure ID not found: $secureId');
        return null;
      }

      final secureIdData =
          secureIdSnapshot.snapshot.value as Map<dynamic, dynamic>;
      final userId = secureIdData['userId'] as String?;

      if (userId == null) {
        print('User ID not found in secure ID mapping');
        return null;
      }

      // Get the user data
      final userSnapshot = await _database.child('users/$userId').once();

      if (!userSnapshot.snapshot.exists) {
        print('User data not found for ID: $userId');
        return null;
      }

      final userData = userSnapshot.snapshot.value as Map<dynamic, dynamic>;
      return AppUser.fromRealtimeDatabase(
        Map<String, dynamic>.from(userData),
        userId,
      );
    } catch (e) {
      print('Error getting user by secureId: $e');
      return null;
    }
  }

  static Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _database.child('users').once();

      if (!snapshot.snapshot.exists) {
        return [];
      }

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final users = <AppUser>[];

      data.forEach((userId, userData) {
        try {
          if (userData is Map<dynamic, dynamic>) {
            final user = AppUser.fromRealtimeDatabase(
              Map<String, dynamic>.from(userData),
              userId.toString(),
            );
            users.add(user);
          }
        } catch (e) {
          print('Error parsing user $userId: $e');
        }
      });

      return users;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  static Future<List<AppUser>> searchUsersByName(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final allUsers = await getAllUsers();
      final lowerQuery = query.toLowerCase();

      return allUsers.where((user) {
        return user.name.toLowerCase().contains(lowerQuery) ||
            user.secureId.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching users by name: $e');
      return [];
    }
  }

  static Future<List<AppUser>> searchUsersBySecureId(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final allUsers = await getAllUsers();
      final upperQuery = query.toUpperCase();

      return allUsers.where((user) {
        return user.secureId.contains(upperQuery);
      }).toList();
    } catch (e) {
      print('Error searching users by secure ID: $e');
      return [];
    }
  }

  static Future<AppUser?> getUserById(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').once();

      if (!snapshot.snapshot.exists) {
        return null;
      }

      final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return AppUser.fromRealtimeDatabase(
        Map<String, dynamic>.from(userData),
        userId,
      );
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  static Future<void> updateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _database.child('users/$userId').update(updates);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  static Future<bool> isSecureIdTaken(String secureId) async {
    try {
      final snapshot = await _database.child('secureIds/$secureId').once();
      return snapshot.snapshot.exists;
    } catch (e) {
      print('Error checking if secure ID is taken: $e');
      return true; // Assume taken on error for safety
    }
  }
}

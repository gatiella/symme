import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import 'dart:math';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Anonymous authentication for privacy
  static Future<User?> signInAnonymously() async {
    try {
      print('Starting anonymous sign in...');
      final UserCredential result = await _auth.signInAnonymously();
      final User? user = result.user;

      if (user != null) {
        print('Anonymous user created: ${user.uid}');

        // Initialize user data with better error handling
        try {
          await _initializeUserData(user.uid);
          print('User data initialized successfully');
        } catch (e) {
          print('Warning: User data initialization failed, but auth succeeded: $e');
          // Don't throw here - let the user proceed with basic auth
          // Store basic info locally even if database write fails
          await StorageService.setUserId(user.uid);
        }

        return user;
      } else {
        print('Anonymous sign in failed: user is null');
        return null;
      }
    } catch (e) {
      print('Anonymous sign in failed: $e');
      return null;
    }
  }

  static Future<void> _initializeUserData(String userId) async {
    try {
      print('Initializing user data for: $userId');

      // Check if user already has data
      final snapshot = await _database.child('users/$userId').once();
      print('User data exists: ${snapshot.snapshot.exists}');

      if (!snapshot.snapshot.exists) {
        print('Creating new user profile...');

        // Generate new secure ID
        final secureId = _generateUniqueSecureId();
        print('Generated secure ID: $secureId');

        final keyPair = CryptoService.generateKeyPair();
        print('Generated key pair');

        final userData = {
          'secureId': secureId,
          'publicKey': keyPair['public'],
          'createdAt': ServerValue.timestamp,
          'lastSeen': ServerValue.timestamp,
          'isActive': true,
          'keyGeneratedAt': ServerValue.timestamp,
        };

        print('Writing user data to database...');
        await _database.child('users/$userId').set(userData);
        print('User data written successfully');

        print('Writing secure ID mapping...');
        try {
          await _database.child('secureIds/$secureId').set({
            'userId': userId,
            'createdAt': ServerValue.timestamp,
            'isActive': true,
          });
          print('Secure ID mapping written successfully');
        } catch (e) {
          print('Warning: Failed to write secure ID mapping: $e');
          // Continue anyway - the user data is more important
        }

        // Store data locally
        print('Storing data locally...');
        await StorageService.setUserPrivateKey(keyPair['private']!);
        await StorageService.setUserSecureId(secureId);
        await StorageService.setUserId(userId);
        print('Local storage completed');
      } else {
        print('User exists, updating last seen...');

        // Update last seen
        await _database.child('users/$userId').update({
          'lastSeen': ServerValue.timestamp,
          'isActive': true,
        });

        // Get and store secure ID locally
        final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final existingSecureId = userData['secureId'] as String?;

        if (existingSecureId != null) {
          await StorageService.setUserSecureId(existingSecureId);
          print('Stored existing secure ID: $existingSecureId');
        } else {
          print('Warning: Existing user has no secure ID');
        }

        await StorageService.setUserId(userId);
        print('Updated existing user successfully');
      }
    } catch (e, stackTrace) {
      print('Error initializing user data: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Re-throw for the calling method to handle
    }
  }

  static String _generateUniqueSecureId() {
    // Generate 12-character unique ID
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    String id;
    do {
      id = String.fromCharCodes(
        Iterable.generate(
          12,
              (_) => chars.codeUnitAt(random.nextInt(chars.length)),
        ),
      );
    } while (id.length != 12);

    return id;
  }

  static Future<bool> regenerateSecureId() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Get current secure ID
      final currentSnapshot = await _database.child('users/${user.uid}').once();
      if (currentSnapshot.snapshot.exists) {
        final userData =
        currentSnapshot.snapshot.value as Map<dynamic, dynamic>;
        final oldSecureId = userData['secureId'];

        // Deactivate old secure ID
        if (oldSecureId != null) {
          try {
            await _database.child('secureIds/$oldSecureId').update({
              'isActive': false,
              'deactivatedAt': ServerValue.timestamp,
            });
          } catch (e) {
            print('Warning: Failed to deactivate old secure ID: $e');
          }
        }
      }

      // Generate new secure ID and key pair
      final newSecureId = _generateUniqueSecureId();
      final newKeyPair = CryptoService.generateKeyPair();

      // Update user data
      await _database.child('users/${user.uid}').update({
        'secureId': newSecureId,
        'publicKey': newKeyPair['public'],
        'keyGeneratedAt': ServerValue.timestamp,
      });

      // Create new secure ID mapping
      try {
        await _database.child('secureIds/$newSecureId').set({
          'userId': user.uid,
          'createdAt': ServerValue.timestamp,
          'isActive': true,
        });
      } catch (e) {
        print('Warning: Failed to create new secure ID mapping: $e');
      }

      // Update local storage
      await StorageService.setUserPrivateKey(newKeyPair['private']!);
      await StorageService.setUserSecureId(newSecureId);
      await StorageService.setUserId(user.uid);

      return true;
    } catch (e) {
      print('Error regenerating secure ID: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserBySecureId(
      String secureId,
      ) async {
    try {
      // Check if secure ID is active
      final idSnapshot = await _database.child('secureIds/$secureId').once();
      if (!idSnapshot.snapshot.exists) return null;

      final idData = idSnapshot.snapshot.value as Map<dynamic, dynamic>;
      if (!idData['isActive']) return null;

      // Get user data
      final userId = idData['userId'];
      final userSnapshot = await _database.child('users/$userId').once();

      if (userSnapshot.snapshot.exists) {
        final userData = userSnapshot.snapshot.value as Map<dynamic, dynamic>;

        // Check if user is still active (within 30 days)
        final lastSeen = userData['lastSeen'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        final daysSinceLastSeen = (now - lastSeen) / (1000 * 60 * 60 * 24);

        if (daysSinceLastSeen > 30) {
          // Deactivate inactive user
          await _deactivateUser(userId, secureId);
          return null;
        }

        return {
          'userId': userId,
          'secureId': userData['secureId'],
          'publicKey': userData['publicKey'],
          'lastSeen': userData['lastSeen'],
          'isActive': userData['isActive'],
        };
      }

      return null;
    } catch (e) {
      print('Error getting user by secure ID: $e');
      return null;
    }
  }

  static Future<void> _deactivateUser(String userId, String secureId) async {
    await _database.child('users/$userId').update({
      'isActive': false,
      'deactivatedAt': ServerValue.timestamp,
    });

    await _database.child('secureIds/$secureId').update({
      'isActive': false,
      'deactivatedAt': ServerValue.timestamp,
    });
  }

  static Future<void> updateLastSeen() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _database.child('users/${user.uid}').update({
        'lastSeen': ServerValue.timestamp,
        'isActive': true,
      });
    }
  }

  static Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _database.child('users/${user.uid}').update({
        'isActive': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
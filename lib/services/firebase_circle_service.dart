import 'package:firebase_database/firebase_database.dart';
import 'package:symme/models/circle.dart';
import 'dart:async';

class FirebaseCircleService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  static Future<String> createCircle(String name, String createdBy) async {
    try {
      final circleRef = _database.child('circles').push();
      final circleId = circleRef.key!;

      final Circle newCircle = Circle(
        id: circleId,
        name: name,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        members: [createdBy],
      );

      await circleRef.set(newCircle.toRealtimeDatabase());
      return circleId;
    } catch (e) {
      print('Error creating circle: $e');
      rethrow;
    }
  }

  static Stream<List<Circle>> getCircles(String userSecureId) {
    final StreamController<List<Circle>> controller =
        StreamController<List<Circle>>();

    _database
        .child('circles')
        .onValue
        .listen(
          (event) {
            final value = event.snapshot.value;

            if (value == null) {
              controller.add([]);
              return;
            }

            final circles = <Circle>[];

            if (value is Map) {
              value.forEach((circleId, circleData) {
                try {
                  if (circleData is Map) {
                    final circleMap = Map<String, dynamic>.from(circleData);

                    // Fix: Handle members field properly
                    final membersData = circleData['members'];
                    final members = <String>[];

                    if (membersData is List) {
                      // Convert all list items to strings
                      for (var member in membersData) {
                        if (member != null) {
                          members.add(member.toString());
                        }
                      }
                    } else if (membersData is Map) {
                      // If stored as map, get values
                      for (var member in membersData.values) {
                        if (member != null) {
                          members.add(member.toString());
                        }
                      }
                    }

                    // Only add circle if user is a member
                    if (members.contains(userSecureId)) {
                      // Update the circleMap with properly formatted members
                      circleMap['members'] = members;

                      final circle = Circle.fromRealtimeDatabase(
                        circleMap,
                        circleId.toString(),
                      );
                      circles.add(circle);
                    }
                  }
                } catch (e) {
                  print('Error parsing circle $circleId: $e');
                }
              });
            }

            // Sort by creation date (newest first)
            circles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            controller.add(circles);
          },
          onError: (error) {
            print('Error listening to circles: $error');
            controller.addError(error);
          },
        );

    return controller.stream;
  }

  static Future<void> addMemberToCircle(
    String circleId,
    String userSecureId,
  ) async {
    try {
      final circleRef = _database.child('circles/$circleId');

      // Get current members
      final snapshot = await circleRef.child('members').once();
      final currentMembers = <String>[];

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value;
        if (data is List) {
          for (var member in data) {
            if (member != null) {
              currentMembers.add(member.toString());
            }
          }
        } else if (data is Map) {
          for (var member in data.values) {
            if (member != null) {
              currentMembers.add(member.toString());
            }
          }
        }
      }

      // Add new member if not already present
      if (!currentMembers.contains(userSecureId)) {
        currentMembers.add(userSecureId);
        await circleRef.child('members').set(currentMembers);
      }
    } catch (e) {
      print('Error adding member to circle: $e');
      rethrow;
    }
  }

  static Future<void> removeMemberFromCircle(
    String circleId,
    String userSecureId,
  ) async {
    try {
      final circleRef = _database.child('circles/$circleId');

      // Get current members
      final snapshot = await circleRef.child('members').once();
      final currentMembers = <String>[];

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value;
        if (data is List) {
          for (var member in data) {
            if (member != null) {
              currentMembers.add(member.toString());
            }
          }
        } else if (data is Map) {
          for (var member in data.values) {
            if (member != null) {
              currentMembers.add(member.toString());
            }
          }
        }
      }

      // Remove member
      currentMembers.remove(userSecureId);

      // If no members left, delete the circle
      if (currentMembers.isEmpty) {
        await circleRef.remove();
      } else {
        await circleRef.child('members').set(currentMembers);
      }
    } catch (e) {
      print('Error removing member from circle: $e');
      rethrow;
    }
  }

  static Future<Circle?> getCircleById(String circleId) async {
    try {
      final snapshot = await _database.child('circles/$circleId').once();

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final circleMap = Map<String, dynamic>.from(data);

        // Fix members field handling
        final membersData = data['members'];
        final members = <String>[];

        if (membersData is List) {
          for (var member in membersData) {
            if (member != null) {
              members.add(member.toString());
            }
          }
        } else if (membersData is Map) {
          for (var member in membersData.values) {
            if (member != null) {
              members.add(member.toString());
            }
          }
        }

        circleMap['members'] = members;

        return Circle.fromRealtimeDatabase(circleMap, circleId);
      }

      return null;
    } catch (e) {
      print('Error getting circle by ID: $e');
      return null;
    }
  }

  static Future<void> updateCircle(
    String circleId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _database.child('circles/$circleId').update(updates);
    } catch (e) {
      print('Error updating circle: $e');
      rethrow;
    }
  }

  static Future<void> deleteCircle(String circleId) async {
    try {
      await _database.child('circles/$circleId').remove();
    } catch (e) {
      print('Error deleting circle: $e');
      rethrow;
    }
  }
}

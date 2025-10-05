import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> getHabitCollection() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _firestore.collection("users").doc(user.uid).collection("habits");
  }

  // ---------------------- Add Habit ----------------------
  Future<void> addHabit(Map<String, dynamic> habitData) async {
    final habits = getHabitCollection();
    await habits.add({
      ...habitData,
      "createdAt": FieldValue.serverTimestamp(),
      "completed": false,
      "completedAt": null,
      "streakCount": 0,
      "lastCompletedDate": null,
    });
  }

  // ---------------------- Update Habit ----------------------
  Future<void> updateHabit(String id, Map<String, dynamic> habitData) async {
    final habits = getHabitCollection();
    habitData.remove("createdAt"); // don't override creation date
    await habits.doc(id).update(habitData);
  }

  // ---------------------- Delete Habit ----------------------
  Future<void> deleteHabit(String id) async {
    final habits = getHabitCollection();
    await habits.doc(id).delete();
  }

  // ---------------------- Toggle Complete ----------------------
  Future<void> toggleComplete(String id, Map<String, dynamic> habit) async {
    final habits = getHabitCollection();
    final isCompleted = habit["completed"] == true;
    final now = DateTime.now();
    final lastCompletedDate = habit["lastCompletedDate"] != null
        ? (habit["lastCompletedDate"] as Timestamp).toDate()
        : null;

    int newStreakCount = habit["streakCount"] ?? 0;

    if (!isCompleted) {
      if (lastCompletedDate == null) {
        newStreakCount = 1;
      } else {
        final difference = now.difference(lastCompletedDate).inDays;
        if (difference == 1) {
          newStreakCount += 1;
        } else if (difference > 1) {
          newStreakCount = 1;
        }
      }
    }

    await habits.doc(id).update({
      "completed": !isCompleted,
      "completedAt": !isCompleted ? FieldValue.serverTimestamp() : null,
      "lastCompletedDate": !isCompleted ? Timestamp.fromDate(now) : null,
      "streakCount": !isCompleted ? newStreakCount : 0,
    });
  }
}

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
    final frequency = (habit["frequency"] ?? "").toString().toLowerCase();
    final lastCompletedDate = habit["lastCompletedDate"] != null
        ? (habit["lastCompletedDate"] as Timestamp).toDate()
        : null;

    int newStreakCount = habit["streakCount"] ?? 0;

    // When marking as complete
    if (!isCompleted) {
      if (lastCompletedDate == null) {
        newStreakCount = 1; // First ever completion
      } else {
        final difference = now.difference(lastCompletedDate).inDays;

        if (frequency.contains("daily")) {
          if (difference == 1) {
            newStreakCount += 1; // consecutive daily streak
          } else if (difference > 1) {
            newStreakCount = 1; // missed a day, reset streak
          }
        } else if (frequency.contains("weekly")) {
          // Check week number difference
          int currentWeek = _getWeekNumber(now);
          int lastWeek = _getWeekNumber(lastCompletedDate);

          if (currentWeek - lastWeek == 1) {
            newStreakCount += 1; // consecutive week
          } else if (currentWeek != lastWeek) {
            newStreakCount = 1; // missed a week, reset streak
          }
        } else {
          // Default: daily logic fallback
          if (difference >= 1) {
            newStreakCount = 1;
          }
        }
      }
    }

    // Update Firestore
    await habits.doc(id).update({
      "completed": !isCompleted,
      "completedAt": !isCompleted ? FieldValue.serverTimestamp() : null,
      "lastCompletedDate": !isCompleted ? Timestamp.fromDate(now) : null,
      "streakCount": !isCompleted ? newStreakCount : 0,
    });
  }

  // Helper function to get week number of a given date
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final diff = date
        .difference(firstDayOfYear.subtract(Duration(days: daysOffset)))
        .inDays;
    return (diff / 7).ceil();
  }

  Future<void> refreshHabitsStatus() async {
    final habitsCollection = getHabitCollection();
    final snapshot = await habitsCollection.get();
    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lastCompletedDate = data["lastCompletedDate"] != null
          ? (data["lastCompletedDate"] as Timestamp).toDate()
          : null;
      final frequency = (data["frequency"] ?? "daily")
          .toLowerCase(); // "daily" or "weekly"
      final isCompleted = data["completed"] == true;

      if (lastCompletedDate == null) continue; // Skip new habits

      final daysSinceLast = now.difference(lastCompletedDate).inDays;

      bool shouldReset = false;

      if (frequency == "daily" &&
          daysSinceLast >= 1 &&
          !isSameDay(now, lastCompletedDate)) {
        shouldReset = true;
      } else if (frequency == "weekly" && daysSinceLast >= 7) {
        shouldReset = true;
      }

      if (shouldReset && isCompleted) {
        await habitsCollection.doc(doc.id).update({
          "completed": false,
          "streakCount": 0,
        });
      }
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

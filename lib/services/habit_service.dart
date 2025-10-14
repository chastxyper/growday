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
    habitData.remove("createdAt");
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
    final frequency = (habit["frequency"] ?? "daily").toString().toLowerCase();
    final lastCompletedDate = habit["lastCompletedDate"] != null
        ? (habit["lastCompletedDate"] as Timestamp).toDate()
        : null;

    int newStreakCount = habit["streakCount"] ?? 0;

    if (!isCompleted) {
      // Completing the habit
      if (lastCompletedDate == null) {
        newStreakCount = 1;
      } else {
        final difference = now.difference(lastCompletedDate).inDays;

        if (frequency == "daily") {
          if (difference == 1) {
            newStreakCount += 1; // consecutive day
          } else if (difference > 1) {
            newStreakCount = 1; // missed a day, reset
          }
        } else if (frequency == "weekly") {
          int currentWeek = _getWeekNumber(now);
          int lastWeek = _getWeekNumber(lastCompletedDate);
          if (currentWeek - lastWeek == 1) {
            newStreakCount += 1; // consecutive week
          } else if (currentWeek != lastWeek) {
            newStreakCount = 1; // missed a week, reset
          }
        }
      }
    }

    await habits.doc(id).update({
      "completed": !isCompleted,
      "completedAt": !isCompleted ? FieldValue.serverTimestamp() : null,
      "lastCompletedDate": !isCompleted ? Timestamp.fromDate(now) : null,
      "streakCount": newStreakCount,
    });
  }

  // Helper: get week number
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final diff = date
        .difference(firstDayOfYear.subtract(Duration(days: daysOffset)))
        .inDays;
    return (diff / 7).ceil();
  }

  // ---------------------- Daily / Weekly Reset ----------------------
  Future<void> refreshHabitsStatus() async {
    final habitsCollection = getHabitCollection();
    final snapshot = await habitsCollection.get();
    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lastCompletedDate = data["lastCompletedDate"] != null
          ? (data["lastCompletedDate"] as Timestamp).toDate()
          : null;
      final frequency = (data["frequency"] ?? "daily").toLowerCase();
      final isCompleted = data["completed"] == true;
      final streakCount = data["streakCount"] ?? 0;

      if (lastCompletedDate == null) continue;

      bool shouldReset = false;

      if (frequency == "daily") {
        if (!isSameDay(now, lastCompletedDate) &&
            now.difference(lastCompletedDate).inDays >= 1) {
          shouldReset = true;
        }
      } else if (frequency == "weekly") {
        int currentWeek = _getWeekNumber(now);
        int lastWeek = _getWeekNumber(lastCompletedDate);
        if (currentWeek != lastWeek) {
          shouldReset = true;
        }
      }

      if (shouldReset && isCompleted) {
        await habitsCollection.doc(doc.id).update({
          "completed": false,
          "streakCount": 0, // Reset streak when missed
        });
      }
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

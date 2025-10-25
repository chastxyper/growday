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

  // ---------------------- Add Habit (UTC Safe) ----------------------
  Future<void> addHabit(Map<String, dynamic> habitData) async {
    final habits = getHabitCollection();
    final now = DateTime.now().toUtc();

    await habits.add({
      ...habitData,
      "createdAt": Timestamp.fromDate(now),
      "completed": false,
      "completedAt": null,
      "streakCount": 0,
      "longestStreak": 0,
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

  // ---------------------- Toggle Complete (UTC Safe) ----------------------
  Future<void> toggleComplete(String id) async {
    final habits = getHabitCollection();
    final docRef = habits.doc(id);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) throw Exception("Habit not found");

      final data = snapshot.data()!;
      final isCompleted = data["completed"] == true;
      final frequency = (data["frequency"] ?? "daily").toString().toLowerCase();

      final lastTs = data["lastCompletedDate"] as Timestamp?;
      final lastDate = lastTs?.toDate().toUtc();
      final now = DateTime.now().toUtc();

      final nowDateOnly = DateTime.utc(now.year, now.month, now.day);
      DateTime? lastDateOnly;
      if (lastDate != null) {
        lastDateOnly = DateTime.utc(
          lastDate.year,
          lastDate.month,
          lastDate.day,
        );
      }

      int newStreak = data["streakCount"] ?? 0;
      int longestStreak = data["longestStreak"] ?? 0;

      if (!isCompleted) {
        // Completing habit
        if (lastDateOnly == null) {
          newStreak = 1;
        } else {
          if (frequency == "daily") {
            final dayDiff = nowDateOnly.difference(lastDateOnly).inDays;
            if (dayDiff == 1) {
              newStreak += 1;
            } else if (dayDiff > 1 || dayDiff < 0) {
              newStreak = 1;
            } else if (dayDiff == 0) {
              newStreak = data["streakCount"] ?? 1;
            }
          } else if (frequency == "weekly") {
            final currentWeek = _getIsoWeekNumber(now);
            final lastWeek = _getIsoWeekNumber(lastDate!);
            final currentYear = now.year;
            final lastYear = lastDate.year;
            final weekDiff =
                (currentYear - lastYear) * 53 + (currentWeek - lastWeek);
            if (weekDiff == 1) {
              newStreak += 1;
            } else if (weekDiff > 1 || weekDiff <= 0) {
              newStreak = 1;
            }
          }
        }

        if (newStreak > longestStreak) longestStreak = newStreak;

        tx.update(docRef, {
          "completed": true,
          "completedAt": Timestamp.fromDate(now),
          "lastCompletedDate": Timestamp.fromDate(now),
          "streakCount": newStreak,
          "longestStreak": longestStreak,
        });
      } else {
        // Uncomplete habit
        tx.update(docRef, {
          "completed": false,
          "completedAt": null,
          "lastCompletedDate": null,
        });
      }
    });
  }

  // ---------------------- Daily / Weekly Reset (Improved Streak Logic - UTC Safe) ----------------------
  Future<void> refreshHabitsStatus() async {
    final habitsCollection = getHabitCollection();
    final snapshot = await habitsCollection.get();

    final now = DateTime.now().toUtc();
    final nowDateOnly = DateTime.utc(now.year, now.month, now.day);

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lastTs = data["lastCompletedDate"] as Timestamp?;
      final frequency = (data["frequency"] ?? "daily").toString().toLowerCase();
      final isCompleted = data["completed"] == true;

      if (lastTs == null) {
        if (isCompleted) {
          await habitsCollection.doc(doc.id).update({"completed": false});
        }
        continue;
      }

      final lastDate = lastTs.toDate().toUtc();
      final lastDateOnly = DateTime.utc(
        lastDate.year,
        lastDate.month,
        lastDate.day,
      );

      bool shouldUnmark = false;
      bool shouldResetStreak = false;

      if (frequency == "daily") {
        final dayDiff = nowDateOnly.difference(lastDateOnly).inDays;
        if (dayDiff == 1) {
          // new day — unmark complete but keep streak
          shouldUnmark = true;
        } else if (dayDiff > 1) {
          // missed at least 2 days — reset streak
          shouldUnmark = true;
          shouldResetStreak = true;
        }
      } else if (frequency == "weekly") {
        final currentWeek = _getIsoWeekNumber(now);
        final lastWeek = _getIsoWeekNumber(lastDate);
        final currentYear = now.year;
        final lastYear = lastDate.year;
        final weekDiff =
            (currentYear - lastYear) * 53 + (currentWeek - lastWeek);

        if (weekDiff == 1) {
          shouldUnmark = true; // new week — keep streak
        } else if (weekDiff > 1) {
          shouldUnmark = true;
          shouldResetStreak = true;
        }
      }

      if (shouldUnmark) {
        final Map<String, dynamic> updateData = {"completed": false};
        if (shouldResetStreak) updateData["streakCount"] = 0;
        await habitsCollection.doc(doc.id).update(updateData);
      }
    }
  }

  // ---------------------- Helper Functions ----------------------
  int _getIsoWeekNumber(DateTime date) {
    final wednesday = date.add(Duration(days: (3 - ((date.weekday + 6) % 7))));
    final firstThursday = DateTime(wednesday.year, 1, 4);
    final weekNumber = 1 + ((wednesday.difference(firstThursday).inDays ~/ 7));
    return weekNumber;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

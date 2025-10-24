import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';
import 'habit_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final HabitService _habitService = HabitService();

  // 🔹 Access user's habit collection in Firestore
  CollectionReference<Map<String, dynamic>> get _habitCollection {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("habits");
  }

  @override
  void initState() {
    super.initState();
    _setupNotification(); // 🔔 Schedule daily notifications when app starts
  }

  // 🔹 Initializes local notifications
  Future<void> _setupNotification() async {
    await NotificationService.initialize();
    await NotificationService.scheduleDailyReminder();
  }

  // 🔹 Opens HabitFormPage for adding or editing a habit
  Future<void> _openHabitForm({String? id, Map<String, dynamic>? habit}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HabitFormPage(
          id: id,
          habit: habit,
          onSave: (habitData, {String? id}) async {
            if (id == null) {
              await _habitService.addHabit(habitData);
              _showSnack("Habit added successfully", Colors.green);
            } else {
              await _habitService.updateHabit(id, habitData);
              _showSnack("Habit updated successfully", Colors.blue);
            }
          },
        ),
      ),
    );
  }

  // 🔹 Confirms and deletes a habit from Firestore
  Future<void> _deleteHabit(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          "Confirm Delete",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to delete \"$title\"?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _habitService.deleteHabit(id);
      _showSnack("Habit deleted", Colors.red);
    }
  }

  // 🔹 Marks habit as complete or incomplete
  Future<void> _toggleComplete(String id, Map<String, dynamic> habit) async {
    await _habitService.toggleComplete(id);
    _showSnack(
      habit["completed"] == true
          ? "Habit marked incomplete"
          : "Habit completed 🎉",
      habit["completed"] == true ? Colors.orange : Colors.green,
    );
  }

  // 🔹 Displays habit details in a popup dialog
  void _showHabitDetails(String id, Map<String, dynamic> habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(
          habit["title"] ?? "Habit Details",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (habit["description"] != null && habit["description"] != "")
              Text(
                habit["description"],
                style: const TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 10),
            Text(
              "Frequency: ${habit["frequency"] ?? "N/A"}",
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              "Streak: ${habit["streakCount"] ?? 0} 🔥",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _toggleComplete(id, habit);
            },
            child: Text(
              habit["completed"] == true
                  ? "Mark Incomplete"
                  : "Mark Complete ✅",
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Handles user logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // ⚠️ Reminder: redirect to login screen after logout
  }

  // 🔹 Shows feedback messages
  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // 🖤 Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2E),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // ☰ White menu icon
        title: const Text(
          "GrowDay",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // ✅ White title text
          ),
        ),
      ),

      // 🔹 Drawer with user info and logout option
      drawer: Drawer(
        backgroundColor: const Color(0xFF2C2C2E),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user?.displayName ?? "User",
                style: const TextStyle(color: Colors.white),
              ),
              accountEmail: Text(
                user?.email ?? "No email",
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
              ),
              decoration: const BoxDecoration(color: Colors.deepPurple),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                "Settings",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // ⚙️ TODO: Add settings page or theme toggle here
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),

      // 🔹 StreamBuilder listens to Firestore for real-time habit updates
      body: StreamBuilder<QuerySnapshot>(
        stream: _habitCollection
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading habits",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;
          if (data.isEmpty) {
            return const Center(
              child: Text(
                "No habits yet.\nTap + to add one!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            );
          }

          // 🔹 Displays list of habits with swipe actions
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final doc = data[index];
              final habit = doc.data() as Map<String, dynamic>;
              final id = doc.id;

              return Dismissible(
                key: Key(id),
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.check, color: Colors.white, size: 28),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                // 🧭 Swipe left = delete | Swipe right = complete
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _toggleComplete(id, habit);
                    return false; // Prevent auto-dismiss
                  } else if (direction == DismissDirection.endToStart) {
                    await _deleteHabit(id, habit["title"] ?? "");
                    return false;
                  }
                  return false;
                },

                child: Card(
                  color: const Color(0xFF2C2C2E),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    onTap: () => _showHabitDetails(id, habit),
                    title: Text(
                      habit["title"] ?? "Untitled",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: habit["completed"] == true
                            ? TextDecoration.lineThrough
                            : null,
                        color: Colors.white, // Always visible on dark mode
                      ),
                    ),
                    subtitle: Text(
                      habit["frequency"] ?? "",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.blueAccent),
                    onLongPress: () =>
                        _openHabitForm(id: id, habit: habit), // ✏️ Quick edit
                  ),
                ),
              );
            },
          );
        },
      ),

      // ➕ Add habit button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openHabitForm(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

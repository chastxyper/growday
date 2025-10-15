import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/habit_service.dart';
import 'habit_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final HabitService _habitService = HabitService();

  CollectionReference<Map<String, dynamic>> get _habitCollection {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("habits");
  }

  // ---------------------- Open Add/Edit Habit Screen ----------------------
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

  // ---------------------- Delete Habit ----------------------
  Future<void> _deleteHabit(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete \"$title\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
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

  // ---------------------- Toggle Complete ----------------------
  Future<void> _toggleComplete(String id, Map<String, dynamic> habit) async {
    await _habitService.toggleComplete(id, habit);
    _showSnack(
      habit["completed"] == true
          ? "Habit marked incomplete"
          : "Habit completed 🎉",
      habit["completed"] == true ? Colors.orange : Colors.green,
    );
  }

  // ---------------------- Show Habit Details ----------------------
  void _showHabitDetails(String id, Map<String, dynamic> habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(habit["title"] ?? "Habit Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (habit["description"] != null && habit["description"] != "")
              Text(habit["description"]),
            const SizedBox(height: 10),
            Text("Frequency: ${habit["frequency"] ?? "N/A"}"),
            Text("Streak: ${habit["streakCount"] ?? 0} 🔥"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
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

  // ---------------------- Logout ----------------------
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ---------------------- Snackbar ----------------------
  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GrowDay",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? "User"),
              accountEmail: Text(user?.email ?? "No email"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
              ),
              decoration: const BoxDecoration(color: Colors.deepPurple),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _habitCollection
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading habits"));
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
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

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
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _toggleComplete(id, habit); // Swipe right → complete
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    await _deleteHabit(
                      id,
                      habit["title"] ?? "",
                    ); // Swipe left → delete
                    return false;
                  }
                  return false;
                },
                child: Card(
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
                        color: habit["completed"] == true
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      habit["frequency"] ?? "",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _openHabitForm(id: id, habit: habit),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openHabitForm(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

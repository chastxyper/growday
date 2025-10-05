import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/habit_service.dart';

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

  // ---------------------- Habit Form ----------------------
  Future<void> _openHabitForm({String? id, Map<String, dynamic>? habit}) async {
    final _formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: habit?["title"] ?? "");
    final descriptionController = TextEditingController(
      text: habit?["description"] ?? "",
    );
    final frequencyController = TextEditingController(
      text: habit?["frequency"] ?? "",
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(id == null ? "Add Habit" : "Edit Habit")),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Habit Title",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter a title" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: frequencyController,
                    decoration: const InputDecoration(
                      labelText: "Frequency (e.g. Daily, Weekly)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final habitData = {
                          "title": titleController.text.trim(),
                          "description": descriptionController.text.trim(),
                          "frequency": frequencyController.text.trim(),
                        };

                        if (id == null) {
                          await _habitService.addHabit(habitData);
                          _showSnack("Habit added successfully", Colors.green);
                        } else {
                          await _habitService.updateHabit(id, habitData);
                          _showSnack("Habit updated successfully", Colors.blue);
                        }

                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      id == null ? "Save Habit" : "Update Habit",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          "My Habits",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
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

              return Card(
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit["frequency"] ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      if ((habit["streakCount"] ?? 0) > 0)
                        Text(
                          "🔥 Streak: ${habit["streakCount"]}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.deepOrange,
                          ),
                        ),
                      if (habit["createdAt"] != null)
                        Text(
                          "Created: ${habit["createdAt"].toDate().toString().substring(0, 16)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: Icon(
                          habit["completed"] == true
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: habit["completed"] == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                        onPressed: () => _toggleComplete(id, habit),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openHabitForm(id: id, habit: habit),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteHabit(id, habit["title"] ?? ""),
                      ),
                    ],
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: () {},
              tooltip: "Habits",
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {},
              tooltip: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

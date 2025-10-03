import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get _habitCollection {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("habits");
  }

  // ---------------------- Habit Form (Add / Update) ----------------------
  Future<void> _addHabitForm() async => _openHabitForm();

  Future<void> _updateHabitForm(String id, Map<String, dynamic> habit) async =>
      _openHabitForm(id: id, habit: habit);

  Future<void> _openHabitForm({String? id, Map<String, dynamic>? habit}) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController titleController = TextEditingController(
      text: habit?["title"] ?? "",
    );
    final TextEditingController descriptionController = TextEditingController(
      text: habit?["description"] ?? "",
    );
    final TextEditingController frequencyController = TextEditingController(
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
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter a title" : null,
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
                  Center(
                    child: ElevatedButton(
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
                            "createdAt": FieldValue.serverTimestamp(),
                            "completed": false,
                            "completedAt": null,
                          };

                          if (id == null) {
                            await _habitCollection.add(habitData);
                          } else {
                            habitData.remove("createdAt");
                            await _habitCollection.doc(id).update(habitData);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                id == null
                                    ? "Habit added successfully"
                                    : "Habit updated successfully",
                              ),
                              backgroundColor: id == null
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          );

                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        id == null ? "Save Habit" : "Update Habit",
                        style: const TextStyle(fontSize: 16),
                      ),
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
      await _habitCollection.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Habit deleted"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------- Complete / Incomplete ----------------------
  Future<void> _toggleComplete(String id, Map<String, dynamic> habit) async {
    try {
      final isCompleted = habit["completed"] == true;
      await _habitCollection.doc(id).update({
        "completed": !isCompleted,
        "completedAt": !isCompleted ? FieldValue.serverTimestamp() : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted ? "Habit marked incomplete" : "Habit completed 🎉",
          ),
          backgroundColor: isCompleted ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update habit status"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------- Logout ----------------------
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
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
                  subtitle: Text(
                    habit["frequency"] ?? "",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
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
                        onPressed: () => _updateHabitForm(id, habit),
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
        onPressed: _addHabitForm,
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

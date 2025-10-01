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

  // Add Habit Form
  Future<void> _addHabitForm() async {
    await _openHabitForm();
  }

  // Update Habit Form
  Future<void> _updateHabitForm(String id, Map<String, dynamic> habit) async {
    await _openHabitForm(id: id, habit: habit);
  }

  // Reusable form (used by Add and Update)
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final habitData = {
                            "title": titleController.text.trim(),
                            "description": descriptionController.text.trim(),
                            "frequency": frequencyController.text.trim(),
                            "createdAt":
                                FieldValue.serverTimestamp(), // only used when new
                          };

                          if (id == null) {
                            // Add new
                            await _habitCollection.add(habitData);
                          } else {
                            // Update existing
                            habitData.remove("createdAt"); // keep old timestamp
                            await _habitCollection.doc(id).update(habitData);
                          }

                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(id == null ? "Save Habit" : "Update Habit"),
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

  // Delete with confirmation
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
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _habitCollection.doc(id).delete();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Habits"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
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
            return const Center(child: Text("Error loading data"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return const Center(child: Text("No habits yet. Add one!"));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final doc = data[index];
              final habit = doc.data() as Map<String, dynamic>;
              final id = doc.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(habit["title"] ?? "Untitled"),
                  subtitle: Text(habit["frequency"] ?? ""),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.access_time), onPressed: () {}),
            const SizedBox(width: 40), // space for FAB
            IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

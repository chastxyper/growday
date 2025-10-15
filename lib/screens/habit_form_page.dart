import 'package:flutter/material.dart';

class HabitFormPage extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? habit;
  final Future<void> Function(Map<String, dynamic> habitData, {String? id})
  onSave;

  const HabitFormPage({super.key, this.id, this.habit, required this.onSave});

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController frequencyController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.habit?["title"] ?? "");
    descriptionController = TextEditingController(
      text: widget.habit?["description"] ?? "",
    );
    frequencyController = TextEditingController(
      text: widget.habit?["frequency"] ?? "",
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    frequencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.id != null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditing ? "Edit Habit" : "Add Habit",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3949AB),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Habit Title
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: "Habit Title",
                          prefixIcon: const Icon(
                            Icons.title_rounded,
                            color: Color(0xFF5C6BC0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter a title" : null,
                      ),
                      const SizedBox(height: 20),

                      // Description
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: "Description",
                          prefixIcon: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF5C6BC0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Frequency
                      TextFormField(
                        controller: frequencyController,
                        decoration: InputDecoration(
                          labelText: "Frequency (e.g. Daily, Weekly)",
                          prefixIcon: const Icon(
                            Icons.repeat_rounded,
                            color: Color(0xFF5C6BC0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save/Update Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3949AB),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
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
                            await widget.onSave(habitData, id: widget.id);
                            if (mounted) Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          isEditing ? "Update Habit" : "Save Habit",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cancel Button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

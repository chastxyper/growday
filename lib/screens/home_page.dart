import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dummy data for now (we’ll connect Firestore later)
  final List<Map<String, String>> _items = [
    {"id": "1", "title": "First Item"},
    {"id": "2", "title": "Second Item"},
    {"id": "3", "title": "Third Item"},
  ];

  // Placeholder CRUD methods
  void _createItem() {
    setState(() {
      _items.add({
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": "New Item",
      });
    });
  }

  void _updateItem(String id) {
    setState(() {
      final index = _items.indexWhere((item) => item["id"] == id);
      if (index != -1) {
        _items[index]["title"] = "${_items[index]["title"]} (updated)";
      }
    });
  }

  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((item) => item["id"] == id);
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page - CRUD Ready"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(item["title"]!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _updateItem(item["id"]!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteItem(item["id"]!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

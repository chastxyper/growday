// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // only needed if you still navigate manually

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      print(
        '🔓 Attempting signOut for: ${FirebaseAuth.instance.currentUser?.uid}',
      );
      await FirebaseAuth.instance.signOut();
      print(
        '✅ signOut completed. currentUser: ${FirebaseAuth.instance.currentUser}',
      );
      // No manual Navigator.pushReplacement needed; AuthWrapper will show LoginPage.
    } catch (e, st) {
      print('❌ Error during signOut: $e\n$st');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logout failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Habit Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(child: Text('Welcome, ${user?.email ?? 'Guest'}')),
    );
  }
}

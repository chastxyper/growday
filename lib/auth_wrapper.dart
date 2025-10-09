import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'services/habit_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final HabitService _habitService = HabitService();

  Future<void> _refreshHabitsOnLogin() async {
    try {
      await _habitService.refreshHabitsStatus();
    } catch (e) {
      debugPrint("Error refreshing habits: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for Firebase connection
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is signed in
        if (snapshot.hasData) {
          // Refresh habits before showing HomePage
          _refreshHabitsOnLogin();
          return const HomePage();
        }

        // User not signed in
        return const LoginPage();
      },
    );
  }
}

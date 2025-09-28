import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false; // Loading state for signup process

  @override
  void dispose() {
    // Dispose controllers to free memory
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handles user signup with Firebase Authentication and Firestore
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if password and confirm password match
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords don’t match")));
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Create user in Firebase Authentication
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Store extra user info in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCred.user!.uid)
          .set({
            "email": _emailController.text.trim(),
            "createdAt": Timestamp.now(),
          });

      if (!mounted) return;
      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signup successful!")));

      // Go back to previous screen (login page)
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Show Firebase-specific error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Signup failed")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Reset loading state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter an email" : null,
              ),
              const SizedBox(height: 12),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (val) => val != null && val.length < 6
                    ? "Password must be at least 6 characters"
                    : null,
              ),
              const SizedBox(height: 12),

              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Signup button or loading spinner
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signup,
                      child: const Text("Sign Up"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

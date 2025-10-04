import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles user login with email & password.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      setState(() => _isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login error: ${e.code}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handles anonymous login (guest mode).
  Future<void> _loginAsGuest() async {
    try {
      setState(() => _isLoading = true);
      await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guest login successful')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Guest login error: ${e.code}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guest login failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Builds the login page UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // card width
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // vertical center
                crossAxisAlignment: CrossAxisAlignment.stretch, // full width
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter your email" : null,
                  ),
                  const SizedBox(height: 12),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (val) => val == null || val.isEmpty
                        ? "Enter your password"
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Login button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text("Login"),
                        ),
                  const SizedBox(height: 12),

                  // Navigate to signup
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupPage()),
                        );
                      },
                      child: const Text("Don’t have an account? Sign up"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Guest login button
                  OutlinedButton(
                    onPressed: _loginAsGuest,
                    child: const Text("Continue as Guest"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

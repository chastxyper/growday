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
  bool _isPasswordVisible = false; // <— new state for view password toggle

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showAlert(
    String title,
    String message, {
    bool isSuccess = false,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Logged in successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

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

      await _showAlert(
        "Login Successful",
        "Welcome back, $email!",
        isSuccess: true,
      );
      // You can navigate to another screen after login here if needed
    } on FirebaseAuthException catch (e) {
      await _showAlert("Login Failed", e.message ?? "Invalid credentials");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAsGuest() async {
    try {
      setState(() => _isLoading = true);
      await FirebaseAuth.instance.signInAnonymously();
      await _showAlert(
        "Guest Login",
        "You are now signed in as a guest.",
        isSuccess: true,
      );
    } on FirebaseAuthException catch (e) {
      await _showAlert("Guest Login Failed", e.message ?? "Try again later");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Welcome Back 👋",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Login to continue",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? "Enter your email"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Password Field with toggle
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? "Enter your password"
                            : null,
                      ),
                      const SizedBox(height: 24),

                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              onPressed: _login,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Login"),
                            ),
                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        onPressed: _loginAsGuest,
                        icon: const Icon(Icons.person_outline),
                        label: const Text("Continue as Guest"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don’t have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupPage(),
                                ),
                              );
                            },
                            child: const Text("Sign Up"),
                          ),
                        ],
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

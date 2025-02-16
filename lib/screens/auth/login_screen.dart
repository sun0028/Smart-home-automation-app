import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/screens/dashboard.dart'; // Import your dashboard screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool isLoading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => value!.isEmpty ? 'Enter an email' : null,
                        onChanged: (value) {
                          setState(() => email = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) => value!.length < 6 ? 'Enter a valid password' : null,
                        onChanged: (value) {
                          setState(() => password = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              await _auth.signInWithEmailAndPassword(email: email, password: password);

                              // Navigate to the dashboard after successful login
                              // ignore: use_build_context_synchronously
                              if (mounted) { // Check if the widget is still mounted
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              setState(() {
                                error = e.message!;
                                isLoading = false;
                              });
                            }
                          }
                        },
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 12.0),
                      Text(error, style: const TextStyle(color: Colors.red, fontSize: 14.0)),
                      TextButton(
                        onPressed: () {
                          // Navigate to the registration screen
                          Navigator.pushNamed(context, '/register'); // Use named route
                        },
                        child: const Text("Don't have an account? Register"),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
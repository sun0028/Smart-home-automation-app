import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/screens/dashboard.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
                        validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
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
                              UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
                              User? user = userCredential.user;

                              if (user != null) {
                                // Store user data in Firestore
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                  'email': email,
                                  // Add other user data fields as needed
                                });

                                // Navigate to the dashboard after successful registration and Firestore update
                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                  );
                                }
                              }
                            } on FirebaseAuthException catch (e) {
                              setState(() {
                                error = e.message!;
                                isLoading = false;
                              });
                            }
                          }
                        },
                        child: const Text('Register'),
                      ),
                      const SizedBox(height: 12.0),
                      Text(error, style: const TextStyle(color: Colors.red, fontSize: 14.0)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
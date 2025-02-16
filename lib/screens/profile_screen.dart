import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _userEmail = '';
  String _userName = '';
  TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      setState(() {
        _userEmail = _user!.email!;
      });

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'] ?? '';
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _changePassword() async {

    String newPassword = _passwordController.text;

    if (newPassword.length < 6) {
      setState(() {
        _errorMessage = "Password must be at least 6 characters long.";
      });
      return;
    }

    try {
      await _user!.updatePassword(newPassword);
      _passwordController.clear(); // Clear the password field
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully.")));
      setState(() {
        _errorMessage = ""; // Clear any previous error messages
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "An error occurred while updating the password.";
      });
    }
  }

  Future<void> _deleteAccount() async {
    try {
      String userId = _user!.uid;

    // 1. Delete user's devices
    QuerySnapshot devicesSnapshot = await FirebaseFirestore.instance.collection('devices').where('userId', isEqualTo: userId).get();
    for (var doc in devicesSnapshot.docs) {
      await doc.reference.delete();
    }

    // 2. Delete user's groups
    QuerySnapshot groupsSnapshot = await FirebaseFirestore.instance.collection('groups').where('userId', isEqualTo: userId).get();
    for (var doc in groupsSnapshot.docs) {
      await doc.reference.delete();
    }

    // 3. Delete user data from Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();

    // 4. Delete the user account from Firebase Authentication
    await _user!.delete();

    // 5. Navigate back to the login screen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account deleted successfully.")));
    }
  } 
  on FirebaseAuthException catch (e) {
    setState(() {
      _errorMessage = e.message ?? "An error occurred.";
    });
  }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: _user != null
            ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_user!.photoURL ?? 'https://via.placeholder.com/150'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _userName.isNotEmpty ? _userName : "User",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userEmail,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _changePassword,
                      child: const Text('Change Password'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // ... (Dialog code remains the same)
                       showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              await _deleteAccount();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              )
            : const Text('Not logged in.'),
      ),
      bottomNavigationBar: _user != null
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _signOut,
                child: const Text('Log Out'),
              ),
            )
          : null,
    );
  }
}
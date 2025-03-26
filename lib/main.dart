import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/screens/auth/login_screen.dart';
import 'package:my_app/screens/auth/registration_screen.dart';
import 'package:my_app/screens/splash_screen.dart'; // Import the splash screen
import 'screens/dashboard.dart';
import 'screens/device_control_page.dart';
import 'package:my_app/screens/profile_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/', 
      routes: {
        '/': (context) => const SplashScreen(), 
        '/register': (context) => const RegistrationScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/device-control': (context) => const DeviceControlPage(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:my_app/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double opacity = 0.0; // Initial opacity

  @override
  void initState() {
    super.initState();
    _navigateToLogin();

    // Start the animation after a slight delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        opacity = 1.0; // Set opacity to 1.0 to trigger the animation
      });
    });
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36454F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: Image.asset('assets/logo.png'),
            ),
            AnimatedOpacity(
              opacity: opacity, // Use the opacity variable here
              duration: const Duration(seconds: 2),
              curve: Curves.easeIn,
              child: const Text(
                "Smart Home Automation",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
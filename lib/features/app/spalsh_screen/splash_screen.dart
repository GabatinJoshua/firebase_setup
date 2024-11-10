import 'package:flutter/material.dart';

import '../../user_auth/presentation/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child; // This can be null
  const SplashScreen({super.key, this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay navigation by 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              widget.child ??
              LoginPage(), // Default to LoginPage if child is null
        ),
        (route) => false, // Removes all previous routes
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.center,
          // Center content horizontally
          children: [
            // Add the image here
            Image.asset(
              'images/vote.png',
              // Path to your image in the assets folder
              height: 200, // Optional: Set the height of the image
              width: 300, // Optional: Set the width of the image
            ),
            SizedBox(height: 20), // Space between image and text
          ],
        ),
      ),
    );
  }
}

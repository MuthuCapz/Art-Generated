import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'art_generator_screen.dart';
import 'registration_screen.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay content
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Centered content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row with circular image and text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular image
                  ClipOval(
                    child: Image.asset(
                      'assets/images/Genify-Ai.png',
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  // Text next to the image
                  Text(
                    'Genify AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 34),
              // Subtitle text
              Text(
                'Generate stunning AI images effortlessly \n with Genify AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 54),
              // Get started button
              ElevatedButton(
                onPressed: () async {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // User is already signed in, navigate to Main Page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ArtGeneratorScreen()),
                    );
                  } else {
                    // User is not signed in, navigate to Registration Screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegistrationScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Transparent background
                  shadowColor: Colors.transparent, // Remove shadow
                  side: BorderSide(
                    color: Colors.blue, // Stroke color
                    width: 2, // Stroke width
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Get started',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue), // Match text color to outline
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

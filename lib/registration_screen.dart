import 'package:art_generator/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

import 'art_generator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(ArtGeneratorApp());
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing Firebase: $error'),
        ),
      ),
    );
  }
}

class ArtGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return ErrorApp(error: snapshot.error.toString());
          }
          return RegistrationScreen();
        },
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _signOutGoogle(); // Sign out Google on page load
  }

// Method to sign out from Google and Firebase
  Future<void> _signOutGoogle() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google
      await _auth.signOut(); // Sign out from Firebase
    } catch (e) {
      print("Google Sign-Out Error: $e");
    }
  }

  Future<String> generateUserID() async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersRef.get();

    int userCount = querySnapshot.size; // Get current user count

    return 'aiuser${(userCount + 1).toString().padLeft(3, '0')}'; // Ensures aiuser001 is first
  }

  // Method to handle Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String userID = await generateUserID(); // Generate unique user ID
        String formattedDate =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'profile': user.photoURL ?? '',
            'username': user.displayName ?? '',
            'loginDateTime': formattedDate,
            'userID': userID,
            'uid': user.uid,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google Sign-In successful!')));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => ArtGeneratorScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
    }
  }

  // Method to handle regular email/password registration
  Future<void> _registerAccount() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Try to sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If user exists, fetch data from Firestore
      User? user = userCredential.user;
      if (user != null) {
        // Fetch the stored password from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Check if the stored password matches the entered password
        String storedPassword = userDoc['password'];

        if (storedPassword == _passwordController.text.trim()) {
          // Password matches, navigate to the main page
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Login successful!')));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ArtGeneratorScreen()),
          );
        } else {
          // Password doesn't match, show error message
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Incorrect password, please try again.')));
        }
      }
    } catch (e) {
      // If the user does not exist (sign-in failed), create a new account
      if (e.toString().contains('user-not-found')) {
        try {
          // Create new user if not found
          UserCredential newUserCredential =
              await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          User? newUser = newUserCredential.user;
          if (newUser != null) {
            // Generate a unique userID and current timestamp
            String userID = await generateUserID();
            String formattedDate =
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

            // Store the new user's details in Firestore (including the password for validation)
            await FirebaseFirestore.instance
                .collection('users')
                .doc(newUser.uid)
                .set({
              'email': _emailController.text.trim(),
              'profile': '', // Optional field
              'username': _usernameController.text.trim(),
              'password': _passwordController.text
                  .trim(), // Store password for later validation
              'loginDateTime': formattedDate,
              'userID': userID,
              'uid': newUser.uid,
            });

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account created successfully!')));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ArtGeneratorScreen()),
            );
          }
        } catch (e) {
          // Handle registration error
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Registration failed: $e')));
        }
      } else {
        // Handle other errors (e.g., incorrect email/password format)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 50),
                  Image.asset(
                    'assets/images/loginn.png',
                    height: 200,
                    width: 200,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Create an account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    controller: _usernameController,
                    hintText: 'Username',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      } else if (value.length > 25) {
                        return 'Username must be at most 25 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    icon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      } else if (!RegExp(r'^[\w-]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email (e.g., abc@gmail.com)';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    icon: Icons.lock,
                    isPasswordField: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      } else if (value.length < 6 || value.length > 12) {
                        return 'Password must be 6-12 characters long';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _registerAccount,
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Text(
                        '  Or  ',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Google Sign-In Button
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: Text(
                      'Log In with Google',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black38, width: 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool isPasswordField = false,
    String? Function(String?)? validator,
  }) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(30),
      child: TextFormField(
        controller: controller,
        obscureText: isPasswordField ? !_isPasswordVisible : obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.grey[500]),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.black38, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.black54, width: 1.0),
          ),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
        ),
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}

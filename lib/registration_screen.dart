import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'art_generator_screen.dart';
import 'dart:async';

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
  Timer? _autoSignOutTimer;
  Future<String> generateUserID() async {
    final usersRef = FirebaseFirestore.instance.collection('artgen_users');
    final querySnapshot = await usersRef.get();

    int userCount = querySnapshot.size;

    return 'genArtuser${(userCount + 1).toString().padLeft(3, '0')}';
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
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
        String formattedDate =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('artgen_users').doc(user.uid);
        DocumentSnapshot userDoc = await userDocRef.get();

        if (userDoc.exists) {
          await userDocRef
              .update({'updateDateTime': formattedDate, 'status': 'active'});
        } else {
          String userID = await generateUserID();
          assignFreePlanToUser(user.uid);
          await userDocRef.set({
            'email': user.email,
            'status': 'active',
            'profile': user.photoURL ?? '',
            'username': user.displayName ?? '',
            'createDateTime': formattedDate,
            'updateDateTime': formattedDate,
            'userID': userID,
            'uid': user.uid,
          }, SetOptions(merge: true));
        }

        startInactivityTimer(user.uid);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ArtGeneratorScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> getFreePlan() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentSnapshot freePlanSnapshot = await firestore
        .collection('artgen_subscription_plans')
        .doc('plans')
        .get();

    if (freePlanSnapshot.exists && freePlanSnapshot.data() != null) {
      var data = freePlanSnapshot.data() as Map<String, dynamic>;

      if (data.containsKey('free')) {
        return data['free']; // Get the free plan details
      }
    }

    print("❌ No Free Plan found in Firestore!");
    return null;
  }

  Future<void> assignFreePlanToUser(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    var freePlan = await getFreePlan();

    if (freePlan != null) {
      await firestore.collection('artgen_user_subscriptions').doc(userId).set({
        'plan_id': freePlan['plan_id'],
        'plan_name': freePlan['plan_name'],
        'subscription_id': 'sub_${userId}',
        'imagecount': freePlan['image_count'],
        'credits': freePlan['credits'],
      }, SetOptions(merge: true));

      print("Free Plan assigned to user $userId");
    } else {
      print("Failed to assign Free Plan to user: $userId");
    }
  }

  void startInactivityTimer(String userId) {
    _autoSignOutTimer?.cancel();
    _autoSignOutTimer = Timer(const Duration(days: 30), () async {
      await FirebaseFirestore.instance
          .collection('artgen_users')
          .doc(userId)
          .update({
        'status': 'inactive',
      });
      await FirebaseAuth.instance.signOut();
    });
  }

  void updateActivity(String userId) async {
    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await FirebaseFirestore.instance
        .collection('artgen_users')
        .doc(userId)
        .update({
      'updateDateTime': formattedDate,
      'status': 'active',
    });
    startInactivityTimer(userId);
  }

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      updateActivity(user.uid);
    } else {
      print("No user is signed in.");
    }
  }

  Future<void> _registerAccount() async {
    if (!_formKey.currentState!.validate()) return;

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('artgen_users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;
        String userId = userDoc.id;

        await FirebaseFirestore.instance
            .collection('artgen_users')
            .doc(userId)
            .update({
          'updateDateTime':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'status': 'active'
        });

        await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ArtGeneratorScreen()),
        );
      } else {
        UserCredential newUserCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);

        User? newUser = newUserCredential.user;
        if (newUser != null) {
          String userID = await generateUserID();
          String formattedDate =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          assignFreePlanToUser(newUser.uid);

          await FirebaseFirestore.instance
              .collection('artgen_users')
              .doc(newUser.uid)
              .set({
            'email': email,
            'status': 'active',
            'profile': '',
            'username': _usernameController.text.trim(),
            'password': password,
            'createDateTime': formattedDate,
            'updateDateTime': formattedDate,
            'userID': userID,
            'uid': newUser.uid,
          });
          startInactivityTimer(newUser.uid);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account created successfully!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ArtGeneratorScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                  ElevatedButton.icon(
                    onPressed: () {
                      _signInWithGoogle(context);
                    },
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

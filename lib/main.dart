import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter engine is ready
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(GenifyApp());
}

class GenifyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: SplashScreen(), // Starting point
    );
  }
}

/// **multiple encrypted keys store in Firestore! and decrypt format original key displayed**
/*
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'encryption_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter engine is ready
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SecureFirestoreScreen(),
    );
  }
}

class SecureFirestoreScreen extends StatefulWidget {
  @override
  _SecureFirestoreScreenState createState() => _SecureFirestoreScreenState();
}

class _SecureFirestoreScreenState extends State<SecureFirestoreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  Map<String, String> decryptedKeys = {};

  // Encrypt and store multiple keys in Firestore
  Future<void> _encryptAndStoreKey() async {
    if (_keyController.text.isEmpty || _valueController.text.isEmpty) {
      _showToast("Enter both key name and value");
      return;
    }

    String keyName = _keyController.text.trim();
    String plainTextValue = _valueController.text.trim();
    String encryptedValue = EncryptionHelper.encryptData(plainTextValue);

    try {
      await _firestore.collection('secure').doc('ltVaek1ZaAsbJ8YehI5J').set({
        keyName: encryptedValue,
      }, SetOptions(merge: true));

      _showToast("Key '$keyName' encrypted & saved successfully!");
      _keyController.clear();
      _valueController.clear();
    } catch (e) {
      _showToast("Error saving key: $e");
    }
  }

  // Fetch encrypted keys from Firestore and decrypt them
  Future<void> _fetchAndDecryptKeys() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('secure')
          .doc('ltVaek1ZaAsbJ8YehI5J')
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, String> tempDecryptedKeys = {};

        // ✅ Casting `doc.data()` to a Map
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        data.forEach((key, encryptedValue) {
          if (encryptedValue is String) {
            // ✅ Ensure it's a string before decrypting
            tempDecryptedKeys[key] =
                EncryptionHelper.decryptData(encryptedValue);
          }
        });

        setState(() {
          decryptedKeys = tempDecryptedKeys;
        });
      } else {
        _showToast("No keys found in Firestore.");
      }
    } catch (e) {
      _showToast("Error fetching keys: $e");
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Firestore Encryption/Decryption")),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter Key Name (e.g., key1, key2)",
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter Value to Encrypt",
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: _encryptAndStoreKey,
              child: Text("Encrypt & Save Key"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAndDecryptKeys,
              child: Text("Fetch & Decrypt All Keys"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: decryptedKeys.entries.map((entry) {
                  return ListTile(
                    title: Text("🔑 ${entry.key}"),
                    subtitle: Text("📜 ${entry.value}",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/// *Encrypted key is enter then decrypt format(Original) key is displayed*
/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

import 'encryption_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EncryptionScreen(),
    );
  }
}

class EncryptionScreen extends StatefulWidget {
  @override
  _EncryptionScreenState createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  TextEditingController _encryptedKeyController = TextEditingController();
  String _decryptedKey = "";

  void _decryptKey() {
    String encryptedText = _encryptedKeyController.text.trim();
    if (encryptedText.isNotEmpty) {
      try {
        String decrypted = EncryptionHelper.decryptData(encryptedText);
        setState(() {
          _decryptedKey = decrypted;
        });
      } catch (e) {
        setState(() {
          _decryptedKey = "Invalid Encrypted Key!";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AES Decryption")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _encryptedKeyController,
              decoration: InputDecoration(
                labelText: "Enter Encrypted Key",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _decryptKey,
              child: Text("Decrypt"),
            ),
            SizedBox(height: 20),
            Text(
              "Decrypted Key: $_decryptedKey",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
*/

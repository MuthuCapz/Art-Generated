import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppLifecycleService with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppLifecycleService() {
    WidgetsBinding.instance.addObserver(this);
    _updateUserStatus("active");
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateUserStatus("inactive");
    } else if (state == AppLifecycleState.resumed) {
      _updateUserStatus("active");
    }
  }

  Future<void> _updateUserStatus(String status) async {
    String? uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await _firestore.collection('artgen_users').doc(uid).set(
        {'status': status},
        SetOptions(merge: true),
      );
    }
  }
}

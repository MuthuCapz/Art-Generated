import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

// Initialize local notifications
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Function to check inactive users and update status
Future<void> checkInactiveUsers() async {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? user = auth.currentUser;
  if (user == null) return; // No user is logged in

  DocumentReference userDocRef =
      firestore.collection('artgen_users').doc(user.uid);
  DocumentSnapshot userDoc = await userDocRef.get();

  if (userDoc.exists) {
    String? lastLoginStr = userDoc.get('updateDateTime');
    DateTime lastLogin = lastLoginStr != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').parse(lastLoginStr)
        : DateTime.now();

    int minutesSinceLastLogin = DateTime.now().difference(lastLogin).inDays;

    if (minutesSinceLastLogin > 30) {
      // Mark user as inactive
      await userDocRef.update({'status': 'inactive'});

      // Send a local notification
      showNotification();
    }
  }
}

// Function to show local notification
Future<void> showNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'Inactivity Notification',
    channelDescription: 'Notifies when the user is inactive',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    "We Miss You!", // Title
    "Haven't seen you in a while! Open the app now.", // Message
    platformChannelSpecifics,
  );
}

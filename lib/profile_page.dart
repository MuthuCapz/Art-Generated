import 'package:art_generator/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'SubscriptionPage.dart';

class ProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Profile Information"),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('artgen_users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("User data not found"));
          }

          var userData = snapshot.data!;
          String profileUrl = userData['profile'] ?? '';
          String username = userData['username'] ?? 'No Username';
          String email = userData['email'] ?? 'No Email';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.purple,
                      backgroundImage: profileUrl.isNotEmpty
                          ? NetworkImage(profileUrl)
                          : null,
                      child: profileUrl.isEmpty
                          ? Icon(Icons.person, size: 70, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    username,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      "Email",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      "Username",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      username,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Current Plan",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: _firestore
                                  .collection('artgen_user_subscriptions')
                                  .doc(user?.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return Text(
                                    "Free",
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                }

                                var subscriptionData = snapshot.data!;
                                String planName =
                                    subscriptionData['plan_name'] ?? "Free";

                                return Text(
                                  planName == "Free" ? "Free" : "Paid",
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Divider(color: Colors.grey[300]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Plan Limit",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: _firestore
                                  .collection('artgen_user_subscriptions')
                                  .doc(user?.uid)
                                  .snapshots(),
                              builder: (context, subscriptionSnapshot) {
                                if (subscriptionSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                if (!subscriptionSnapshot.hasData ||
                                    !subscriptionSnapshot.data!.exists) {
                                  return Text(
                                    "5 images",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black),
                                  );
                                }

                                var subscriptionData =
                                    subscriptionSnapshot.data!;
                                String planName =
                                    subscriptionData['plan_name'] ?? 'Free';
                                int imageCount = int.tryParse(
                                        subscriptionData['imagecount']
                                            .toString()) ??
                                    5;

                                if (planName == 'Free') {
                                  return Text(
                                    "$imageCount images",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black),
                                  );
                                }

                                return StreamBuilder<DocumentSnapshot>(
                                  stream: _firestore
                                      .collection('artgen_payments')
                                      .doc(user?.uid)
                                      .snapshots(),
                                  builder: (context, paymentSnapshot) {
                                    if (paymentSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }

                                    if (!paymentSnapshot.hasData ||
                                        !paymentSnapshot.data!.exists) {
                                      return Text(
                                        "5 images",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      );
                                    }

                                    var paymentData = paymentSnapshot.data!;
                                    String paymentResult =
                                        paymentData['payment_result'] ??
                                            'failure';

                                    if (paymentResult == 'success') {
                                      return Text(
                                        "$imageCount images",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      );
                                    } else {
                                      return Text(
                                        "5 images",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Prompts Remaining",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: _firestore
                                  .collection('artgen_user_subscriptions')
                                  .doc(user?.uid)
                                  .snapshots(),
                              builder: (context, subscriptionSnapshot) {
                                if (subscriptionSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                if (!subscriptionSnapshot.hasData ||
                                    !subscriptionSnapshot.data!.exists) {
                                  return upgradeNowText(context);
                                }

                                var subscriptionData =
                                    subscriptionSnapshot.data!.data()
                                            as Map<String, dynamic>? ??
                                        {};
                                String planName =
                                    subscriptionData['plan_name'] ?? 'Free';
                                int imageCount = int.tryParse(
                                        subscriptionData['imagecount']
                                                ?.toString() ??
                                            "5") ??
                                    5;
                                int balanceImage = subscriptionData
                                        .containsKey('balance_image')
                                    ? int.tryParse(
                                            subscriptionData['balance_image']
                                                .toString()) ??
                                        imageCount
                                    : imageCount;

                                if (planName == 'Free') {
                                  return displayBalanceOrUpgrade(
                                      context, balanceImage, imageCount);
                                }

                                return StreamBuilder<DocumentSnapshot>(
                                  stream: _firestore
                                      .collection('artgen_payments')
                                      .doc(user?.uid)
                                      .snapshots(),
                                  builder: (context, paymentSnapshot) {
                                    if (paymentSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }

                                    if (!paymentSnapshot.hasData ||
                                        !paymentSnapshot.data!.exists) {
                                      return upgradeNowText(context);
                                    }

                                    var paymentData = paymentSnapshot.data!;
                                    String paymentResult =
                                        paymentData['payment_result'] ??
                                            'failure';

                                    if (paymentResult == 'success') {
                                      return displayBalanceOrUpgrade(
                                          context, balanceImage, imageCount);
                                    } else {
                                      return upgradeNowText(context);
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SubscriptionPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 5,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.pink],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Container(
                          constraints: BoxConstraints(minHeight: 50),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/crown.png',
                                width: 23,
                                height: 23,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Upgrade Plan",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            backgroundColor: Colors.white,
                            title: Text("Logout",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Text(
                              "Are you sure you want to logout?",
                              style: TextStyle(fontSize: 18),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("No",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _auth.signOut();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SplashScreen()),
                                    (route) => false,
                                  );
                                },
                                child: Text("Yes",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.green[900])),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.logout, color: Colors.white),
                    label:
                        Text("Logout", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget displayBalanceOrUpgrade(
      BuildContext context, int balanceImage, int imageCount) {
    if (balanceImage <= 0) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SubscriptionPage()),
          );
        },
        child: Text(
          "$imageCount/$imageCount Upgrade Now",
          style: TextStyle(
              fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Text(
      "$balanceImage image${balanceImage > 1 ? 's' : ''}",
      style: TextStyle(fontSize: 14, color: Colors.black),
    );
  }

  Widget upgradeNowText(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubscriptionPage()),
        );
      },
      child: Text(
        "Upgrade Now...",
        style: TextStyle(
            fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'art_generator_screen.dart';
import 'encryption_helper.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String selectedPlan = 'yearly'; // Default selected plan
  Razorpay? _razorpay;
  String razorpayKey = ''; // Store decrypted Razorpay Key

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    fetchRazorpayKey().then((_) {
      print("Razorpay key fetched: $razorpayKey"); // Debugging
    });
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> fetchRazorpayKey() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('secure')
          .doc('ltVaek1ZaAsbJ8YehI5J')
          .get();

      if (doc.exists) {
        String encryptedKey = doc['key1']; // Fetch encrypted key from Firestore
        String decryptedKey =
            EncryptionHelper.decryptData(encryptedKey); // Decrypt it

        setState(() {
          razorpayKey = decryptedKey;
        });
      } else {
        print("No Razorpay key found.");
      }
    } catch (e) {
      print("Error fetching Razorpay key: $e");
    }
  }

  void startPayment() {
    if (razorpayKey.isEmpty) {
      print("Razorpay key is empty, cannot proceed with payment.");
      return;
    }

    print("Using Razorpay Key: $razorpayKey"); // Debugging purpose

    var options = {
      'key': razorpayKey, // Use the decrypted Razorpay key
      'amount': getAmount(selectedPlan), // Convert amount to paisa
      'name': 'Genify AI',
      'description': 'Subscription Plan',
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      print("Error starting payment: $e");
    }
  }

  /// **Handle Successful Payment**
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("Payment Successful: ${response.paymentId}");
    saveSubscriptionPlan("success"); // Save the subscription to Firestore
  }

  /// **Handle Payment Failure**
  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Failed: ${response.message}");
    saveSubscriptionPlan("failure");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ArtGeneratorScreen()),
    );
  }

  /// **Handle External Wallet Payment**
  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet Used: ${response.walletName}");
  }

  int getAmount(String plan) {
    switch (plan) {
      case 'yearly':
        return 9998 * 100; // Convert dollars to paisa
      case 'quarterly':
        return 2998 * 100;
      case 'monthly':
        return 998 * 100;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          /// **Blurred Full-Screen Background Image**
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Image.asset(
                'assets/images/background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                "Manage Plan",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),

                    /// **Title**
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/Genify-Ai.png',
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Genify AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),

                    /// **Subscription Options**
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSubscriptionOption(
                              title: "\$99.98 / year",
                              subtitle:
                                  "• 100 AI Image Generator calls\n• Billed and recurring yearly\n• Cancel anytime",
                              isSelected: selectedPlan == 'yearly',
                              onTap: () {
                                setState(() {
                                  selectedPlan = 'yearly';
                                });
                              },
                              tag: "You save 20%",
                            ),
                            _buildSubscriptionOption(
                              title: "\$29.98 / 3 months",
                              subtitle:
                                  "• 100 AI Image Generator calls\n• Billed and recurring every 3 months\n• Cancel anytime",
                              isSelected: selectedPlan == 'quarterly',
                              onTap: () {
                                setState(() {
                                  selectedPlan = 'quarterly';
                                });
                              },
                            ),
                            _buildSubscriptionOption(
                              title: "\$9.98 / month",
                              subtitle:
                                  "• 100 AI Image Generator calls\n• Billed and recurring monthly\n• Cancel anytime",
                              isSelected: selectedPlan == 'monthly',
                              onTap: () {
                                setState(() {
                                  selectedPlan = 'monthly';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 50),

                    /// **Continue Button with Firestore Integration**
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomPadding + 16),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (razorpayKey.isEmpty) {
                            await fetchRazorpayKey();
                          }
                          startPayment();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Continue",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// **Firestore Function to Save Subscription Plan**
  void saveSubscriptionPlan(String paymentResult) async {
    User? user = FirebaseAuth.instance.currentUser; // Get Current User
    if (user == null) {
      print("User not logged in");
      return;
    }

    String uid = user.uid; // Get user ID
    Map<String, dynamic> subscriptionData = {};

    // Get current DateTime and format it
    DateTime now = DateTime.now();
    String formattedDateTime =
        DateFormat('MMMM d, y \'at\' h:mm:ss a').format(now);

    // Determine selected plan details
    if (selectedPlan == 'yearly') {
      subscriptionData = {
        "title": "\$99.98 / year",
        "subtitle":
            "• 100 AI Image Generator calls\n• Billed and recurring yearly\n• Cancel anytime",
        "paymentResult": paymentResult, // Store payment result
        "subscriptionDateTime": formattedDateTime,
      };
    } else if (selectedPlan == 'quarterly') {
      subscriptionData = {
        "title": "\$29.98 / 3 months",
        "subtitle":
            "• 100 AI Image Generator calls\n• Billed and recurring every 3 months\n• Cancel anytime",
        "paymentResult": paymentResult, // Store payment result
        "subscriptionDateTime": formattedDateTime,
      };
    } else if (selectedPlan == 'monthly') {
      subscriptionData = {
        "title": "\$9.98 / month",
        "subtitle":
            "• 100 AI Image Generator calls\n• Billed and recurring monthly\n• Cancel anytime",
        "paymentResult": paymentResult, // Store payment result
        "subscriptionDateTime": formattedDateTime,
      };
    }

    try {
      await FirebaseFirestore.instance
          .collection("subscription")
          .doc(uid)
          .set(subscriptionData);

      print("Subscription saved successfully!");
    } catch (e) {
      print("Error saving subscription: $e");
    }
  }

  /// **Widget to Build Subscription Plan Option**
  Widget _buildSubscriptionOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    String? tag,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white.withOpacity(0.9),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tag != null)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Radio(
                value: true,
                groupValue: isSelected,
                onChanged: (value) => onTap(),
                activeColor: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

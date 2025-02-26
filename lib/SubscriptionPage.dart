import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
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
  String? selectedPlanId;
  Razorpay? _razorpay;
  String razorpayKey = '';
  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    fetchHighestPricedPlan();
    fetchRazorpayKey().then((_) {
      print("Razorpay key fetched: $razorpayKey"); // Debugging
    });
  }

  Future<void> fetchHighestPricedPlan() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('artgen_subscription_plans')
          .doc('plans')
          .get();

      if (!snapshot.exists) {
        print("No subscription plans found.");
        return;
      }

      Map<String, dynamic> plansData =
          snapshot.data() as Map<String, dynamic>? ?? {};

      String? highestPricedPlanId;
      double highestPrice = 0.0;

      plansData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          String amountString = value['amount'] ?? '₹0';
          String numericAmount = amountString.replaceAll(RegExp(r'[^\d.]'), '');
          double price = double.tryParse(numericAmount) ?? 0.0;

          if (price > highestPrice) {
            highestPrice = price;
            highestPricedPlanId = value['plan_id'];
          }
        }
      });

      if (highestPricedPlanId != null) {
        setState(() {
          selectedPlanId = highestPricedPlanId;
        });
        print("Default selected plan: $selectedPlanId (₹$highestPrice)");
      }
    } catch (e) {
      print("Error fetching highest-priced plan: $e");
    }
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

  void startPayment() async {
    if (razorpayKey.isEmpty) {
      print("Razorpay key is empty, cannot proceed with payment.");
      return;
    }

    if (selectedPlanId == null) {
      print("No plan selected, cannot proceed with payment.");
      return;
    }

    print("Using Razorpay Key: $razorpayKey");
    print("Selected Plan ID: $selectedPlanId");

    try {
      double amountInRupees = await getAmount(selectedPlanId!);

      if (amountInRupees == 0.0) {
        print("Error: Retrieved amount is 0.0");
        return;
      }

      int amountInPaise = (amountInRupees * 100).toInt();

      print("Amount in Paise: $amountInPaise"); // Debugging

      var options = {
        'key': razorpayKey,
        'amount': amountInPaise, // Razorpay requires amount in paise
        'name': 'Genify AI',
        'description': 'Subscription Plan',
      };

      _razorpay?.open(options);
    } catch (e) {
      print("Error starting payment: $e");
    }
  }

  Future<double> getAmount(String planId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('artgen_subscription_plans')
          .doc('plans')
          .get();

      if (!snapshot.exists) {
        print("Plan data not found.");
        return 0.0;
      }

      Map<String, dynamic> plansData =
          snapshot.data() as Map<String, dynamic>? ?? {};

      // Debugging - Print the retrieved data
      print("Retrieved Plans Data: $plansData");

      // Find the plan within the document
      Map<String, dynamic>? selectedPlan;

      plansData.forEach((key, value) {
        if (value is Map<String, dynamic> && value["plan_id"] == planId) {
          selectedPlan = value;
        }
      });

      if (selectedPlan == null) {
        print("Selected plan ($planId) not found.");
        return 0.0;
      }

      // Debugging - Print the selected plan
      print("Selected Plan Data: $selectedPlan");

      String amountString = selectedPlan?['amount'] ?? '₹0';
      String numericAmount = amountString.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(numericAmount) ?? 0.0;
    } catch (e) {
      print("Error fetching plan amount: $e");
      return 0.0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Plan',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          // Light Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFECF0FF), Color(0xFFD7C3F3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20),
                // App Logo & Title
                CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage('assets/images/Genify-Ai.png'),
                  backgroundColor: Colors.transparent,
                ),
                SizedBox(height: 10),
                Text(
                  "Genify AI",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(height: 20),
                // Fetching Plans
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('artgen_subscription_plans')
                        .doc('plans')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Center(
                            child: Text('No Plans Available',
                                style: TextStyle(color: Colors.black)));
                      }

                      var plansData =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      var plans = plansData.entries.toList();
                      // Sorting Plans by plan_id
                      plans.sort((a, b) => a.key.compareTo(b.key));

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          var plan =
                              plans[index].value as Map<String, dynamic>? ?? {};

                          String planId = plan['plan_id'] ?? 'Unknown';
                          String planName = plan['plan_name'] ?? 'No Name';
                          String amount = plan['amount'] ?? '\₹0';
                          String planDuration =
                              plan['plan_duration'] ?? 'No month';
                          int credits = int.tryParse(
                                  plan['credits']?.toString() ?? '0') ??
                              0;
                          String description =
                              plan['description'] ?? 'No description available';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPlanId = planId;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: selectedPlanId == planId
                                    ? Colors.purpleAccent.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.7),
                                border: Border.all(
                                  color: selectedPlanId == planId
                                      ? Colors.deepPurpleAccent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        planName,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                      if (plan.containsKey('tag') &&
                                          plan['tag'] != null &&
                                          plan['tag'].toString().isNotEmpty)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            plan[
                                                'tag'], // Fetching the tag dynamically
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '$amount / $planDuration',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '$credits Credits',
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 14),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    description,
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Continue Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: GestureDetector(
                    onTap: () async {
                      if (selectedPlanId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Please select a plan"),
                          backgroundColor: Colors.red,
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Selected Plan: $selectedPlanId"),
                          backgroundColor: Colors.green,
                        ));
                      }
                      if (razorpayKey.isEmpty) {
                        await fetchRazorpayKey();
                      }
                      startPayment();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Color(0xFFB37FEB), Color(0xFF8E7CC3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Continue",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void saveSubscriptionPlan(String paymentResult) async {
    if (selectedPlanId == null) {
      print("No plan selected.");
      return;
    }

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot planSnapshot = await FirebaseFirestore.instance
          .collection('artgen_subscription_plans')
          .doc('plans')
          .get();

      if (!planSnapshot.exists) {
        print("Plan document not found in Firestore.");
        return;
      }

      Map<String, dynamic>? plansData =
          planSnapshot.data() as Map<String, dynamic>? ?? {};
      print("Firestore Plans Data: $plansData");

      Map<String, dynamic>? selectedPlan;

      plansData.forEach((category, planDetails) {
        if (planDetails["plan_id"] == selectedPlanId) {
          selectedPlan = planDetails;
        }
      });

      if (selectedPlan == null) {
        print("Selected plan ($selectedPlanId) not found in Firestore.");
        return;
      }

      print("Selected Plan Data: $selectedPlan");

      int credits =
          int.tryParse(selectedPlan?['credits']?.toString() ?? '0') ?? 0;
      int imageCount =
          int.tryParse(selectedPlan?['image_count']?.toString() ?? '0') ?? 0;

      DateTime now = DateTime.now();
      DateTime subscriptionEndDateTime = now.add(Duration(days: 30));

      String formattedSubscriptionDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      String formattedEndDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(subscriptionEndDateTime);
      String formattedPaymentDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      await FirebaseFirestore.instance
          .collection('artgen_user_subscriptions')
          .doc(uid)
          .set({
        "subscription_id": "sub_${uid}",
        "plan_id": selectedPlanId!,
        "plan_name": selectedPlan?['plan_name'],
        "imagecount": imageCount,
        "credits": credits,
        "subscriptionDateTime": formattedSubscriptionDate,
        "subscriptionEndDateTime": formattedEndDate,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('artgen_payments')
          .doc(uid)
          .set({
        "payment_id": "pay_${uid}",
        "payment_result": paymentResult,
        "plan_id": selectedPlanId!,
        "payment_date": formattedPaymentDate,
        "subscriptionDateTime": formattedSubscriptionDate,
        "subscriptionEndDateTime": formattedEndDate,
      }, SetOptions(merge: true));

      print("Subscription & payment data saved successfully.");
    } catch (e) {
      print("Error saving subscription/payment data: $e");
    }
  }
}

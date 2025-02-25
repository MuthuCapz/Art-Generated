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

  void startPayment() async {
    // Make function async
    if (razorpayKey.isEmpty) {
      print("Razorpay key is empty, cannot proceed with payment.");
      return;
    }

    print("Using Razorpay Key: $razorpayKey");

    try {
      dynamic amountResult = await getAmount(selectedPlanId!);
      double amountInRupees =
          (amountResult is int) ? amountResult.toDouble() : amountResult;

      int amountInPaise = (amountInRupees * 100).toInt();

      var options = {
        'key': razorpayKey, // Use the decrypted Razorpay key
        'amount': amountInPaise, // Razorpay requires amount in paise
        'name': 'Genify AI',
        'description': 'Subscription Plan',
      };

      print("Amount in Paise: $amountInPaise");
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

      Map<String, dynamic>? selectedPlan = plansData[planId];

      if (selectedPlan == null) {
        print("Selected plan details not found.");
        return 0.0;
      }

      String amountString = selectedPlan['amount'] ?? '₹0';
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
      appBar: AppBar(
        title: Text('Manage Plan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.purple.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                      style: TextStyle(color: Colors.white)));
            }

            var plansData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
            var plans = plansData.entries.toList();

            return Column(
              children: [
                SizedBox(height: 100),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/Genify-Ai.png'),
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: 10),
                Text(
                  "Genify AI",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      var plan =
                          plans[index].value as Map<String, dynamic>? ?? {};

                      String planId = plan['plan_id'] ?? 'Unknown';
                      String planName = plan['plan_name'] ?? 'No Name';
                      String amount = plan['amount'] ?? '\₹0';
                      String planDuration = plan['plan_duration'] ?? 'No month';
                      int credits =
                          int.tryParse(plan['credits']?.toString() ?? '0') ?? 0;
                      String description =
                          plan['description'] ?? 'No description available';

                      return Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RadioListTile<String>(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(planName,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              if (index == 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text("You save 10%",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$amount / $planDuration',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              SizedBox(height: 4),
                              Text('$credits Credits',
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 12)),
                              SizedBox(height: 4),
                              Text(description,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                          value: planId,
                          groupValue: selectedPlanId,
                          activeColor: Colors.purple,
                          onChanged: (String? value) {
                            setState(() {
                              selectedPlanId = value;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ElevatedButton(
                    onPressed: () async {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text("Continue",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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

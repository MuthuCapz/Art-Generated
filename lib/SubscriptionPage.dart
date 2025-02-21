import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String? selectedPlanId;

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
                      String amount = plan['amount'] ?? '\$0';
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
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
                    },
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
}

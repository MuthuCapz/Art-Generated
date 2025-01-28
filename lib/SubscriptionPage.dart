import 'package:flutter/material.dart';
import 'dart:ui';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String selectedPlan = 'yearly'; // Default selected plan

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

                    /// **Continue Button with Dynamic Padding**
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomPadding + 16),
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle continue action
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

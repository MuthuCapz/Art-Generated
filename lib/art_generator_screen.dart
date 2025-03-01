import 'package:art_generator/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'SubscriptionPage.dart';
import 'encryption_helper.dart';

void main() => runApp(ArtGeneratorApp());

class ArtGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ArtGeneratorScreen(),
    );
  }
}

class ArtGeneratorScreen extends StatefulWidget {
  const ArtGeneratorScreen({super.key});

  @override
  _ArtGeneratorScreenState createState() => _ArtGeneratorScreenState();
}

class _ArtGeneratorScreenState extends State<ArtGeneratorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  int remainingCredits = 0;
  String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  String selectedAspectRatio = 'square';
  String? _generatedImageUrl;
  bool _isLoading = false;
  String? _apiKey;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    fetchInitialCredits();
    _fetchApiKey();
  }

  void fetchInitialCredits() {
    if (uid.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('artgen_user_subscriptions')
          .doc(uid)
          .snapshots()
          .listen((DocumentSnapshot subscriptionSnapshot) {
        if (subscriptionSnapshot.exists) {
          Map<String, dynamic> data =
              subscriptionSnapshot.data() as Map<String, dynamic>;

          String planName =
              data.containsKey('plan_name') ? data['plan_name'] : 'Free';

          if (planName == 'Free') {
            updateCredits(data);
          } else {
            FirebaseFirestore.instance
                .collection('artgen_payments')
                .doc(uid)
                .snapshots()
                .listen((DocumentSnapshot paymentSnapshot) {
              if (paymentSnapshot.exists) {
                Map<String, dynamic> paymentData =
                    paymentSnapshot.data() as Map<String, dynamic>;
                String paymentResult = paymentData.containsKey('payment_result')
                    ? paymentData['payment_result']
                    : 'failure';

                if (paymentResult == 'success') {
                  updateCredits(data);
                } else {
                  setState(() {
                    remainingCredits = 0;
                  });
                }
              } else {
                setState(() {
                  remainingCredits = 0;
                });
              }
            });
          }
        } else {
          setState(() {
            remainingCredits = 0;
          });
        }
      }, onError: (error) {
        print("Error fetching real-time credits: $error");
      });
    }
  }

  void updateCredits(Map<String, dynamic> data) {
    int fetchedCredits = 0;
    if (data.containsKey('balance_credits')) {
      fetchedCredits = int.tryParse(data['balance_credits'].toString()) ?? 0;
    } else if (data.containsKey('credits')) {
      fetchedCredits = int.tryParse(data['credits'].toString()) ?? 0;
    }

    setState(() {
      remainingCredits = fetchedCredits;
    });
  }

  Future<void> _fetchApiKey() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('secure')
          .doc('ltVaek1ZaAsbJ8YehI5J')
          .get();

      if (doc.exists) {
        String encryptedKey = doc['key'];
        String decryptedKey =
            EncryptionHelper.decryptData(encryptedKey); // Decrypt it

        setState(() {
          _apiKey = decryptedKey;
        });
      } else {
        showToast("API key not found in Firestore.");
      }
    } catch (e) {
      showToast("Error fetching API key: $e");
    }
  }

  Map<String, String> aspectRatioValues = {
    'square': '1:1',
    'portrait': '9:16',
    'landscape': '16:9',
  };

  bool isValidPrompt(String prompt) {
    return prompt.trim().length <= 500;
  }

  String selectedStyle = 'Cute Creature Generator';

  List<String> styles = [
    'Cute Creature Generator',
    'Anime Portrait Generator',
    'Old Drawing Generator',
    'Abstract Painting Generator',
    '3d Objects Generator',
    'AI Logo Generator',
  ];
  Map<String, String> styleImages = {
    'Cute Creature Generator': 'assets/images/cute.png',
    'Anime Portrait Generator': 'assets/images/anime.png',
    'Old Drawing Generator': 'assets/images/oldart.png',
    'Abstract Painting Generator': 'assets/images/painting.png',
    '3d Objects Generator': 'assets/images/threedart.png',
    'AI Logo Generator': 'assets/images/ailogo.png',
  };

  Widget buildStyleButton(String styleName) {
    bool isSelected = selectedStyle == styleName;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStyle = styleName;
        });
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.2)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                styleImages[styleName]!,
                width: 120,
                height: 104,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 4),
            Text(styleName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isSelected ? Colors.deepPurple : Colors.black)),
          ],
        ),
      ),
    );
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Widget buildAspectRatioButton(String ratioName, String ratioValue) {
    bool isSelected = selectedAspectRatio == ratioName;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAspectRatio = ratioName;
        });
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.2)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _getAspectRatio(ratioValue),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[400]!),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(ratioName.toUpperCase(),
                style: TextStyle(
                    color: isSelected ? Colors.deepPurple : Colors.black)),
            Text("(${ratioValue})",
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  double _getAspectRatio(String ratio) {
    List<String> parts = ratio.split(':');
    double width = double.parse(parts[0]);
    double height = double.parse(parts[1]);
    return width / height;
  }

  Future<void> _saveImage() async {
    if (_generatedImageUrl == null) {
      showToast("No image to save.");
      return;
    }
    showToast("Image saved to gallery.");
    try {
      final response = await http.get(Uri.parse(_generatedImageUrl!));
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = File('${directory.path}/generated_image.png');
      imagePath.writeAsBytesSync(response.bodyBytes);

      final result = await ImageGallerySaver.saveFile(imagePath.path);

      if (result != null && result['isSuccess']) {
      } else {
        showToast("Failed to save image.");
      }
    } catch (e) {
      showToast("Error saving image: $e");
    }
  }

  Future<void> _shareImage() async {
    if (_generatedImageUrl == null) {
      showToast("No image to share.");
      return;
    }

    try {
      final response = await http.get(Uri.parse(_generatedImageUrl!));

      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/shared_image.png');

      imagePath.writeAsBytesSync(response.bodyBytes);

      await Share.shareXFiles([XFile(imagePath.path)],
          text: 'Check out this AI-generated art!');
    } catch (e) {
      showToast("Error sharing image: $e");
    }
  }

  Future<void> _onGenerateButtonPressed() async {
    final prompt = _textController.text.trim();
    if (isValidPrompt(prompt)) {
      _focusNode.unfocus();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });

      await _checkImageCountAndGenerate(prompt, selectedAspectRatio);
    } else {
      showToast("Input should be 500 characters or less");
    }
  }

  Future<void> _checkImageCountAndGenerate(
      String prompt, String aspectRatioName) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showToast("User not logged in.");
        return;
      }

      DocumentReference userDocRef =
          _firestore.collection('artgen_user_subscriptions').doc(user.uid);
      DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        showToast("User subscription data not found. Please subscribe.");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String planName = userData['plan_name'] ?? "Free";
      int imageCount = int.tryParse(userData['imagecount'].toString()) ?? 5;

      int balanceImage = userData.containsKey('balance_image')
          ? int.tryParse(userData['balance_image'].toString()) ?? imageCount
          : imageCount;

      if (planName == "Free") {
        if (!userData.containsKey('balance_image')) {
          balanceImage = imageCount - 1;
          await userDocRef.update({'balance_image': balanceImage});
        } else {
          balanceImage -= 1; // Decrease by 1 each time
          await userDocRef.update({'balance_image': balanceImage});
        }

        if (balanceImage >= 0) {
          await generateArt(prompt, aspectRatioName);
        } else {
          _showSubscriptionPrompt();
        }
      } else {
        DocumentSnapshot paymentDoc =
            await _firestore.collection('artgen_payments').doc(user.uid).get();

        if (!paymentDoc.exists ||
            paymentDoc.get('payment_result') != "success") {
          _showSubscriptionPrompt();
          return;
        }

        if (!userData.containsKey('balance_image')) {
          balanceImage = imageCount - 1;
          await userDocRef.update({'balance_image': balanceImage});
        } else {
          balanceImage -= 1;
          await userDocRef.update({'balance_image': balanceImage});
        }

        if (balanceImage >= 0) {
          await generateArt(prompt, aspectRatioName);
        } else {
          _showSubscriptionPrompt();
          return;
        }
      }

      int credits = int.tryParse(userData['credits'].toString()) ?? 25;

      int balanceCredits = userData.containsKey('balance_credits')
          ? int.tryParse(userData['balance_credits'].toString()) ?? credits
          : credits;

      DocumentSnapshot planDoc = await _firestore
          .collection('artgen_subscription_plans')
          .doc('plans')
          .get();

      int creditsPerImage =
          int.tryParse(planDoc.get('credits_perimage').toString()) ?? 5;

      if (!userData.containsKey('balance_credits')) {
        balanceCredits = credits;
        await userDocRef.update({'balance_credits': balanceCredits});
      }
      if (balanceCredits < creditsPerImage) {
        _showSubscriptionPrompt();
        return;
      }

      balanceCredits -= creditsPerImage;
      await userDocRef.update({'balance_credits': balanceCredits});
    } catch (e) {
      showToast("Error accessing image count: $e");
    }
  }

  Future<void> generateArt(String prompt, String aspectRatioName) async {
    if (_apiKey == null) {
      showToast("API key is not available.");
      return;
    }

    String aspectRatio = aspectRatioValues[aspectRatioName]!;
    setState(() {
      _isLoading = true;
      _generatedImageUrl = null;
    });

    const String apiUrl = 'https://api.deepai.org/api/text2img';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Api-Key': _apiKey!},
        body: {
          'text': prompt,
          'aspect_ratio': aspectRatio,
          'style': selectedStyle,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _generatedImageUrl = data['output_url'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        showToast('Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showToast('Error: $e');
    }
  }

  void _showSubscriptionPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Subscription Required"),
          content: Text(
              "You have reached the free limit or Your payment is failed. Please subscribe to generate more images."),
          actions: [
            TextButton(
              child: Text("Subscribe"),
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionPage()),
                );
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI Image Generator', // Left side text
              style: TextStyle(color: Colors.white),
            ),
            Row(
              children: [
                Text('💰', style: TextStyle(fontSize: 20)),
                // Coin symbol
                SizedBox(width: 3),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                  child: Text(
                    '$remainingCredits',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.normal),
                  ),
                ),

                SizedBox(width: 15),
                IconButton(
                  icon: Icon(Icons.menu, color: Colors.white), // Sidebar icon
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) Center(child: CircularProgressIndicator()),
            Container(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: _generatedImageUrl != null
                    ? AspectRatio(
                        aspectRatio: _getAspectRatio(
                            aspectRatioValues[selectedAspectRatio]!),
                        child: Image.network(
                          _generatedImageUrl!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          },
                        ),
                      )
                    : Image.asset(
                        'assets/images/ai.jpg',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            SizedBox(height: 16),
            if (_generatedImageUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveImage, // Call the save function
                    icon: Icon(Icons.save),
                    label: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _shareImage, // Call the share function
                    icon: Icon(Icons.share),
                    label: Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 8),
            Text(
              "Enter image description",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              "Note: The more detailed the description, the more optimal the image creation will be.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              minLines: 5,
              maxLength: 500,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Type your description...",
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20, // Adjust height
                  horizontal: 16, // Adjust horizontal padding
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0), // Rounded corners
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                    color: Colors.deepPurple,
                    width: 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                    color: Colors.red,
                    width: 1.0,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value.length > 500) {
                  _textController.text = value.substring(0, 500);
                  _textController.selection =
                      TextSelection.collapsed(offset: 500);
                  showToast("Maximum character limit reached!");
                }
              },
              onSubmitted: (_) {
                final prompt = _textController.text.trim();
                if (isValidPrompt(prompt)) {
                  _focusNode.unfocus();
                  final aspectRatio = selectedAspectRatio.isNotEmpty
                      ? selectedAspectRatio
                      : '1:1'; // Default to 1:1 if none selected
                  generateArt(prompt, aspectRatio);
                } else {
                  showToast("Input should be 500 characters or less");
                }
              },
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Style',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 images per row
                    crossAxisSpacing: 8.0, // Spacing between columns
                    mainAxisSpacing: 8.0, // Spacing between rows
                    childAspectRatio: 1, // Ensures square images
                  ),
                  itemCount: styles.length > 6
                      ? 6
                      : styles.length, // Ensure only 6 items are displayed
                  itemBuilder: (context, index) {
                    return buildStyleButton(styles[index]);
                  },
                ),
              ],
            ),

            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aspect Ratio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: buildAspectRatioButton('square', '1:1'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: buildAspectRatioButton('portrait', '9:16'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: buildAspectRatioButton('landscape', '16:9'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.clear_all, color: Colors.white),
                    label: Text('Clear all',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      _textController.clear();
                      setState(() {
                        _generatedImageUrl = null;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.image, color: Colors.white),
                    label:
                        Text('Generate', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: _onGenerateButtonPressed,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20), // Reduced spacing
          ],
        ),
      ),
    );
  }
}

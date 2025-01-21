import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  String selectedAspectRatio = 'square';
  String? _generatedImageUrl;
  bool _isLoading = false;

  final String _apiKey = 'ebc8659c-7b7c-4836-9e2f-5b8a10a48116';
  final String _defaultImageUrl = 'https://www.example.com/placeholder.jpg';

  // Default to square
  Map<String, String> aspectRatioValues = {
    'square': '1:1',
    'portrait': '9:16', // Or '3:4' depending on your preference
    'landscape': '16:9',
  };

  bool isValidPrompt(String prompt) {
    return prompt.trim().length <= 500;
  }

  String selectedStyle = 'Cute Creature Generator'; // Default style

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
              borderRadius:
                  BorderRadius.circular(10), // Adjust the radius as needed
              child: Image.asset(
                styleImages[styleName]!,
                width: 120, // Adjust the width to fit your design
                height: 104, // Adjust the height as needed
                fit: BoxFit.cover, // Ensures the image fits well
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

  // Add this function to handle aspect ratio selection

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

      // Create a temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/shared_image.png');

      imagePath.writeAsBytesSync(response.bodyBytes);

      // Share the downloaded image
      await Share.shareXFiles([XFile(imagePath.path)],
          text: 'Check out this AI-generated art!');
    } catch (e) {
      showToast("Error sharing image: $e");
    }
  }

  Future<void> generateArt(String prompt, String aspectRatioName) async {
    String aspectRatio = aspectRatioValues[aspectRatioName]!;
    setState(() {
      _isLoading = true;
      _generatedImageUrl = null;
    });

    const String apiUrl = 'https://api.deepai.org/api/text2img';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Api-Key': _apiKey},
        body: {
          'text': prompt,
          'aspect_ratio': aspectRatio, // Pass the aspect ratio
          'style': selectedStyle, // Pass the selected style (add this)
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${response.statusCode} - ${response.reasonPhrase}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _onGenerateButtonPressed() {
    final prompt = _textController.text.trim();
    if (isValidPrompt(prompt)) {
      // Unfocus the text field
      _focusNode.unfocus();

      // Scroll to the top after the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });

      // Generate the art
      final aspectRatio = selectedAspectRatio.isNotEmpty
          ? selectedAspectRatio
          : '1:1'; // Default to 1:1 if none selected
      generateArt(prompt, aspectRatio);
    } else {
      showToast("Input should be 300 characters or less");
    }
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
        title: Text(
          'Ai Image Generator',
          style: TextStyle(color: Colors.white),
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
                        // Wrap with AspectRatio
                        aspectRatio: _getAspectRatio(aspectRatioValues[
                            selectedAspectRatio]!), // Use selected aspect ratio
                        child: Image.network(
                          _generatedImageUrl!,
                          fit: BoxFit.cover,
                          alignment:
                              Alignment.center, // Important: Use BoxFit.cover
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
            SizedBox(height: 16), // Added spacing between image and buttons
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
                // Soft background color
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
                  shrinkWrap:
                      true, // Ensures GridView doesn't take infinite height
                  physics:
                      NeverScrollableScrollPhysics(), // Disable scrolling inside the GridView
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
                  padding:
                      const EdgeInsets.all(1.0), // Increased padding all around
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.white,
                        border: Border.all(
                            color: Colors.grey[300]!), // Added border
                      ),
                      padding:
                          const EdgeInsets.all(12.0), // Increased inner padding
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.max, // Ensure Row takes full width
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

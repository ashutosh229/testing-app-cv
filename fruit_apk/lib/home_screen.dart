import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fruit_apk/stored_images_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  File? _image;
  bool _isUploading = false;
  bool _isDeleting = false;
  bool _isProcessing = false;
  String? _prediction;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _prediction = null; // Reset prediction when new image is taken
      });
      
      // Automatically process the image when captured
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // First upload the image to get a URL
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      await supabase.storage.from('images').upload(fileName, _image!);
      final imageUrl = supabase.storage.from('images').getPublicUrl(fileName);
      
      // Send the image URL to your ML API endpoint
      final response = await http.post(
        Uri.parse('http://localhost:5000/predict'), // Replace with your API endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'image_url': imageUrl}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _prediction = result['prediction'];
        });
        
        // Store both the image URL and prediction in Supabase
        await supabase.from('image_urls').insert({
          'url': imageUrl,
          'prediction': _prediction,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banana state: $_prediction')),
        );
      } else {
        throw Exception('Failed to process image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      await supabase.storage.from('images').upload(fileName, _image!);

      final imageUrl = supabase.storage.from('images').getPublicUrl(fileName);
      
      // Include prediction if available
      if (_prediction != null) {
        await supabase.from('image_urls').insert({
          'url': imageUrl,
          'prediction': _prediction,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await supabase.from('image_urls').insert({'url': imageUrl});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteImage() async {
    if (_image == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      setState(() {
        _image = null;
        _prediction = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image deleted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed!')),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture & Upload', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.photo_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StoredImagesScreen()),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6B1495), // First color
                Color(0xFF613DC1), // Second color
                Color(0xFF372D68), // Third color
              ],
              begin: Alignment.topLeft, // Start of the gradient
              end: Alignment.bottomRight, // End of the gradient
              stops: [0.0, 0.5, 1.0], // Optional: Define where each color stops
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null) ...[
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _isUploading || _isDeleting || _isProcessing
                        ? Center(child: CircularProgressIndicator())
                        : Image.file(_image!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 10),
                if (_prediction != null)
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Banana state: $_prediction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getPredictionColor(_prediction!),
                      ),
                    ),
                  ),
                SizedBox(height: 20),
              ],
              if (_image == null)
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("Take Picture"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black
                  ),
                ),
              if (_image != null) ...[
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton("Re-click", _pickImage, Colors.white),
                      SizedBox(width: 10),
                      _buildButton(_prediction == null ? "Analyze" : "Upload", 
                                  _prediction == null ? _processImage : _uploadImage, 
                                  Colors.white),
                      SizedBox(width: 10),
                      _buildButton("Delete", _deleteImage, Colors.white),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPredictionColor(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'ripe':
        return Colors.yellow.shade800;
      case 'overripe':
        return Colors.orange;
      case 'decay':
        return Colors.brown;
      default:
        return Colors.black;
    }
  }

  Widget _buildButton(String text, VoidCallback onPressed, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black),
        child: Text(text),
      ),
    );
  }
}
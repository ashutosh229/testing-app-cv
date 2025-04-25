import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fruit_apk/stored_images_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  File? _image;
  bool _isUploading = false;
  bool _isDeleting = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
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
      await supabase.from('image_urls').insert({'url': imageUrl});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image uploaded successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));

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
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image deleted!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed!')));
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Capture & Upload',style: TextStyle(fontWeight: FontWeight.bold),),backgroundColor: Colors.transparent,),
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
                    child: _isUploading || _isDeleting
                        ? Center(child: CircularProgressIndicator())
                        : Image.file(_image!, fit: BoxFit.cover),
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
                      _buildButton("Upload", _uploadImage, Colors.white),
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

  Widget _buildButton(String text, VoidCallback onPressed, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color,foregroundColor: Colors.black),
        child: Text(text),
      ),
    );
  }
}

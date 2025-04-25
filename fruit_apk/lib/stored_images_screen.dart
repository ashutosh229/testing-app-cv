import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoredImagesScreen extends StatefulWidget {
  @override
  _StoredImagesScreenState createState() => _StoredImagesScreenState();
}

class _StoredImagesScreenState extends State<StoredImagesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchImages() async {
    final response = await supabase.from('image_urls').select();
    return response as List<Map<String, dynamic>>;
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final String fileName = Uri.parse(imageUrl).pathSegments.last;

      // Delete from storage
      await supabase.storage.from('images').remove([fileName]);

      // Delete from database
      await supabase.from('image_urls').delete().eq('url', imageUrl);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image deleted successfully!')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete image!')),
      );
    }
  }

  void _showDeleteDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Image"),
          content: Text("Are you sure you want to delete this image?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteImage(imageUrl);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stored Images")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No images captured", style: TextStyle(fontSize: 18)),
            );
          }

          final images = snapshot.data!;

          return GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // Two columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4, // Adjust height-width ratio
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onLongPress: () => _showDeleteDialog(images[index]['url']),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade400),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      images[index]['url'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

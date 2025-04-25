import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoredImagesScreen extends StatefulWidget {
  @override
  _StoredImagesScreenState createState() => _StoredImagesScreenState();
}

class _StoredImagesScreenState extends State<StoredImagesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchImages() async {
    final response = await supabase
        .from('image_urls')
        .select()
        .order('created_at', ascending: false);
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

  Color _getPredictionColor(String? prediction) {
    if (prediction == null) return Colors.grey;
    
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
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stored Images"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6B1495),
                Color(0xFF613DC1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
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
              crossAxisCount: 2, // Two columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 4 / 5, // Adjust height-width ratio
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageData = images[index];
              final prediction = imageData['prediction'] as String?;
              
              return GestureDetector(
                onLongPress: () => _showDeleteDialog(imageData['url']),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade400),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          child: Image.network(
                            imageData['url'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _getPredictionColor(prediction).withOpacity(0.3),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          prediction ?? 'Unknown',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
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
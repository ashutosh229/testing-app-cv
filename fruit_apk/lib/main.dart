import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vayinuekvorftkdrioug.supabase.co', // Replace with your URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZheWludWVrdm9yZnRrZHJpb3VnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4OTYwNDMsImV4cCI6MjA1NjQ3MjA0M30.QrPi2wSgZw5ldprbfqu7Abs-qNA2cCd6nRVthQ_tWKk', // Replace with your key
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase Image Storage',
      home: HomeScreen(),
    );
  }
}

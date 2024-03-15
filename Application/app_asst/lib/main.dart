import 'dart:io';
import 'package:flutter/material.dart';
import 'gallery_page.dart';
import 'camera_page.dart';
import 'record_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spinopelvic Parameters Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 21, 226, 175)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Main Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _buttonPressed() {
    print('Button pressed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 21, 226, 175),
        title: Text(widget.title,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Spinopelvic Parameters Assistant',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            const Text(
              'Please select an option',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const CameraPage()));
              },
              child: Text(
                'Open Camera',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 21, 226, 175),
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 8,
                padding: EdgeInsets.symmetric(
                  horizontal: 82,
                  vertical: 26,
                ),
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const GalleryPage()));
              },
              child: Text(
                'Pick from Gallery',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 21, 226, 175),
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 8,
                padding: EdgeInsets.symmetric(
                  horizontal: 62,
                  vertical: 26,
                ),
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const RecordPage()));
              },
              child: Text(
                'Open Record',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 21, 226, 175),
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 8,
                padding: EdgeInsets.symmetric(
                  horizontal: 85,
                  vertical: 26,
                ),
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                exit(0);
              },
              child: Text(
                'Exit',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 21, 226, 175),
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 8,
                padding: EdgeInsets.symmetric(
                  horizontal: 135,
                  vertical: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

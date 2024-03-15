import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isLoading = false;
  Uint8List? _imageData;
  bool _showCamera = false;
  Map<String, int>? _angleData;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _detailController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller!.initialize().then((_) {
      setState(() {
        _showCamera = true;
      });
    }).catchError((error) {
      print("Camera initialization error: $error");
    });
  }

  Future<void> _takePhotoAndUpload() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      setState(() {
        _isLoading = true;
        _showCamera = false;
      });

      File imageFile = File(image.path);
      var uri = Uri.parse('http://54.254.127.137:5000/process-image');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));

      var response = await request.send();

      if (response.statusCode == 200) {
        final respBytes = await response.stream.toBytes();
        setState(() {
          _imageData = respBytes;
        });
        _fetchAngleData();
      } else {
        print('Failed to upload image');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAngleData() async {
    var uri = Uri.parse('http://54.254.127.137:5000/angle');
    var response = await http.get(uri);

    if (response.statusCode == 200) {
      setState(() {
        _angleData = Map<String, int>.from(json.decode(response.body));
      });
    } else {
      print('Failed to fetch angle data');
    }
  }

  Future<void> _showSaveSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Success'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Data saved successfully.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveEverything() async {
    if (_imageData == null ||
        _angleData == null ||
        _nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _detailController.text.isEmpty) {
      print("Missing data, cannot save.");
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final infoPath = '${directory.path}/info.json';
    final file = File(infoPath);

    Map<String, dynamic> data = {"records": []};

    if (await file.exists()) {
      final contents = await file.readAsString();
      data = json.decode(contents);
    }

    final imagePath = await _saveImageToFileSystem(_imageData!);

    final Map<String, dynamic> newRecord = {
      'name': _nameController.text,
      'detail': _detailController.text,
      'gender': _selectedGender,
      'age': _ageController.text,
      'imagePath': imagePath,
      'angleData': _angleData,
    };

    data['records'].add(newRecord);

    await file.writeAsString(json.encode(data));
    _showSaveSuccessDialog();
    print("Data saved to $infoPath");
  }

  Future<String> _saveImageToFileSystem(Uint8List imageData) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(imageData);
    return filePath;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    _detailController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Capture & Upload Image',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 21, 226, 175),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              CircularProgressIndicator()
            else if (_showCamera && _controller != null)
              CameraPreview(_controller!)
            else if (_imageData != null)
              Image.memory(_imageData!),
            SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Patient HN',
                labelStyle: TextStyle(
                    color: Color.fromARGB(
                        255, 3, 105, 80)), // Customize label color
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 21, 226, 175),
                      width: 2.0), // Customize border when focused
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.0), // Customize border when not focused
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: Icon(Icons.person,
                    color: Color.fromARGB(
                        255, 21, 226, 175)), // Add icon as suffix
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _detailController,
              decoration: InputDecoration(
                labelText: 'Patient Name',
                labelStyle: TextStyle(color: Color.fromARGB(255, 3, 105, 80)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 21, 226, 175), width: 2.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: Icon(Icons.description,
                    color: Color.fromARGB(255, 21, 226, 175)),
              ),
            ),
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Patient Age',
                labelStyle: TextStyle(color: Color.fromARGB(255, 3, 105, 80)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 21, 226, 175),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: Icon(Icons.health_and_safety_rounded,
                    color: Color.fromARGB(255, 21, 226, 175)),
              ),
              keyboardType: TextInputType
                  .number, // Define keyboard type for numeric input
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly, // Allow only digits (numbers)
              ],
            ),
            SizedBox(height: 10),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Patient Gender',
                labelStyle: TextStyle(color: Color.fromARGB(255, 3, 105, 80)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 21, 226, 175), width: 2.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              value: _selectedGender,
              items: _genderOptions
                  .map((gender) => DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
            ),
            SizedBox(height: 10),
            if (_angleData != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text('PT: ${_angleData!['PT'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 20)),
                      Text('  |  SS: ${_angleData!['SS'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 20)),
                      Text('  |  PI: ${_angleData!['PI'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 20)),
                      Text('  |  LL: ${_angleData!['LL'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            // ElevatedButton(
            //   onPressed: (!_isLoading) ? _fetchAngleData : null,
            //   child: const Text('Show Angle', style: TextStyle(fontSize: 18)),
            // ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEverything,
              child: Text('Save', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading
            ? null
            : _showCamera
                ? _takePhotoAndUpload
                : () {
                    if (!_showCamera) _initCamera();
                  },
        tooltip: _showCamera ? 'Capture Image' : 'Open Camera',
        child: Icon(_showCamera ? Icons.camera_alt : Icons.camera_enhance),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: CameraPage(),
  ));
}

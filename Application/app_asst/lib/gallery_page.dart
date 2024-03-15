// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  Uint8List? _imageData;
  bool _isLoading = false;
  bool _imageUploaded = false;
  String? _error;
  Map<String, int>? _angleData;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _detailController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female'];

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _fetchAngleData() async {
    if (!_imageUploaded) return;

    setState(() => _isLoading = true);

    final uri = Uri.parse('http://54.254.127.137:5000/angle');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() =>
            _angleData = Map<String, int>.from(json.decode(response.body)));
      } else {
        setState(() => _error = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Failed to fetch angle data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isLoading = true;
      _imageUploaded = false;
    });

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      PlatformFile file = result.files.first;
      Uint8List fileBytes = file.bytes ?? await File(file.path!).readAsBytes();
      var uri = Uri.parse('http://54.254.127.137:5000/process-image');

      // Explicitly create a new http client for each upload attempt
      var client = http.Client();
      var request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('file', fileBytes,
            filename: file.name));

      try {
        var response = await client.send(request);
        if (response.statusCode == 200) {
          final respBytes = await response.stream.toBytes();
          setState(() {
            _imageData = respBytes;
            _imageUploaded = true;
            _fetchAngleData();
          });
        } else {
          print('Server error: ${response.statusCode}');
        }
      } catch (e) {
        print('Failed to upload image: $e');
      } finally {
        client.close();
      }
    } else {
      print('No image selected.');
    }

    setState(() => _isLoading = false);
  }

  //show save success dialog
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
      print("Missing data.");
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final infoPath = '${directory.path}/info.json';
    final file = File(infoPath);

    // Initialize an empty map that will contain the "records" list
    Map<String, dynamic> data = {"records": []};

    // If the file exists, read and decode its content into 'data'
    if (await file.exists()) {
      final contents = await file.readAsString();
      data = json.decode(contents);
      if (data['records'] == null) {
        data['records'] = [];
      }
    }

    final imagePath = await _saveImageToFileSystem(_imageData!);

    // Construct the new record
    final Map<String, dynamic> newRecord = {
      'name': _nameController.text,
      'detail': _detailController.text,
      'age': _ageController.text,
      'gender': _selectedGender,
      'imagePath': imagePath,
      'angleData': _angleData,
    };

    // Append the new record to the 'records' list within 'data'
    (data['records'] as List).add(newRecord);

    // Write the updated 'data' map back to info.json
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick & Upload Image',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageData != null) Image.memory(_imageData!),
              if (_isLoading) const CircularProgressIndicator(),
              if (_imageData == null)
                const Text('No image selected.',
                    style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              // TextField(
              //     controller: _nameController,
              //     decoration: const InputDecoration(labelText: 'Patient ID')),
              // const SizedBox(height: 8),
              // TextField(
              //     controller: _detailController,
              //     decoration: const InputDecoration(labelText: 'Patient Name')),
              // const SizedBox(height: 8),
              // TextField(
              //     controller: _ageController,
              //     decoration: const InputDecoration(labelText: 'Patient Age')),
              // const SizedBox(height: 20),

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
              SizedBox(height: 10),
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveEverything,
                child: const Text('Save', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadImage,
        tooltip: 'Pick Image',
        backgroundColor: Color.fromARGB(255, 21, 226, 175),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

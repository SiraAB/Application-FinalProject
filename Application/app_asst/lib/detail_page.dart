import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DetailPage extends StatefulWidget {
  final String? name;
  final String? detail;
  final String? gender;
  final String? age;
  final String? imagePath;
  final Map<String, dynamic>? angleData;
  final VoidCallback onDelete;
  final Function(String?, String?, String?, String?) onUpdate;

  const DetailPage({
    Key? key,
    this.name,
    this.detail,
    this.gender,
    this.age,
    this.imagePath,
    this.angleData,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<bool> imageExistsFuture;

  TextEditingController? nameController;
  TextEditingController? detailController;
  TextEditingController? genderController;
  TextEditingController? ageController;

  @override
  void initState() {
    super.initState();
    imageExistsFuture = _checkImageFileExists(widget.imagePath);

    nameController = TextEditingController(text: widget.name ?? "");
    detailController = TextEditingController(text: widget.detail ?? "");
    genderController = TextEditingController(text: widget.gender ?? "");
    ageController = TextEditingController(text: widget.age ?? "");
  }

  @override
  void dispose() {
    nameController?.dispose();
    detailController?.dispose();
    genderController?.dispose();
    ageController?.dispose();
    super.dispose();
  }

  Future<void> _updateAndSaveDetails() async {
    final directory = await getApplicationDocumentsDirectory();
    final infoPath = '${directory.path}/info.json';
    final file = File(infoPath);

    if (await file.exists()) {
      final contents = await file.readAsString();
      final Map<String, dynamic> decodedJson = json.decode(contents);

      // Access the 'records' array within the decoded JSON object
      List<dynamic> data = decodedJson['records'];

      // Now 'data' is a List<dynamic> containing your records
      // Proceed with finding and updating the record as before
      final index =
          data.indexWhere((element) => element['name'] == widget.name);
      if (index != -1) {
        Map<String, dynamic> updatedRecord = {
          'name': nameController?.text,
          'detail': detailController?.text,
          'gender': genderController?.text,
          'age': ageController?.text,
          'imagePath': widget.imagePath,
          'angleData': widget.angleData,
        };
        data[index] = updatedRecord;

        // Update the whole JSON object, not just the 'data' list
        decodedJson['records'] = data;
        await file.writeAsString(json.encode(decodedJson));
        // Optionally, show a success message or navigate back
      }
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

  Future<bool> _checkImageFileExists(String? imagePath) async {
    if (imagePath == null) return false;
    return File(imagePath).exists();
  }

  Map<String, int> convertDynamicToInt(Map<String, dynamic>? dynamicMap) {
    return dynamicMap?.map((key, value) =>
            MapEntry(key, int.tryParse(value.toString()) ?? 0)) ??
        {};
  }

  @override
  Widget build(BuildContext context) {
    final convertedAngleData = convertDynamicToInt(widget.angleData);

    return Scaffold(
      appBar: AppBar(
        title: Text('Patient ID: ${widget.name ?? "N/A"}',
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
              color: Colors.white,
            ),
            onPressed: () {
              _updateAndSaveDetails();
              _showSaveSuccessDialog();
              widget.onUpdate(
                nameController!.text,
                detailController!.text,
                genderController!.text,
                ageController!.text,
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
            onPressed: () {
              widget.onDelete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<bool>(
                future: imageExistsFuture,
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Color.fromARGB(255, 21, 226, 175), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(widget.imagePath!),
                            fit: BoxFit.cover),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("No image available.",
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    );
                  }
                },
              ),
              TextFormField(
                controller: nameController,
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
                controller: detailController,
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
                controller: genderController,
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
                  suffixIcon: Icon(Icons.person,
                      color: Color.fromARGB(255, 21, 226, 175)),
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: 'Patient Age',
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
                  suffixIcon: Icon(Icons.health_and_safety_rounded,
                      color: Color.fromARGB(255, 21, 226, 175)),
                ),
              ),

              SizedBox(height: 10),
              // _buildInfoTile('Patient ID:', widget.name ?? "N/A"),
              // _buildInfoTile('Patient Name:', widget.detail ?? "N/A"),
              // _buildInfoTile('Patient Gender:', widget.gender ?? "N/A"),
              // _buildInfoTile('Patient Age:', widget.age ?? "N/A"),
              _buildInfoTile(
                  'PT:', convertedAngleData['PT']?.toString() ?? "N/A"),
              _buildInfoTile(
                  'SS:', convertedAngleData['SS']?.toString() ?? "N/A"),
              _buildInfoTile(
                  'PI:', convertedAngleData['PI']?.toString() ?? "N/A"),
              _buildInfoTile(
                  'LL:', convertedAngleData['LL']?.toString() ?? "N/A"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 4, 121, 91),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

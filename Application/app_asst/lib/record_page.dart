import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'detail_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<bool> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<void> _loadSavedData() async {
    final directory = await getApplicationDocumentsDirectory();
    final infoPath = '${directory.path}/info.json';
    final File file = File(infoPath);

    if (await file.exists()) {
      final String contents = await file.readAsString();
      final data = json.decode(contents);

      if (data is Map<String, dynamic> && data.containsKey('records')) {
        final List<dynamic> recordsList = data['records'];
        setState(() {
          records = List<Map<String, dynamic>>.from(recordsList);
        });
      } else {
        setState(() => records = []);
      }
    } else {
      setState(() => records = []);
    }
  }

  Map<String, int> convertDynamicToInt(Map<String, dynamic>? dynamicMap) {
    return dynamicMap?.map((key, dynamic value) =>
            MapEntry(key, int.tryParse(value.toString()) ?? 0)) ??
        {};
  }

  String convertRecordsToCsv(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return '';

    final headers = records.first.keys;
    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln(headers.join(',')); // CSV header

    for (final record in records) {
      final row =
          headers.map((header) => record[header]?.toString() ?? '').join(',');
      csvBuffer.writeln(row);
    }

    return csvBuffer.toString();
  }

  Future<void> _exportRecords() async {
    if (await requestPermissions()) {
      final csv = convertRecordsToCsv(records);
      final directory = await getApplicationDocumentsDirectory();
      final csvPath = '${directory.path}/records.csv';
      final file = File(csvPath);
      await file.writeAsString(csv);
      await Share.file(
          'Records', 'records.csv', file.readAsBytesSync(), 'text/csv');
    }
  }

  Future<void> _showSaveSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exporting'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Data exporting as csv. file.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records Page',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                  context: context,
                  delegate:
                      RecordsSearch(records: records, refreshParent: () {}));
            },
          ),
          IconButton(
            icon: Icon(Icons.save_alt, color: Colors.white),
            onPressed: () async {
              await _exportRecords();
              await _showSaveSuccessDialog();
            },
          ),
        ],
        backgroundColor: Color.fromARGB(255, 21, 226, 175),
      ),
      body: records.isEmpty
          ? Center(
              child: Text(
                'No records',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (BuildContext context, int index) {
                final record = records[index];
                final imagePath = record['imagePath'] as String?;
                final name = record['name'] as String? ?? 'Unnamed Record';

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: imagePath != null
                        ? Image.file(
                            File(imagePath),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(width: 50, height: 50),
                    title: Text('Patient ID: $name'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            name: record['name'],
                            detail: record['detail'],
                            gender: record['gender'],
                            age: record['age'],
                            imagePath: record['imagePath'],
                            angleData: convertDynamicToInt(
                                record['angleData'] as Map<String, dynamic>?),
                            onDelete: () async {
                              records.removeAt(index);
                              final directory =
                                  await getApplicationDocumentsDirectory();
                              final infoPath = '${directory.path}/info.json';
                              final file = File(infoPath);
                              await file.writeAsString(
                                  json.encode({'records': records}));
                              setState(() {});
                            },
                            onUpdate: (String? updatedName,
                                String? updatedDetail,
                                String? updatedGender,
                                String? updatedAge) {
                              setState(() {
                                record['name'] = updatedName;
                                record['detail'] = updatedDetail;
                                record['gender'] = updatedGender;
                                record['age'] = updatedAge;
                              });
                            },
                          ),
                        )),
                  ),
                );
              },
            ),
    );
  }
}

class RecordsSearch extends SearchDelegate {
  final List<Map<String, dynamic>> records;
  final Function
      refreshParent; // Hypothetical callback to refresh the parent widget's state

  RecordsSearch({required this.records, required this.refreshParent});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = records.where((record) {
      return record['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final record = suggestions[index];
        final imagePath = record['imagePath'] as String?;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                imagePath != null ? FileImage(File(imagePath)) : null,
            child: imagePath == null
                ? Icon(Icons.person, color: Colors.white)
                : null,
            backgroundColor: Color.fromARGB(255, 21, 226, 175),
          ),
          title: Text('Patient ID: ${record['name']}'),
          subtitle: Text(
              'Patient Name: ${record['detail'] ?? 'No detail available'}'),
          onTap: () async {
            final updated = await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => DetailPage(
                name: record['name'],
                detail: record['detail'],
                gender: record['gender'],
                age: record['age'],
                imagePath: record['imagePath'],
                angleData: record['angleData'],
                onUpdate: (String? updatedName, String? updatedDetail,
                    String? updatedGender, String? updatedAge) {
                  // This example assumes the DetailPage handles the update internally or through a provided function
                },
                onDelete: () async {
                  // This example assumes the DetailPage handles the deletion internally or through a provided function
                },
              ),
            ));

            // If the DetailPage returns 'true', indicating an update or deletion occurred, call the refreshParent callback
            if (updated == true) {
              refreshParent();
            }
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Implement buildResults similar to buildSuggestions or as needed
    return Container();
  }
}

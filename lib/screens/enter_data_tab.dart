import 'package:flutter/material.dart';
import 'dart:io'; // For File operations
import 'dart:convert';
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'package:nfc_app/models/user_details.dart';

class EnterDataTab extends StatefulWidget {
  const EnterDataTab({super.key});

  @override
  State<EnterDataTab> createState() => _EnterDataTabState();
}

class _EnterDataTabState extends State<EnterDataTab> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _sexController.dispose();
    super.dispose();
  }

  Future<void> _saveDetailsToJsonFile(String fileName, String jsonData) async {
    try {
      // 1. Get the application's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      // 2. Write the JSON data to the file
      await file.writeAsString(jsonData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Details saved to ${file.path}')),
        );
      }
      print('JSON file saved to: ${file.path}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
      print('Error saving JSON file: $e');
    }
  }

  void _saveDetails() async {
    // if (_formKey.currentState!.validate()) {
    //   final String fullName = _fullNameController.text;
    //   final String age = _ageController.text;
    //   final String sex = _sexController.text;

    //   print('Saving Details:');
    //   print('Name: $fullName');
    //   print('Email: $age');
    //   print('Notes: $sex');

    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Details Saved Successfully!')),
    //   );

    //   _fullNameController.clear();
    //   _ageController.clear();
    //   _sexController.clear();
    // }
    final String fullName = _fullNameController.text;
    final String age = _ageController.text;
    final String sex = _sexController.text;

    final userDetails = UserDetails(fullName: fullName, age: age, sex: sex);
    final Map<String, dynamic> userDetailsMap = userDetails.toJson();
    final String jsonData = jsonEncode(userDetailsMap);

    print('Generated JSON: $jsonData');

    // Call the function to save the JSON to a file
    await _saveDetailsToJsonFile(
      'user_details.json',
      jsonData,
    ); // You can choose any filename

    // Optionally, you could load it immediately after saving to verify
    // await _loadJsonFromFile('user_details.json');

    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Details saved to internal app storage.')),
    // );

    _fullNameController.clear();
    _ageController.clear();
    _sexController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Enter Your Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter your name';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter your email';
                //   }
                //   if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                //     return 'Please enter a valid email address';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _sexController,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                // maxLines: 3,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveDetails,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Details'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

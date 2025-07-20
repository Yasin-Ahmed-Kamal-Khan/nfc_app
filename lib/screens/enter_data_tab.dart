import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:nfc_app/models/user_details.dart';

class EnterDataTab extends StatefulWidget {
  const EnterDataTab({super.key});

  @override
  State<EnterDataTab> createState() => _EnterDataTabState();
}

class _EnterDataTabState extends State<EnterDataTab> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _pastMedicationsController = TextEditingController();
  final _pastSurgeriesController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _lastSyncController = TextEditingController();
  final _doctorNotesController = TextEditingController();
  final _weightController = TextEditingController();
  final _dependentsController = TextEditingController();

  Gender? _selectedGender;
  String? _selectedBloodType;

  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    _dateOfBirthController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _currentMedicationsController.dispose();
    _pastMedicationsController.dispose();
    _pastSurgeriesController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _emergencyContactController.dispose();
    _lastSyncController.dispose();
    _doctorNotesController.dispose();
    _weightController.dispose();
    _dependentsController.dispose();
    super.dispose();
  }

  Future<void> _saveDetailsToJsonFile(String fileName, String jsonData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Details saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      _dateOfBirthController.text = pickedDate.toIso8601String().substring(0, 10);
    }
  }

  void _saveDetails() async {
    final userDetails = UserDetails(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      idNumber: _idNumberController.text,
      dateOfBirth: DateTime.parse(_dateOfBirthController.text),
      gender: _selectedGender ?? Gender.male,
      bloodType: _selectedBloodType ?? 'Unknown',
      allergies: _allergiesController.text,
      conditions: _conditionsController.text,
      currentMedications: _currentMedicationsController.text,
      pastMedications: _pastMedicationsController.text,
      pastSurgeries: _pastSurgeriesController.text,
      address: _addressController.text,
      phoneNumber: _phoneNumberController.text,
      emergencyContact: _emergencyContactController.text,
      dependents: int.tryParse(_dependentsController.text) ?? 0,
      lastSync: _lastSyncController.text,
      doctorNotes: _doctorNotesController.text,
      weight: double.tryParse(_weightController.text) ?? 0.0,
    );

    final json = jsonEncode(userDetails.toJson());
    await _saveDetailsToJsonFile('user_details.json', json);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Enter Medical Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(labelText: 'ID Number'),
              ),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                items: Gender.values.map((g) {
                  return DropdownMenuItem(
                    value: g,
                    child: Text(g == Gender.male ? 'Male' : 'Female'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                items: _bloodTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedBloodType = val),
                decoration: const InputDecoration(labelText: 'Blood Type'),
              ),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(labelText: 'Allergies'),
              ),
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(labelText: 'Conditions'),
              ),
              TextFormField(
                controller: _currentMedicationsController,
                decoration: const InputDecoration(labelText: 'Current Medications'),
              ),
              TextFormField(
                controller: _pastMedicationsController,
                decoration: const InputDecoration(labelText: 'Past Medications'),
              ),
              TextFormField(
                controller: _pastSurgeriesController,
                decoration: const InputDecoration(labelText: 'Past Surgeries'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(labelText: 'Emergency Contact'),
              ),
              TextFormField(
                controller: _dependentsController,
                decoration: const InputDecoration(labelText: 'Dependents'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _lastSyncController,
                decoration: const InputDecoration(labelText: 'Last Sync Time'),
              ),
              TextFormField(
                controller: _doctorNotesController,
                decoration: const InputDecoration(labelText: 'Doctor Notes'),
                maxLines: 4,
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveDetails,
                icon: const Icon(Icons.save),
                label: const Text('Save Details'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Keep your imports
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nfc_app/models/user_details.dart';

class EnterDataTab extends StatefulWidget {
  const EnterDataTab({super.key});
  @override
  State<EnterDataTab> createState() => _EnterDataTabState();
}

class _EnterDataTabState extends State<EnterDataTab> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  // Add a controller for the file name
  final _fileNameController = TextEditingController();

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
  BloodType? _selectedBloodType;
  GuardianType? _selectedGuardianType;

  final List<BloodType> _bloodTypes = BloodType.values;
  final List<GuardianType> _guardianOptions = GuardianType.values;

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      _dateOfBirthController.text = pickedDate.toIso8601String().substring(
        0,
        10,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Update file name when first or last name changes
    _firstNameController.addListener(_updateFileName);
    _lastNameController.addListener(_updateFileName);
  }

  void _updateFileName() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    String base = '';
    if (first.isNotEmpty || last.isNotEmpty) {
      base = '${first}_${last}'.replaceAll(' ', '_').toLowerCase();
    } else {
      base = 'user_details';
    }
    _fileNameController.text = '$base.json';
  }

  Future<void> _saveDetailsToJsonFile(String fileName, String jsonData) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonData);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Details saved to ${file.path}')));
    }
  }

  void _saveDetails() async {
    final userDetails = UserDetails(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      idNumber: _idNumberController.text,
      dateOfBirth: DateTime.parse(_dateOfBirthController.text),
      gender: _selectedGender ?? Gender.male,
      bloodType: _selectedBloodType ?? BloodType.unknown,
      allergies: _allergiesController.text,
      conditions: _conditionsController.text,
      currentMedications: _currentMedicationsController.text,
      pastMedications: _pastMedicationsController.text,
      pastSurgeries: _pastSurgeriesController.text,
      address: _addressController.text,
      phoneNumber: _phoneNumberController.text,
      emergencyContact: _emergencyContactController.text,
      dependents: _dependentsController.text.isEmpty
          ? 'None'
          : _dependentsController.text,
      dependentOn: _selectedGuardianType ?? GuardianType.none,
      lastSync: _lastSyncController.text,
      doctorNotes: _doctorNotesController.text,
      weight: double.tryParse(_weightController.text) ?? 0.0,
    );

    final json = jsonEncode(userDetails.toJson());
    // Use the file name from the controller
    await _saveDetailsToJsonFile(_fileNameController.text.trim(), json);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_updateFileName);
    _lastNameController.removeListener(_updateFileName);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _fileNameController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Enter Medical Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(labelText: 'ID Number'),
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
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
                items: Gender.values
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<BloodType>(
                value: _selectedBloodType,
                items: _bloodTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toShortString()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedBloodType = val),
                decoration: const InputDecoration(labelText: 'Blood Type'),
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(labelText: 'Conditions'),
              ),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(labelText: 'Allergies'),
              ),
              TextFormField(
                controller: _currentMedicationsController,
                decoration: const InputDecoration(
                  labelText: 'Current Medications',
                ),
              ),
              TextFormField(
                controller: _pastMedicationsController,
                decoration: const InputDecoration(
                  labelText: 'Past Medications',
                ),
              ),
              TextFormField(
                controller: _pastSurgeriesController,
                decoration: const InputDecoration(labelText: 'Past Surgeries'),
              ),
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextFormField(
                controller: _dependentsController,
                decoration: const InputDecoration(
                  labelText: 'Dependents (comma-separated or "None")',
                ),
              ),
              DropdownButtonFormField<GuardianType>(
                value: _selectedGuardianType,
                items: _guardianOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGuardianType = val),
                decoration: const InputDecoration(labelText: 'Dependent On'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _doctorNotesController,
                decoration: const InputDecoration(labelText: 'Doctor Notes'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _lastSyncController,
                decoration: const InputDecoration(
                  labelText: 'Last Sync Timestamp',
                ),
              ),
              // Add this field for file name (editable)
              TextFormField(
                controller: _fileNameController,
                decoration: const InputDecoration(
                  labelText: 'File Name',
                  helperText: 'Edit the file name if you want',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'File name is required';
                  }
                  if (!value.trim().endsWith('.json')) {
                    return 'File name must end with .json';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveDetails,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

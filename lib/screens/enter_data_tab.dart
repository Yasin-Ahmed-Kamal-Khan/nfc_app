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
  final _doctorNotesController = TextEditingController();
  final _weightController = TextEditingController();
  final _dependentsController = TextEditingController();

  Gender? _selectedGender;
  BloodType? _selectedBloodType;
  GuardianType? _selectedGuardianType;

  bool _isDisplayMode = false;
  UserDetails? _savedUserDetails;

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _requiredDropdownValidator<T>(T? value) {
    if (value == null) {
      return 'Please select an option';
    }
    return null;
  }

  Future<void> _saveDetailsToJsonFile(String fileName, String jsonData) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Details saved successfully to ${file.path}')),
      );
    }
  }

  void _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      final userDetails = UserDetails(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        dateOfBirth: DateTime.parse(_dateOfBirthController.text),
        gender: _selectedGender!,
        bloodType: _selectedBloodType!,
        allergies: _allergiesController.text.trim().isEmpty
            ? 'None'
            : _allergiesController.text.trim(),
        conditions: _conditionsController.text.trim().isEmpty
            ? 'None'
            : _conditionsController.text.trim(),
        currentMedications: _currentMedicationsController.text.trim(),
        pastMedications: _pastMedicationsController.text.trim(),
        pastSurgeries: _pastSurgeriesController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: int.tryParse(_phoneNumberController.text.trim()) ?? 0,
        emergencyContact:
            int.tryParse(_emergencyContactController.text.trim()) ?? 0,
        dependents: _dependentsController.text.trim().isEmpty
            ? 'None'
            : _dependentsController.text.trim(),
        dependentOn: _selectedGuardianType!,
        lastSync: DateTime.now().toIso8601String(),
        doctorNotes: _doctorNotesController.text.trim(),
        weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      );

      final json = jsonEncode(userDetails.toJson());
      await _saveDetailsToJsonFile('${userDetails.firstName}_${userDetails.lastName}.json', json);

      setState(() {
        _savedUserDetails = userDetails;
        _isDisplayMode = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  Widget _buildInfoCard(String label, String value, {Color? highlightColor}) {
    if (value.isEmpty || value == 'None' || value == '0') {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isDisplayMode = false;
            });
          },
        ),
        title: Text(
          _savedUserDetails?.firstName.toUpperCase() ?? 'MEDICAL ID',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Details',
            onPressed: () {
              setState(() {
                _isDisplayMode = false;
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            "Current Condition / Injury",
            _savedUserDetails!.conditions,
            highlightColor: Colors.red.withOpacity(0.08),
          ),
          _buildInfoCard(
            "Blood Type",
            _savedUserDetails!.bloodType.toShortString(),
          ),
          _buildInfoCard("Allergies", _savedUserDetails!.allergies),
          _buildInfoCard(
            "Current Medications",
            _savedUserDetails!.currentMedications,
          ),
          _buildInfoCard(
            "Emergency Contact",
            _savedUserDetails!.emergencyContact.toString(),
          ),
          const SizedBox(height: 20),
          const Divider(),
          _buildInfoCard("First Name", _savedUserDetails!.firstName),
          _buildInfoCard("Last Name", _savedUserDetails!.lastName),
          _buildInfoCard("ID Number", _savedUserDetails!.idNumber),
          _buildInfoCard(
            "Date of Birth",
            _savedUserDetails!.dateOfBirth.toIso8601String().substring(0, 10),
          ),
          _buildInfoCard("Gender", _savedUserDetails!.gender.name),
          _buildInfoCard(
            "Weight",
            "${_savedUserDetails!.weight.toStringAsFixed(1)} kg",
          ),
        ],
      ),
    );
  }

  // --- NEW: This builds the data entry form ---
  Widget _buildFormView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Patient Data Entry',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(labelText: 'ID Number'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name*'),
                validator: _requiredValidator,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name*'),
                validator: _requiredValidator,
              ),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth*',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: _requiredValidator,
              ),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies (enter "None" if unknown)',
                ),
              ),
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(
                  labelText: 'Major Conditions (e.g., Diabetes, Epilepsy)',
                ),
              ),
              DropdownButtonFormField<BloodType>(
                value: _selectedBloodType,
                items: BloodType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toShortString()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedBloodType = val),
                decoration: const InputDecoration(labelText: 'Blood Type*'),
                validator: _requiredDropdownValidator,
              ),
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  final phoneRegExp = RegExp(r'^\+?\d{7,15}$');
                  if (!phoneRegExp.hasMatch(value)) {
                    return 'Enter a valid phone number.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _currentMedicationsController,
                decoration: const InputDecoration(
                  labelText: 'Current Medications (Dosage & Freq)',
                ),
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
              ),
              TextFormField(
                controller: _pastSurgeriesController,
                decoration: const InputDecoration(
                  labelText: 'Past Surgeries / Implants',
                ),
              ),
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                items: Gender.values
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                decoration: const InputDecoration(labelText: 'Gender*'),
                validator: _requiredDropdownValidator,
              ),
              DropdownButtonFormField<GuardianType>(
                value: _selectedGuardianType,
                items: GuardianType.values
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGuardianType = val),
                decoration: const InputDecoration(
                  labelText: 'Dependent On* (e.g., for a child)',
                ),
                validator: _requiredDropdownValidator,
              ),
              TextFormField(
                controller: _dependentsController,
                decoration: const InputDecoration(
                  labelText: 'Names of Dependents (or "None")',
                ),
              ),
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Personal Phone Number',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  final phoneRegExp = RegExp(r'^\+?\d{7,15}$');
                  if (!phoneRegExp.hasMatch(value)) {
                    return 'Enter a valid phone number.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _pastMedicationsController,
                decoration: const InputDecoration(
                  labelText: 'Significant Past Medications',
                ),
              ),
              TextFormField(
                controller: _doctorNotesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Doctor Notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveDetails,
                icon: const Icon(Icons.save_as),
                label: const Text('Save and View Summary'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Added a Scaffold here to provide a consistent background
      body: _isDisplayMode ? _buildDisplayView() : _buildFormView(),
    );
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    _doctorNotesController.dispose();
    _weightController.dispose();
    _dependentsController.dispose();
    super.dispose();
  }
}

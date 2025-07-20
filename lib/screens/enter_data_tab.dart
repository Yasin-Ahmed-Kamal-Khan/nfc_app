import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nfc_app/models/user_details.dart';
import 'package:file_picker/file_picker.dart';

class EnterDataTab extends StatefulWidget {
  const EnterDataTab({super.key});
  @override
  State<EnterDataTab> createState() => _EnterDataTabState();
}

class _EnterDataTabState extends State<EnterDataTab> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  // Controller for the file name (without extension)
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

  @override
  void initState() {
    super.initState();
    // Update file name when first or last name changes
    _firstNameController.addListener(_updateFileName);
    _lastNameController.addListener(_updateFileName);
  }

  Future<void> _showJsonFilePicker() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory
        .listSync()
        .where((e) => e is File && e.path.endsWith('.json'))
        .map((e) => e.path.split(Platform.pathSeparator).last)
        .toList();

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No JSON files found in app directory')),
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select a JSON file'),
        children: files
            .map(
              (f) => SimpleDialogOption(
                child: Text(f),
                onPressed: () => Navigator.pop(context, f),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null) {
      await _loadFromJsonFileInAppDir(selected);
    }
  }

  Future<void> _loadFromJsonFileInAppDir(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      final content = await file.readAsString();
      final data = jsonDecode(content);
      final userDetails = UserDetails.fromJson(data);

      setState(() {
        _firstNameController.text = userDetails.firstName;
        _lastNameController.text = userDetails.lastName;
        _idNumberController.text = userDetails.idNumber;
        _dateOfBirthController.text = userDetails.dateOfBirth
            .toIso8601String()
            .substring(0, 10);
        _selectedGender = userDetails.gender;
        _weightController.text = userDetails.weight.toString();
        _conditionsController.text = userDetails.conditions;
        _allergiesController.text = userDetails.allergies;
        _currentMedicationsController.text = userDetails.currentMedications;
        _pastMedicationsController.text = userDetails.pastMedications;
        _pastSurgeriesController.text = userDetails.pastSurgeries;
        _emergencyContactController.text = userDetails.emergencyContact
            .toString();
        _phoneNumberController.text = userDetails.phoneNumber.toString();
        _dependentsController.text = userDetails.dependents;
        _addressController.text = userDetails.address;
        _doctorNotesController.text = userDetails.doctorNotes;
        _fileNameController.text = fileName.replaceAll('.json', '');
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loaded $fileName')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load file: $e')));
    }
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
    _fileNameController.text = base; // No .json extension
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
    if (_formKey.currentState!.validate()) {
      // Only check for gender since other dropdowns are removed
      if (_selectedGender == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a gender')));
        return;
      }

      final userDetails = UserDetails(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        dateOfBirth: DateTime.parse(_dateOfBirthController.text),
        gender: _selectedGender!,
        // Set default values for removed dropdowns
        bloodType: BloodType.unknown,
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
        dependentOn: GuardianType.none, // Set a default value
        lastSync: DateTime.now().toIso8601String(),
        doctorNotes: _doctorNotesController.text.trim(),
        weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      );

      final json = jsonEncode(userDetails.toJson());
      // Always append .json to the file name
      final fileName = '${_fileNameController.text.trim()}.json';
      await _saveDetailsToJsonFile(fileName, json);

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

  // Add this method to load and fill fields from a JSON file
  Future<void> _loadFromJsonFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content);

        // If your UserDetails has a fromJson method, use it:
        final userDetails = UserDetails.fromJson(data);

        setState(() {
          _firstNameController.text = userDetails.firstName;
          _lastNameController.text = userDetails.lastName;
          _idNumberController.text = userDetails.idNumber;
          _dateOfBirthController.text = userDetails.dateOfBirth
              .toIso8601String()
              .substring(0, 10);
          _selectedGender = userDetails.gender;
          _weightController.text = userDetails.weight.toString();
          _conditionsController.text = userDetails.conditions;
          _allergiesController.text = userDetails.allergies;
          _currentMedicationsController.text = userDetails.currentMedications;
          _pastMedicationsController.text = userDetails.pastMedications;
          _pastSurgeriesController.text = userDetails.pastSurgeries;
          _emergencyContactController.text = userDetails.emergencyContact
              .toString();
          _phoneNumberController.text = userDetails.phoneNumber.toString();
          _dependentsController.text = userDetails.dependents;
          _addressController.text = userDetails.address;
          _doctorNotesController.text = userDetails.doctorNotes;
          // Set file name (without .json)
          _fileNameController.text = result.files.single.name.replaceAll(
            '.json',
            '',
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${result.files.single.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load file: $e')));
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

  Widget buildDisplayView(UserDetails? user) {
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
          user?.firstName.toUpperCase() ?? 'MEDICAL ID',
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
            user!.conditions,
            highlightColor: Colors.red.withOpacity(0.08),
          ),
          _buildInfoCard("Blood Type", user!.bloodType.toShortString()),
          _buildInfoCard("Allergies", user!.allergies),
          _buildInfoCard("Current Medications", user!.currentMedications),
          _buildInfoCard(
            "Emergency Contact",
            user!.emergencyContact.toString(),
          ),
          const SizedBox(height: 20),
          const Divider(),
          _buildInfoCard("First Name", user!.firstName),
          _buildInfoCard("Last Name", user!.lastName),
          _buildInfoCard("ID Number", user!.idNumber),
          _buildInfoCard(
            "Date of Birth",
            user!.dateOfBirth.toIso8601String().substring(0, 10),
          ),
          _buildInfoCard("Gender", user!.gender.name),
          _buildInfoCard("Weight", "${user!.weight.toStringAsFixed(1)} kg"),
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
            children: [
              const Text(
                'Enter Medical Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              // Add a button to load a JSON file
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _showJsonFilePicker,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Load/Edit Medical Record'),
                ),
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
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _doctorNotesController,
                decoration: const InputDecoration(labelText: 'Doctor Notes'),
                maxLines: 3,
              ),
              // File name input with fixed .json extension
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fileNameController,
                      decoration: const InputDecoration(
                        labelText: 'Medical Record Name',
                        helperText: 'Enter Name of Medical Record',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'File name is required';
                        }
                        if (value.contains('.')) {
                          return 'Please enter name without extension';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      '.json',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Added a Scaffold here to provide a consistent background
      body: _isDisplayMode
          ? buildDisplayView(_savedUserDetails)
          : _buildFormView(),
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
    _doctorNotesController.dispose();
    _weightController.dispose();
    _dependentsController.dispose();
    super.dispose();
  }
}

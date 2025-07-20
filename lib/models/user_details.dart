import 'dart:convert';

enum Gender { male, female }
enum GuardianType { none, parent, guardian }
enum BloodType {
  unknown,
  A_pos,
  A_neg,
  B_pos,
  B_neg,
  AB_pos,
  AB_neg,
  O_pos,
  O_neg,
}

extension BloodTypeExtension on BloodType {
  String toShortString() {
    switch (this) {
      case BloodType.A_pos: return 'A+';
      case BloodType.A_neg: return 'A-';
      case BloodType.B_pos: return 'B+';
      case BloodType.B_neg: return 'B-';
      case BloodType.AB_pos: return 'AB+';
      case BloodType.AB_neg: return 'AB-';
      case BloodType.O_pos: return 'O+';
      case BloodType.O_neg: return 'O-';
      default: return 'None';
    }
  }

  static BloodType fromString(String value) {
    switch (value) {
      case 'A+': return BloodType.A_pos;
      case 'A-': return BloodType.A_neg;
      case 'B+': return BloodType.B_pos;
      case 'B-': return BloodType.B_neg;
      case 'AB+': return BloodType.AB_pos;
      case 'AB-': return BloodType.AB_neg;
      case 'O+': return BloodType.O_pos;
      case 'O-': return BloodType.O_neg;
      default: return BloodType.unknown;
    }
  }
}

class UserDetails {
  final String firstName;
  final String lastName;
  final String idNumber;
  final DateTime dateOfBirth;
  final Gender gender;
  final BloodType bloodType;
  final String allergies;
  final String conditions;
  final String currentMedications;
  final String pastMedications;
  final String pastSurgeries;
  final String address;
  final String phoneNumber;
  final String emergencyContact;
  final String dependents; // changed from int to string (names or "None")
  final GuardianType dependentOn;
  final String lastSync;
  final String doctorNotes;
  final double weight;

  UserDetails({
    required this.firstName,
    required this.lastName,
    required this.idNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.currentMedications,
    required this.pastMedications,
    required this.pastSurgeries,
    required this.address,
    required this.phoneNumber,
    required this.emergencyContact,
    required this.dependents,
    required this.dependentOn,
    required this.lastSync,
    required this.doctorNotes,
    required this.weight,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      firstName: json['FirstName'] ?? '',
      lastName: json['LastName'] ?? '',
      idNumber: json['IDNumber'] ?? '',
      dateOfBirth: DateTime.tryParse(json['DateOfBirth'] ?? '') ?? DateTime(2000),
      gender: json['Gender'] == 'M' ? Gender.male : Gender.female,
      bloodType: BloodTypeExtension.fromString(json['BloodType'] ?? ''),
      allergies: json['Allergies'] ?? '',
      conditions: json['Conditions'] ?? '',
      currentMedications: json['CurrentMedications'] ?? '',
      pastMedications: json['PastMedications'] ?? '',
      pastSurgeries: json['PastSurgeries'] ?? '',
      address: json['Address'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? '',
      emergencyContact: json['EmergencyContact'] ?? '',
      dependents: json['Dependents'] ?? 'None',
      dependentOn: GuardianType.values.firstWhere(
        (g) => g.name == (json['DependentOn'] ?? 'none'),
        orElse: () => GuardianType.none,
      ),
      lastSync: json['LastSync'] ?? '',
      doctorNotes: json['DoctorNotes'] ?? '',
      weight: double.tryParse(json['Weight'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'IDNumber': idNumber,
      'DateOfBirth': dateOfBirth.toIso8601String().substring(0, 10),
      'Gender': gender == Gender.male ? 'M' : 'F',
      'BloodType': bloodType.toShortString(),
      'Allergies': allergies,
      'Conditions': conditions,
      'CurrentMedications': currentMedications,
      'PastMedications': pastMedications,
      'PastSurgeries': pastSurgeries,
      'Address': address,
      'PhoneNumber': phoneNumber,
      'EmergencyContact': emergencyContact,
      'Dependents': dependents,
      'DependentOn': dependentOn.name,
      'LastSync': lastSync,
      'DoctorNotes': doctorNotes,
      'Weight': weight.toStringAsFixed(1),
    };
  }

  @override
  String toString() {
    return 'UserDetails(firstName: $firstName, lastName: $lastName, idNumber: $idNumber, dateOfBirth: $dateOfBirth, gender: $gender, bloodType: ${bloodType.toShortString()}, allergies: $allergies, conditions: $conditions, currentMedications: $currentMedications, pastMedications: $pastMedications, pastSurgeries: $pastSurgeries, address: $address, phoneNumber: $phoneNumber, emergencyContact: $emergencyContact, dependents: $dependents, dependentOn: $dependentOn, lastSync: $lastSync, doctorNotes: $doctorNotes, weight: $weight)';
  }
}

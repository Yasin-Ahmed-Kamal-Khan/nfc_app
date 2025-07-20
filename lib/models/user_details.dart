import 'dart:convert'; // For jsonEncode and jsonDecode

enum Gender { male, female }
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
      case BloodType.unknown:
        return 'Unknown';
      case BloodType.A_pos:
        return 'A+';
      case BloodType.A_neg:
        return 'A-';
      case BloodType.B_pos:
        return 'B+';
      case BloodType.B_neg:
        return 'B-';
      case BloodType.AB_pos:
        return 'AB+';
      case BloodType.AB_neg:
        return 'AB-';
      case BloodType.O_pos:
        return 'O+';
      case BloodType.O_neg:
        return 'O-';
    }
  }

  static BloodType fromString(String value) {
    switch (value) {
      case 'A+':
        return BloodType.A_pos;
      case 'A-':
        return BloodType.A_neg;
      case 'B+':
        return BloodType.B_pos;
      case 'B-':
        return BloodType.B_neg;
      case 'AB+':
        return BloodType.AB_pos;
      case 'AB-':
        return BloodType.AB_neg;
      case 'O+':
        return BloodType.O_pos;
      case 'O-':
        return BloodType.O_neg;
      default:
        return BloodType.unknown;
    }
  }
}
class UserDetails {
  final String firstName;
  final String lastName;
  final String idNumber;
  final DateTime dateOfBirth;
  final Gender gender;
  final String bloodType;
  final String allergies;
  final String conditions;
  final String currentMedications;
  final String pastMedications;
  final String pastSurgeries;
  final String address;
  final String phoneNumber;
  final String emergencyContact;
  final int dependents;
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
    required this.lastSync,
    required this.doctorNotes,
    required this.weight,
  });
static String safeSubstring(String? input, int maxLength) {
    if (input == null) return '';
    return input.length <= maxLength ? input : input.substring(0, maxLength);
  }

  // Factory constructor to create a UserDetails object from a Map (JSON)
  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      firstName: json['FirstName'].toString().substring(0, 10),
      lastName: json['LastName'].toString().substring(0, 10),
      idNumber: json['IDNumber'].toString().substring(0, 16),
      dateOfBirth: DateTime.parse(json['DateOfBirth']),
      gender: json['Gender'] == 'M' ? Gender.male : Gender.female,
      bloodType: json['BloodType'].toString().substring(0, 3),
      allergies: json['Allergies'].toString().substring(0, 30),
      conditions: json['Conditions'].toString().substring(0, 30),
      currentMedications: json['CurrentMedications'].toString().substring(0, 50),
      pastMedications: json['PastMedications'].toString().substring(0, 50),
      pastSurgeries: json['PastSurgeries'].toString().substring(0, 50),
      address: json['Address'].toString().substring(0, 30),
      phoneNumber: json['PhoneNumber'].toString().substring(0, 15),
      emergencyContact: json['EmergencyContact'].toString().substring(0, 15),
      dependents: int.tryParse(json['Dependents'].toString()) ?? 0,
      lastSync: json['LastSync'].toString().substring(0, 20),
      doctorNotes: json['DoctorNotes'].toString().substring(0, 200),
      weight: double.tryParse(json['Weight'].toString()) ?? 0.0,
    );
  }

  // Method to convert a UserDetails object to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'FirstName': firstName.substring(0, 10),
      'LastName': lastName.substring(0, 10),
      'IDNumber': idNumber.substring(0, 16),
      'DateOfBirth': dateOfBirth.toIso8601String().substring(0, 10),
      'Gender': gender == Gender.male ? 'M' : 'F',
      'BloodType': bloodType.substring(0, 3),
      'Allergies': allergies.substring(0, 30),
      'Conditions': conditions.substring(0, 30),
      'CurrentMedications': currentMedications.substring(0, 50),
      'PastMedications': pastMedications.substring(0, 50),
      'PastSurgeries': pastSurgeries.substring(0, 50),
      'Address': address.substring(0, 30),
      'PhoneNumber': phoneNumber.substring(0, 15),
      'EmergencyContact': emergencyContact.substring(0, 15),
      'Dependents': dependents,
      'LastSync': lastSync.substring(0, 20),
      'DoctorNotes': doctorNotes.substring(0, 200),
      'Weight': weight.toStringAsFixed(1),
    };
  }


 @override
  String toString() {
    return 'UserDetails(firstName: $firstName, lastName: $lastName, idNumber: $idNumber, dateOfBirth: $dateOfBirth, gender: $gender, bloodType: $bloodType, allergies: $allergies, conditions: $conditions, currentMedications: $currentMedications, pastMedications: $pastMedications, pastSurgeries: $pastSurgeries, address: $address, phoneNumber: $phoneNumber, emergencyContact: $emergencyContact, dependents: $dependents, lastSync: $lastSync, doctorNotes: $doctorNotes, weight: $weight)';
  }
}
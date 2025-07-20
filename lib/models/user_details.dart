import 'dart:convert'; // For jsonEncode and jsonDecode

class UserDetails {
  final String fullName;
  final String age;
  final String sex;

  UserDetails({
    required this.fullName,
    required this.age,
    required this.sex,
  });

  // Factory constructor to create a UserDetails object from a Map (JSON)
  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      fullName: json['Full Name'] as String,
      age: json['Age'] as String,
      sex: json['Sex'] as String,
    );
  }

  // Method to convert a UserDetails object to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'Full Name': fullName,
      'Age': age,
      'Sex': sex,
    };
  }

  @override
  String toString() {
    return 'UserDetails(name: $fullName, email: $age, notes: $sex)';
  }
}
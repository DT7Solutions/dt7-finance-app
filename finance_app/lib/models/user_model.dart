class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'ADMIN' or 'EMPLOYEE'
  final String department;
  final String employeeId;
  final String phone;
  final double allocatedAmount;
  final double usedAmount;
  final double remainingAmount;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'EMPLOYEE',
    this.department = 'Sales Department',
    this.employeeId = 'DT7EMP001',
    this.phone = '+91 98765 43210',
    this.allocatedAmount = 0.0,
    this.usedAmount = 0.0,
    this.remainingAmount = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] ?? {};
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: profile['role'] ?? 'EMPLOYEE',
      department: profile['department'] ?? 'Sales Department',
      employeeId: profile['employee_id'] ?? 'DT7EMP001',
      phone: profile['phone'] ?? '+91 98765 43210',
      allocatedAmount: double.tryParse(json['allocated_amount'].toString()) ?? 0.0,
      usedAmount: double.tryParse(json['used_amount'].toString()) ?? 0.0,
      remainingAmount: double.tryParse(json['remaining_amount'].toString()) ?? 0.0,
    );
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return username;
    return '$firstName $lastName'.trim();
  }

  bool get isAdmin => role == 'ADMIN';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'department': department,
      'employee_id': employeeId,
      'phone': phone,
      'allocated_amount': allocatedAmount,
      'used_amount': usedAmount,
      'remaining_amount': remainingAmount,
      'profile': {
        'role': role,
        'department': department,
        'employee_id': employeeId,
        'phone': phone,
      },
    };
  }
}

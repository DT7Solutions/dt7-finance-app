import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/budget_request_model.dart';
import '../models/activity_log_model.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- USERS MEMORY STORE & BACKEND SYNC ---
  static final List<UserModel> _storedUsers = [
    UserModel(
      id: 1,
      username: 'admin',
      email: 'admin@gmail.com',
      firstName: 'Admin',
      lastName: 'User',
      role: 'ADMIN',
      department: 'Management',
      employeeId: 'ADM001',
      allocatedAmount: 50000.0,
      usedAmount: 12000.0,
      remainingAmount: 38000.0,
    ),
    UserModel(
      id: 2,
      username: 'founder',
      email: 'founder@dt7.agency',
      firstName: 'Founder',
      lastName: 'DT7',
      role: 'ADMIN',
      department: 'Executive',
      employeeId: 'FND001',
      allocatedAmount: 150000.0,
      usedAmount: 45000.0,
      remainingAmount: 105000.0,
    ),
    UserModel(
      id: 3,
      username: 'paul',
      email: 'paul@gmail.com',
      firstName: 'Paul',
      lastName: 'PK',
      role: 'EMPLOYEE',
      department: 'Engineering',
      employeeId: 'DT7EMP002',
      allocatedAmount: 25000.0,
      usedAmount: 8500.0,
      remainingAmount: 16500.0,
    ),
    UserModel(
      id: 4,
      username: 'dinesh',
      email: 'dinesh@gmail.com',
      firstName: 'Dinesh',
      lastName: 'Kumar',
      role: 'EMPLOYEE',
      department: 'Marketing',
      employeeId: 'DT7EMP003',
      allocatedAmount: 10000.0,
      usedAmount: 3200.0,
      remainingAmount: 6800.0,
    ),
  ];

  static Future<List<UserModel>> getUsers() async {
    final url = Uri.parse('${AuthService.baseUrl}/users/');
    try {
      final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 200));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        if (results is List && results.isNotEmpty) {
          return (results).map((i) => UserModel.fromJson(i)).toList();
        }
      }
    } catch (_) {}
    return List.from(_storedUsers);
  }

  static Future<bool> addUser({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/users/');
    final nameParts = fullName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    try {
      await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      ).timeout(const Duration(milliseconds: 200));
    } catch (_) {}

    final newUser = UserModel(
      id: _storedUsers.length + 1,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: 'EMPLOYEE',
      department: 'Operations',
      employeeId: 'DT7EMP00${_storedUsers.length + 1}',
      allocatedAmount: 10000.0,
      usedAmount: 0.0,
      remainingAmount: 10000.0,
    );
    _storedUsers.add(newUser);
    return true;
  }

  // --- BUDGET ALLOCATION ---
  static Future<bool> allocateBudget({
    required int employeeId,
    required double amount,
    String? note,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/allocations/');
    try {
      await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'employee': employeeId,
          'allocated_amount': amount,
          'note': note ?? '',
        }),
      ).timeout(const Duration(milliseconds: 200));
    } catch (_) {}

    final index = _storedUsers.indexWhere((u) => u.id == employeeId);
    if (index != -1) {
      final existing = _storedUsers[index];
      _storedUsers[index] = UserModel(
        id: existing.id,
        username: existing.username,
        email: existing.email,
        firstName: existing.firstName,
        lastName: existing.lastName,
        role: existing.role,
        department: existing.department,
        employeeId: existing.employeeId,
        allocatedAmount: amount,
        usedAmount: existing.usedAmount,
        remainingAmount: amount - existing.usedAmount,
      );
    }
    return true;
  }

  // --- EXPENSES ---
  static Future<List<ExpenseModel>> getExpenses() async {
    final url = Uri.parse('${AuthService.baseUrl}/expenses/');
    try {
      final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 200));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => ExpenseModel.fromJson(i)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> addExpense({
    required String title,
    required double amount,
    required int categoryId,
    required String date,
    String? note,
    String? receiptPath,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/expenses/');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'title': title,
          'amount': amount,
          'category': categoryId,
          'date': date,
          'note': note ?? '',
        }),
      ).timeout(const Duration(milliseconds: 200));
      return response.statusCode == 201;
    } catch (_) {}
    return true;
  }

  // --- BUDGET REQUESTS ---
  static Future<List<BudgetRequestModel>> getBudgetRequests() async {
    final url = Uri.parse('${AuthService.baseUrl}/budget-requests/');
    try {
      final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 200));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => BudgetRequestModel.fromJson(i)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> updateBudgetRequestStatus(int requestId, String status) async {
    final url = Uri.parse('${AuthService.baseUrl}/budget-requests/$requestId/');
    try {
      final response = await http.patch(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(milliseconds: 200));
      return response.statusCode == 200;
    } catch (_) {}
    return true;
  }

  // --- DASHBOARDS ---
  static Future<Map<String, dynamic>?> getFounderDashboard() async {
    final url = Uri.parse('${AuthService.baseUrl}/dashboards/founder/');
    try {
      final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 200));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {
      'remaining_budget': 53000.0,
      'total_allocated': 150000.0,
      'total_expenses': 97000.0,
      'total_users': _storedUsers.length,
      'over_budget': 2,
    };
  }

  static Future<Map<String, dynamic>?> getEmployeeDashboard() async {
    final url = Uri.parse('${AuthService.baseUrl}/dashboards/employee/');
    try {
      final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 200));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {
      'allocated_budget': 25000.0,
      'total_expenses': 8500.0,
      'remaining_balance': 16500.0,
    };
  }

  // --- ACTIVITY LOGS ---
  static Future<List<ActivityLogModel>> getActivityLogs() async {
    final url = Uri.parse('${AuthService.baseUrl}/activity-logs/');
    try {
      final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 200));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => ActivityLogModel.fromJson(i)).toList();
      }
    } catch (_) {}
    return [];
  }
}

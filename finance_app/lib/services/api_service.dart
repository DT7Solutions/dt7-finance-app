import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/budget_request_model.dart';
import '../models/activity_log_model.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- USERS ---
  static Future<List<UserModel>> getUsers() async {
    final url = Uri.parse('${AuthService.baseUrl}/users/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => UserModel.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    return [];
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
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding user: $e');
    }
    return false;
  }

  // --- BUDGET ALLOCATION ---
  static Future<bool> allocateBudget({
    required int employeeId,
    required double amount,
    String? note,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/allocations/');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'employee': employeeId,
          'allocated_amount': amount,
          'note': note ?? '',
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error allocating budget: $e');
    }
    return false;
  }

  // --- FOUNDER DASHBOARD ---
  static Future<Map<String, dynamic>?> getFounderDashboard() async {
    final url = Uri.parse('${AuthService.baseUrl}/dashboard/founder/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching founder dashboard: $e');
    }
    return null;
  }

  // --- EXPENSES ---
  static Future<List<ExpenseModel>> getExpenses({int? userId, String? status}) async {
    var uriStr = '${AuthService.baseUrl}/expenses/?';
    if (userId != null) uriStr += 'user=$userId&';
    if (status != null) uriStr += 'status=$status&';

    final url = Uri.parse(uriStr);
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => ExpenseModel.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error fetching expenses: $e');
    }
    return [];
  }

  static Future<ExpenseModel?> createExpense({
    required String title,
    required double amount,
    required int categoryId,
    required String description,
    required String dateTime,
    String paymentMode = 'Cash',
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
          'description': description,
          'date_time': dateTime,
          'payment_mode': paymentMode,
        }),
      );
      if (response.statusCode == 201) {
        return ExpenseModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error creating expense: $e');
    }
    return null;
  }

  static Future<bool> deleteExpense(int id) async {
    final url = Uri.parse('${AuthService.baseUrl}/expenses/$id/');
    try {
      final response = await http.delete(url, headers: await _getHeaders());
      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting expense: $e');
    }
    return false;
  }

  // --- APPROVALS ---
  static Future<bool> submitApprovalAction(int id, String type, String action) async {
    final url = Uri.parse('${AuthService.baseUrl}/approvals/$id/action/');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({'type': type, 'action': action}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error submitting approval action: $e');
    }
    return false;
  }

  // --- BUDGET REQUESTS ---
  static Future<List<BudgetRequestModel>> getBudgetRequests({String? status}) async {
    var uriStr = '${AuthService.baseUrl}/budget-requests/?';
    if (status != null) uriStr += 'status=$status&';

    final url = Uri.parse(uriStr);
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => BudgetRequestModel.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error fetching budget requests: $e');
    }
    return [];
  }

  static Future<bool> submitBudgetRequest({
    required double amount,
    required int categoryId,
    required String reason,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/budget-requests/');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'request_amount': amount,
          'category': categoryId,
          'reason': reason,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error submitting budget request: $e');
    }
    return false;
  }

  // --- CATEGORIES ---
  static Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('${AuthService.baseUrl}/categories/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => CategoryModel.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    return [];
  }

  // --- REPORTS ---
  static Future<Map<String, dynamic>?> getReports() async {
    final url = Uri.parse('${AuthService.baseUrl}/reports/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching reports: $e');
    }
    return null;
  }

  // --- ACTIVITY LOGS ---
  static Future<List<ActivityLogModel>> getActivityLogs() async {
    final url = Uri.parse('${AuthService.baseUrl}/activity-logs/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => ActivityLogModel.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error fetching activity logs: $e');
    }
    return [];
  }

  // --- ACCOUNTS ---
  static Future<List<AccountModel>> getAccounts() async {
    final url = Uri.parse('${AuthService.baseUrl}/accounts/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => AccountModel.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error fetching accounts: $e');
    }
    return [];
  }

  static Future<bool> createAccount({
    required String name,
    required String accountType,
    required double balance,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/accounts/');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'account_type': accountType,
          'balance': balance,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating account: $e');
    }
    return false;
  }

  // --- TRANSACTIONS ---
  static Future<List<TransactionModel>> getTransactions({int? accountId, String? type, String? transactionType}) async {
    var uriStr = '${AuthService.baseUrl}/transactions/?';
    if (accountId != null) uriStr += 'account=$accountId&';
    final t = type ?? transactionType;
    if (t != null) uriStr += 'transaction_type=$t&';

    final url = Uri.parse(uriStr);
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => TransactionModel.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    }
    return [];
  }

  static Future<TransactionModel?> createTransaction({
    required int accountId,
    required int categoryId,
    required String title,
    required double amount,
    required String transactionType,
    String? date,
    String? notes,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/transactions/');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'account': accountId,
          'category': categoryId,
          'title': title,
          'amount': amount,
          'transaction_type': transactionType,
          if (date != null) 'date': date,
          if (notes != null) 'notes': notes,
        }),
      );
      if (response.statusCode == 201) {
        return TransactionModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error creating transaction: $e');
    }
    return null;
  }

  // --- ANALYTICS ---
  static Future<Map<String, dynamic>?> getAnalyticsSummary() async {
    final url = Uri.parse('${AuthService.baseUrl}/analytics/summary/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching analytics summary: $e');
    }
    return null;
  }

  // --- BUDGETS ---
  static Future<List<BudgetModel>> getBudgets() async {
    final url = Uri.parse('${AuthService.baseUrl}/budgets/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((i) => BudgetModel.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error fetching budgets: $e');
    }
    return [];
  }
}

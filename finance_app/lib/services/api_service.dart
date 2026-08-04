import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- ACCOUNTS ---
  static Future<List<AccountModel>> getAccounts() async {
    final url = Uri.parse('${AuthService.baseUrl}/accounts/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((item) => AccountModel.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error fetching accounts: $e');
    }
    return [];
  }

  static Future<AccountModel?> createAccount({
    required String name,
    required String accountType,
    required double balance,
    String currency = 'USD',
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
          'currency': currency,
        }),
      );
      if (response.statusCode == 201) {
        return AccountModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error creating account: $e');
    }
    return null;
  }

  // --- CATEGORIES ---
  static Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('${AuthService.baseUrl}/categories/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((item) => CategoryModel.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    return [];
  }

  // --- TRANSACTIONS ---
  static Future<List<TransactionModel>> getTransactions({
    int? accountId,
    String? type,
    String? monthYear,
  }) async {
    var uriStr = '${AuthService.baseUrl}/transactions/?';
    if (accountId != null) uriStr += 'account=$accountId&';
    if (type != null) uriStr += 'type=$type&';
    if (monthYear != null) uriStr += 'month_year=$monthYear&';

    final url = Uri.parse(uriStr);
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((item) => TransactionModel.fromJson(item)).toList();
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
    required String date,
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
          'date': date,
          'notes': notes,
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

  // --- BUDGETS ---
  static Future<List<BudgetModel>> getBudgets() async {
    final url = Uri.parse('${AuthService.baseUrl}/budgets/');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data;
        return (results as List).map((item) => BudgetModel.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error fetching budgets: $e');
    }
    return [];
  }

  // --- ANALYTICS SUMMARY ---
  static Future<Map<String, dynamic>?> getAnalyticsSummary({String? monthYear}) async {
    var uriStr = '${AuthService.baseUrl}/analytics/summary/';
    if (monthYear != null) uriStr += '?month_year=$monthYear';

    final url = Uri.parse(uriStr);
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
}

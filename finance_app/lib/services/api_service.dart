import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final isRealToken = token != null && token.isNotEmpty && !token.startsWith('jwt_access_token_');
    return {
      'Content-Type': 'application/json',
      if (isRealToken) 'Authorization': 'Bearer $token',
    };
  }

  // --- USERS PERSISTENCE & BACKEND SYNC ---
  static final List<UserModel> _storedUsers = [];
  static bool _usersLoaded = false;

  static Future<void> _saveUsersToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _storedUsers.map((u) => u.toJson()).toList();
      await prefs.setString('saved_users', jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<void> _ensureUsersLoaded() async {
    if (_storedUsers.isNotEmpty) return;
    _usersLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('saved_users');
      if (savedStr != null && savedStr.isNotEmpty) {
        final List dynamicList = jsonDecode(savedStr);
        final loaded = dynamicList.map((i) => UserModel.fromJson(Map<String, dynamic>.from(i))).toList();
        _storedUsers.clear();
        _storedUsers.addAll(loaded);
      }
    } catch (_) {}

    if (_storedUsers.isEmpty) {
      _storedUsers.addAll([
        UserModel(
          id: 1,
          username: 'paul_pk',
          email: 'paul@dt7.agency',
          firstName: 'Paul',
          lastName: 'PK',
          role: 'EMPLOYEE',
          department: 'Engineering',
          employeeId: 'DT7EMP001',
          allocatedAmount: 25000.0,
          usedAmount: 8000.0,
          remainingAmount: 17000.0,
        ),
        UserModel(
          id: 2,
          username: 'neha_singh',
          email: 'neha@dt7.agency',
          firstName: 'Neha',
          lastName: 'Singh',
          role: 'EMPLOYEE',
          department: 'Design & UI',
          employeeId: 'DT7EMP002',
          allocatedAmount: 15000.0,
          usedAmount: 5000.0,
          remainingAmount: 10000.0,
        ),
        UserModel(
          id: 3,
          username: 'alex_j',
          email: 'alex@dt7.agency',
          firstName: 'Alex',
          lastName: 'Johnson',
          role: 'EMPLOYEE',
          department: 'Marketing',
          employeeId: 'DT7EMP003',
          allocatedAmount: 10000.0,
          usedAmount: 12000.0,
          remainingAmount: -2000.0,
        ),
      ]);
      await _saveUsersToPrefs();
    }
  }

  static List<UserModel> get storedUsers => List.unmodifiable(_storedUsers);

  static Future<List<UserModel>> getUsers() async {
    await _ensureUsersLoaded();
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/users/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 500));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List && results.isNotEmpty) {
            final parsedUsers = (results).map((i) => UserModel.fromJson(i)).toList();
            _storedUsers.clear();
            _storedUsers.addAll(parsedUsers);
            await _saveUsersToPrefs();
            break;
          }
        }
      } catch (_) {}
    }

    // Dynamically calculate user spentAmount and remainingAmount based on all active expenses
    await _ensureExpensesLoaded();
    final expenses = _storedExpenses;

    final updatedUsers = _storedUsers.map((u) {
      final spent = calculateUserSpent(u, expenses);
      final finalSpent = spent > 0 ? spent : u.usedAmount;
      final rem = u.allocatedAmount - finalSpent;

      return UserModel(
        id: u.id,
        username: u.username,
        email: u.email,
        firstName: u.firstName,
        lastName: u.lastName,
        role: u.role,
        department: u.department,
        employeeId: u.employeeId,
        allocatedAmount: u.allocatedAmount,
        usedAmount: finalSpent,
        remainingAmount: rem,
      );
    }).toList();

    return updatedUsers;
  }

  static bool isExpenseOwnedByUser(ExpenseModel exp, UserModel? user) {
    if (user == null) return false;
    final uname = user.username.trim().toLowerCase();
    final fname = user.fullName.trim().toLowerCase();
    final email = user.email.trim().toLowerCase();
    final first = user.firstName.trim().toLowerCase();
    final emailPrefix = email.contains('@') ? email.split('@').first : email;
    final expUser = exp.userName.trim().toLowerCase();

    if (expUser.isEmpty) {
      return true;
    }

    if (expUser == uname || expUser == fname || expUser == email || expUser == first || expUser == emailPrefix) {
      return true;
    }
    if (uname.isNotEmpty && (expUser.contains(uname) || uname.contains(expUser))) return true;
    if (fname.isNotEmpty && (expUser.contains(fname) || fname.contains(expUser))) return true;
    if (first.isNotEmpty && (expUser.contains(first) || first.contains(expUser))) return true;
    if (emailPrefix.isNotEmpty && (expUser.contains(emailPrefix) || emailPrefix.contains(expUser))) return true;

    return false;
  }

  static double calculateUserSpent(UserModel u, List<ExpenseModel> expenses) {
    double total = 0.0;
    for (var exp in expenses) {
      if (isExpenseOwnedByUser(exp, u)) {
        total += exp.amount;
      }
    }
    return total;
  }

  static Future<UserModel?> getCurrentUser() async {
    final rawName = await AuthService.getCurrentUsername();
    final cleanInput = rawName.trim().toLowerCase();
    final users = await getUsers();
    if (users.isEmpty) return null;

    if (cleanInput.isNotEmpty) {
      // 1. Exact match by username or email
      for (var u in users) {
        if (u.username.toLowerCase() == cleanInput || u.email.toLowerCase() == cleanInput) {
          return u;
        }
      }

      // 2. Match by firstName, fullName, or employeeId
      final prefix = cleanInput.contains('@') ? cleanInput.split('@').first : cleanInput;
      for (var u in users) {
        final uName = u.username.toLowerCase();
        final uEmail = u.email.toLowerCase();
        final uFirst = u.firstName.toLowerCase();
        final uFull = u.fullName.toLowerCase();
        final uEmpId = u.employeeId.toLowerCase();

        if (uName == prefix ||
            uEmail.startsWith(prefix) ||
            (uFirst.isNotEmpty && uFirst == prefix) ||
            (uFull.isNotEmpty && uFull == cleanInput) ||
            (uEmpId.isNotEmpty && uEmpId == cleanInput)) {
          return u;
        }
      }

      // 3. If username is set but not found in user list, construct active user model for this specific username
      final role = await AuthService.getUserRole();
      return UserModel(
        id: rawName.hashCode.abs() % 100000,
        username: rawName,
        email: cleanInput.contains('@') ? rawName : '$rawName@dt7.agency',
        firstName: rawName,
        lastName: '',
        role: role,
        department: 'Operations',
        employeeId: 'DT7EMP00',
        allocatedAmount: 10000.0,
        usedAmount: 0.0,
        remainingAmount: 10000.0,
      );
    }

    final role = await AuthService.getUserRole();
    for (var u in users) {
      if (role == 'EMPLOYEE' && (u.role == 'EMPLOYEE' || !u.isAdmin)) {
        return u;
      }
      if ((role == 'FOUNDER' || role == 'ADMIN') && (u.role == 'ADMIN' || u.role == 'FOUNDER' || u.isAdmin)) {
        return u;
      }
    }

    return users.first;
  }

  static Future<bool> addUser({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String role = 'EMPLOYEE',
  }) async {
    final nameParts = fullName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/users/');
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
            'role': role,
          }),
        ).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 201 || response.statusCode == 200) {
          await getUsers(); // Refresh user list from backend
          return true;
        }
      } catch (_) {}
    }

    final newUser = UserModel(
      id: _storedUsers.length + 1,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      department: 'Operations',
      employeeId: 'DT7EMP00${_storedUsers.length + 1}',
      allocatedAmount: 0.0,
      usedAmount: 0.0,
      remainingAmount: 0.0,
    );
    _storedUsers.add(newUser);
    await _saveUsersToPrefs();
    return true;
  }

  static Future<bool> updateUser({
    required int id,
    required String fullName,
    required String email,
    required String role,
    required double allocatedAmount,
    String? password,
  }) async {
    final nameParts = fullName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/users/$id/');
      try {
        final response = await http.patch(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'role': role,
            'allocated_amount': allocatedAmount,
            if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
          }),
        ).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
          await getUsers();
          return true;
        }
      } catch (_) {}
    }

    // Update in-memory fallback user list
    final idx = _storedUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      final existing = _storedUsers[idx];
      _storedUsers[idx] = UserModel(
        id: existing.id,
        username: existing.username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        department: existing.department,
        employeeId: existing.employeeId,
        allocatedAmount: allocatedAmount,
        usedAmount: existing.usedAmount,
        remainingAmount: (allocatedAmount - existing.usedAmount).clamp(0, double.infinity),
      );

      await _saveUsersToPrefs();
    }
    return true;
  }

  static Future<bool> deleteUser(int userId) async {
    await _ensureUsersLoaded();
    _storedUsers.removeWhere((u) => u.id == userId);
    await _saveUsersToPrefs();

    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/users/$userId/');
      try {
        final response = await http.delete(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 1000));
        if (response.statusCode == 200 || response.statusCode == 204) {
          AuthService.setActiveBaseUrl(hostUrl);
          break;
        }
      } catch (_) {}
    }
    return true;
  }

  static final List<CategoryModel> _defaultCategories = [
    CategoryModel(id: 1, name: 'Software Tools', type: 'EXPENSE', icon: 'computer', color: '#8B5CF6'),
    CategoryModel(id: 2, name: 'AI Subscriptions', type: 'EXPENSE', icon: 'psychology', color: '#EC4899'),
    CategoryModel(id: 3, name: 'Purchase of Domain or Server', type: 'EXPENSE', icon: 'dns', color: '#2563EB'),
    CategoryModel(id: 4, name: 'Cloud Infrastructure & Hosting', type: 'EXPENSE', icon: 'cloud', color: '#0EA5E9'),
    CategoryModel(id: 5, name: 'API & Third-Party Services', type: 'EXPENSE', icon: 'api', color: '#10B981'),
    CategoryModel(id: 6, name: 'Hardware & Dev Peripherals', type: 'EXPENSE', icon: 'devices', color: '#6366F1'),
    CategoryModel(id: 7, name: 'Travel & Client Visits', type: 'EXPENSE', icon: 'directions_car', color: '#F59E0B'),
    CategoryModel(id: 8, name: 'Office Supplies & Utilities', type: 'EXPENSE', icon: 'shopping_bag', color: '#64748B'),
    CategoryModel(id: 9, name: 'Others', type: 'EXPENSE', icon: 'more_horiz', color: '#9CA3AF'),
  ];

  static Future<List<CategoryModel>> getCategories() async {
    List<CategoryModel> fetchedCategories = [];

    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/categories/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 500));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List && results.isNotEmpty) {
            fetchedCategories = (results).map((i) => CategoryModel.fromJson(i)).toList();
            break;
          }
        }
      } catch (_) {}
    }

    // Filter out obsolete legacy categories (Food, Freelance, Healthcare, Education, etc.)
    final obsoleteKeywords = {'food', 'freelance', 'healthcare', 'education', 'entertainment', 'housing', 'investment'};
    final cleanFetched = fetchedCategories.where((c) {
      final lName = c.name.toLowerCase();
      return !obsoleteKeywords.any((k) => lName.contains(k));
    }).toList();

    // If cleanFetched is empty or missing modern software categories, return standard software company categories
    if (cleanFetched.isEmpty) {
      return List.from(_defaultCategories);
    }

    // Ensure software categories are merged cleanly
    final existingNames = cleanFetched.map((c) => c.name.toLowerCase()).toSet();
    final merged = List<CategoryModel>.from(cleanFetched);
    for (var def in _defaultCategories) {
      if (!existingNames.contains(def.name.toLowerCase())) {
        merged.add(def);
      }
    }
    return merged;
  }

  // --- BUDGET ALLOCATION ---
  static Future<bool> allocateBudget({
    required int employeeId,
    required double amount,
    String? note,
  }) async {
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/allocations/');
      try {
        final response = await http.post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'employee': employeeId,
            'allocated_amount': amount,
            'note': note ?? '',
          }),
        ).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 201 || response.statusCode == 200) {
          await getUsers();
          return true;
        }
      } catch (_) {}
    }

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
      await _saveUsersToPrefs();
    }
    return true;
  }

  static final List<ExpenseModel> _storedExpenses = [];
  static bool _expensesLoaded = false;

  static Future<void> _saveExpensesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _storedExpenses.map((e) => e.toJson()).toList();
      await prefs.setString('saved_expenses', jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<void> _ensureExpensesLoaded() async {
    if (_storedExpenses.isNotEmpty) return;
    _expensesLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('saved_expenses');
      if (savedStr != null && savedStr.isNotEmpty) {
        final List dynamicList = jsonDecode(savedStr);
        final loaded = dynamicList.map((i) => ExpenseModel.fromJson(Map<String, dynamic>.from(i))).toList();
        final nonSeed = loaded.where((e) => e.id != 101 && e.id != 102 && e.id != 103).toList();
        _storedExpenses.clear();
        if (nonSeed.isNotEmpty) {
          _storedExpenses.addAll(nonSeed);
        } else {
          _storedExpenses.addAll(loaded);
        }
      }
    } catch (_) {}
    if (_storedExpenses.isEmpty) {
      _storedExpenses.addAll([
        ExpenseModel(
          id: 101,
          title: 'AWS Cloud Hosting & Server Infrastructure',
          amount: 8000.0,
          categoryId: 4,
          categoryName: 'Cloud Infrastructure & Hosting',
          userName: 'Paul PK',
          dateTime: '07 Aug 2026, 09:30 AM',
          status: 'APPROVED',
          description: 'Monthly production cloud server cluster hosting',
        ),
        ExpenseModel(
          id: 102,
          title: 'Figma Professional Team Plan',
          amount: 5000.0,
          categoryId: 1,
          categoryName: 'Software Tools',
          userName: 'Neha Singh',
          dateTime: '05 Aug 2026, 11:00 AM',
          status: 'APPROVED',
          description: 'UI/UX team design software licenses',
        ),
        ExpenseModel(
          id: 103,
          title: 'Meta Ads & Growth Marketing Tools',
          amount: 12000.0,
          categoryId: 5,
          categoryName: 'API & Third-Party Services',
          userName: 'Alex Johnson',
          dateTime: '03 Aug 2026, 01:45 PM',
          status: 'APPROVED',
          description: 'Client campaign ad spend and marketing tools',
        ),
      ]);
      await _saveExpensesToPrefs();
    }
  }

  // --- EXPENSES ---
  static Future<List<ExpenseModel>> getExpenses() async {
    await _ensureExpensesLoaded();
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/expenses/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 500));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List && results.isNotEmpty) {
            final fetched = (results).map((i) => ExpenseModel.fromJson(i)).toList();
            _storedExpenses.clear();
            _storedExpenses.addAll(fetched);
            await _saveExpensesToPrefs();
            return List.from(_storedExpenses);
          }
        }
      } catch (_) {}
    }
    return List.from(_storedExpenses);
  }

  static Future<bool> addExpense({
    required String title,
    required double amount,
    required int categoryId,
    required String date,
    String? note,
    String? receiptPath,
  }) async {
    return createExpense(
      title: title,
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
      receiptPath: receiptPath,
    );
  }

  static Future<bool> createExpense({
    required String title,
    required double amount,
    required int categoryId,
    String? date,
    String? dateTime,
    String? note,
    String? description,
    String? receiptPath,
  }) async {
    await _ensureExpensesLoaded();

    final Map<int, String> categoryNames = {
      1: 'Software Tools',
      2: 'AI Subscriptions',
      3: 'Purchase of Domain or Server',
      4: 'Cloud Infrastructure & Hosting',
      5: 'API & Third-Party Services',
      6: 'Hardware & Dev Peripherals',
      7: 'Travel & Client Visits',
      8: 'Office Supplies & Utilities',
      9: 'Others',
    };
    final catName = categoryNames[categoryId] ?? 'Software Tools';

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}, $timeStr';

    final currentUser = await getCurrentUser();
    final uName = currentUser?.username ?? '';
    final fName = currentUser?.fullName ?? '';
    final expUser = uName.isNotEmpty ? uName : (fName.isNotEmpty ? fName : 'Current Employee');
    final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
    int realDbId = newId;

    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/expenses/');
      try {
        final response = await http.post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'title': title,
            'amount': amount,
            'category_name': catName,
            'date_time': DateTime.now().toIso8601String(),
            'description': note ?? description ?? '',
            'user_name': expUser,
            'status': 'PENDING',
            if (receiptPath != null) 'receipt_image': receiptPath,
          }),
        ).timeout(const Duration(milliseconds: 1000));

        if (response.statusCode == 200 || response.statusCode == 201) {
          AuthService.setActiveBaseUrl(hostUrl);
          try {
            final body = jsonDecode(response.body);
            if (body is Map && body['id'] != null) {
              realDbId = int.tryParse(body['id'].toString()) ?? newId;
            }
          } catch (_) {}
          break;
        } else {
          debugPrint('[DB SYNC] Response error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('[DB SYNC] Post expense error: $e');
      }
    }

    final newExp = ExpenseModel(
      id: realDbId,
      title: title,
      amount: amount,
      categoryId: categoryId,
      categoryName: catName,
      dateTime: dateTime ?? date ?? dateStr,
      status: 'PENDING',
      description: note ?? description ?? '',
      userName: expUser,
      receiptImage: receiptPath,
    );

    _storedExpenses.removeWhere((e) => e.id == newId || e.id == realDbId);
    _storedExpenses.insert(0, newExp);
    await _saveExpensesToPrefs();

    // Note: Used budget is ONLY updated when expense status is APPROVED by admin.
    return true;
  }

  static Future<bool> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String categoryName,
    String? status,
    String? approvedBy,
    String? approvalDate,
  }) async {
    await _ensureExpensesLoaded();

    final currentUser = await getCurrentUser();
    final activeApprover = approvedBy ??
        (currentUser != null && currentUser.fullName.isNotEmpty
            ? currentUser.fullName
            : (currentUser?.username.isNotEmpty == true ? currentUser!.username : 'Founder Admin'));
    final activeDate = approvalDate ?? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final idx = _storedExpenses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final existing = _storedExpenses[idx];
      final newStatus = status ?? existing.status;
      final isApprovalChange = status != null && (newStatus == 'APPROVED' || newStatus == 'REJECTED');

      _storedExpenses[idx] = ExpenseModel(
        id: existing.id,
        title: title,
        amount: amount,
        categoryId: existing.categoryId,
        categoryName: categoryName,
        dateTime: existing.dateTime,
        status: newStatus,
        description: existing.description,
        userName: existing.userName,
        paymentMode: existing.paymentMode,
        receiptImage: existing.receiptImage,
        approvedBy: isApprovalChange ? activeApprover : existing.approvedBy,
        approvalDate: isApprovalChange ? activeDate : existing.approvalDate,
      );
      await _saveExpensesToPrefs();

      // Recalculate usedAmount & remainingAmount for the expense owner based ONLY on APPROVED expenses
      final expUser = existing.userName.toLowerCase();
      final userIdx = _storedUsers.indexWhere((u) => u.username.toLowerCase() == expUser || '${u.firstName} ${u.lastName}'.toLowerCase() == expUser);
      if (userIdx != -1) {
        final u = _storedUsers[userIdx];
        final approvedSum = _storedExpenses
            .where((e) => e.userName.toLowerCase() == expUser && e.isApproved)
            .fold(0.0, (sum, e) => sum + e.amount);
        final newRem = u.allocatedAmount - approvedSum;
        _storedUsers[userIdx] = UserModel(
          id: u.id,
          username: u.username,
          email: u.email,
          firstName: u.firstName,
          lastName: u.lastName,
          role: u.role,
          department: u.department,
          employeeId: u.employeeId,
          allocatedAmount: u.allocatedAmount,
          usedAmount: approvedSum,
          remainingAmount: newRem,
        );
        await _saveUsersToPrefs();
      }
    }

    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/expenses/$id/');
      try {
        final response = await http.patch(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'title': title,
            'amount': amount,
            'category_name': categoryName,
            if (status != null) 'status': status,
            if (status != null) 'approved_by': activeApprover,
            if (status != null) 'reviewed_by': activeApprover,
            if (status != null) 'approval_date': activeDate,
          }),
        ).timeout(const Duration(milliseconds: 1000));

        if (response.statusCode == 200 || response.statusCode == 201) {
          AuthService.setActiveBaseUrl(hostUrl);
          break;
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> deleteExpense(int expenseId) async {
    await _ensureExpensesLoaded();
    _storedExpenses.removeWhere((e) => e.id == expenseId);
    await _saveExpensesToPrefs();
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/expenses/$expenseId/');
      try {
        final response = await http.delete(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 1000));
        if (response.statusCode == 200 || response.statusCode == 204) {
          AuthService.setActiveBaseUrl(hostUrl);
          break;
        }
      } catch (_) {}
    }
    return true;
  }

  // --- APPROVAL ACTIONS ---
  static Future<bool> submitApprovalAction(int id, String type, String action) async {
    final statusStr = action == 'approve' || action == 'APPROVED' ? 'APPROVED' : 'REJECTED';
    await _ensureExpensesLoaded();
    final idx = _storedExpenses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final e = _storedExpenses[idx];
      _storedExpenses[idx] = ExpenseModel(
        id: e.id,
        title: e.title,
        amount: e.amount,
        categoryId: e.categoryId,
        categoryName: e.categoryName,
        dateTime: e.dateTime,
        status: statusStr,
        description: e.description,
        userName: e.userName,
        paymentMode: e.paymentMode,
        receiptImage: e.receiptImage,
        approvedBy: e.approvedBy,
        approvalDate: e.approvalDate,
      );
      await _saveExpensesToPrefs();
    }

    for (final hostUrl in AuthService.candidateUrls) {
      final urlAction = Uri.parse('$hostUrl/approvals/$id/action/');
      final urlExpense = Uri.parse('$hostUrl/expenses/$id/');
      try {
        await http.post(
          urlAction,
          headers: await _getHeaders(),
          body: jsonEncode({'action': action, 'type': type}),
        ).timeout(const Duration(milliseconds: 1000));

        final response = await http.patch(
          urlExpense,
          headers: await _getHeaders(),
          body: jsonEncode({'status': statusStr}),
        ).timeout(const Duration(milliseconds: 1000));

        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          return true;
        }
      } catch (_) {}
    }
    return true;
  }

  // --- BUDGET REQUESTS ---
  static Future<List<BudgetRequestModel>> getBudgetRequests() async {
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/budget-requests/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List) {
            return (results).map((i) => BudgetRequestModel.fromJson(i)).toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<bool> submitBudgetRequest({
    required double requestAmount,
    required int categoryId,
    required String reason,
  }) async {
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/budget-requests/');
      try {
        final response = await http.post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'request_amount': requestAmount,
            'category': categoryId,
            'reason': reason,
          }),
        ).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> updateBudgetRequestStatus(int requestId, String status) async {
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/budget-requests/$requestId/');
      try {
        final response = await http.patch(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({'status': status}),
        ).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return true;
  }

  // --- REPORTS ---
  static Future<Map<String, dynamic>> getReports() async {
    if (await AuthService.hasRealToken()) {
      for (final hostUrl in AuthService.candidateBaseUrls) {
        final url = Uri.parse('$hostUrl/reports/');
        try {
          final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
          if (response.statusCode == 200) {
            return jsonDecode(response.body);
          }
        } catch (_) {}
      }
    }
    await _ensureExpensesLoaded();
    final totalSpent = _storedExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final users = await getUsers();
    final totalBudget = users.fold(0.0, (sum, u) => sum + u.allocatedAmount);

    final catMap = <String, double>{};
    for (var e in _storedExpenses) {
      catMap[e.categoryName] = (catMap[e.categoryName] ?? 0.0) + e.amount;
    }
    final breakdown = catMap.entries.map((entry) => {'category': entry.key, 'amount': entry.value}).toList();

    return {
      'total_expenses': totalSpent,
      'total_budget': totalBudget,
      'categories_breakdown': breakdown,
    };
  }

  // --- DASHBOARDS ---
  static Future<Map<String, dynamic>?> getFounderDashboard() async {
    if (await AuthService.hasRealToken()) {
      for (final hostUrl in AuthService.candidateUrls) {
        final url = Uri.parse('$hostUrl/dashboard/founder/');
        try {
          final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 500));
          if (response.statusCode == 200) {
            AuthService.setActiveBaseUrl(hostUrl);
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic>) {
              return data;
            }
          }
        } catch (_) {}
      }
    }

    final users = await getUsers();
    final expenses = await getExpenses();

    double totalExpensesSum = expenses.fold(0.0, (s, e) => s + e.amount);
    double totalAllocated = 0.0;
    int overBudgetCount = 0;

    for (var u in users) {
      totalAllocated += u.allocatedAmount;

      final spent = calculateUserSpent(u, expenses);
      final actualUserSpent = spent > 0 ? spent : u.usedAmount;

      if ((actualUserSpent > u.allocatedAmount || (u.allocatedAmount - actualUserSpent) < 0) && u.allocatedAmount > 0) {
        overBudgetCount++;
      }
    }

    final usersUsedSum = users.fold(0.0, (s, u) => s + u.usedAmount);
    final totalSpentFinal = totalExpensesSum > usersUsedSum ? totalExpensesSum : usersUsedSum;
    final remaining = totalAllocated - totalSpentFinal;

    return {
      'remaining_budget': remaining,
      'total_allocated': totalAllocated,
      'total_expenses': totalSpentFinal,
      'total_users': users.length,
      'over_budget': overBudgetCount,
    };
  }

  static Future<Map<String, dynamic>?> getEmployeeDashboard() async {
    if (await AuthService.hasRealToken()) {
      for (final hostUrl in AuthService.candidateUrls) {
        final url = Uri.parse('$hostUrl/dashboards/employee/');
        try {
          final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 500));
          if (response.statusCode == 200) {
            AuthService.setActiveBaseUrl(hostUrl);
            return jsonDecode(response.body);
          }
        } catch (_) {}
      }
    }

    final current = await getCurrentUser();
    final allocated = current?.allocatedAmount ?? 0.0;
    final used = current?.usedAmount ?? 0.0;
    final remaining = current?.remainingAmount ?? (allocated - used);
    return {
      'allocated_budget': allocated,
      'total_expenses': used,
      'remaining_balance': remaining,
    };
  }

  // --- ACTIVITY LOGS ---
  static Future<List<ActivityLogModel>> getActivityLogs() async {
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/activity-logs/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List) {
            return (results).map((i) => ActivityLogModel.fromJson(i)).toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }

  // --- ACCOUNTS, TRANSACTIONS, ANALYTICS & BUDGETS ---
  static Future<List<AccountModel>> getAccounts() async {
    final dash = await getFounderDashboard();
    final bal = (dash?['remaining_budget'] as double?) ?? 0.0;
    return [
      AccountModel(id: 1, name: 'Main Corporate Checking', accountType: 'CHECKING', balance: bal),
    ];
  }

  static Future<bool> createAccount({
    required String name,
    required String accountType,
    required double balance,
  }) async {
    return true;
  }

  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final dash = await getFounderDashboard();
    final bal = (dash?['remaining_budget'] as double?) ?? 0.0;
    final exp = (dash?['total_expenses'] as double?) ?? 0.0;
    final alloc = (dash?['total_allocated'] as double?) ?? 0.0;
    final savings = alloc > 0 ? (((alloc - exp) / alloc) * 100).clamp(0.0, 100.0) : 0.0;

    return {
      'total_balance': bal,
      'monthly_income': alloc,
      'monthly_expenses': exp,
      'savings_rate': savings,
    };
  }

  static Future<List<BudgetModel>> getBudgets() async {
    await _ensureExpensesLoaded();
    final cats = await getCategories();
    final list = <BudgetModel>[];
    for (var cat in cats) {
      final spent = _storedExpenses.where((e) => e.categoryId == cat.id || e.categoryName.toLowerCase() == cat.name.toLowerCase()).fold(0.0, (s, e) => s + e.amount);
      if (spent > 0) {
        list.add(BudgetModel(id: cat.id, categoryId: cat.id, limitAmount: spent * 1.5, monthYear: '2026-08', spentAmount: spent, remainingAmount: (spent * 0.5)));
      }
    }
    return list;
  }

  static Future<List<TransactionModel>> getTransactions() async {
    await _ensureExpensesLoaded();
    return _storedExpenses.map((e) => TransactionModel(
      id: e.id,
      accountId: 1,
      title: e.title,
      amount: e.amount,
      transactionType: 'EXPENSE',
      date: e.dateTime,
    )).toList();
  }

  static Future<bool> createTransaction({
    required int accountId,
    required String title,
    required double amount,
    required String transactionType,
    required String date,
    int? categoryId,
    String? notes,
  }) async {
    return true;
  }
}

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
import '../models/role_model.dart';

class ApiService {
  static Future<void> ensureDataLoaded() async {
    await _ensureUsersLoaded();
    await _ensureExpensesLoaded();
    await _ensureBudgetRequestsLoaded();
  }

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
        UserModel(id: 1, username: 'founder', email: 'founder@dt7.agency', firstName: 'Diya', lastName: 'Founder', allocatedAmount: 100000, role: 'FOUNDER', department: 'Executive'),
        UserModel(id: 2, username: 'admin', email: 'admin@dt7.agency', firstName: 'Admin', lastName: 'User', allocatedAmount: 50000, role: 'ADMIN', department: 'Administration'),
        UserModel(id: 3, username: 'aadmin', email: 'aadmin@dt7.agency', firstName: 'Aadmin', lastName: 'Manager', allocatedAmount: 50000, role: 'ADMIN', department: 'Administration'),
        UserModel(id: 4, username: 'john_doe', email: 'john.doe@example.com', firstName: 'John', lastName: 'Doe', allocatedAmount: 10000, role: 'FOUNDER', department: 'Executive'),
        UserModel(id: 5, username: 'paul_pk', email: 'paul@example.com', firstName: 'Paul', lastName: 'PK', allocatedAmount: 25000, role: 'EMPLOYEE', department: 'Engineering'),
        UserModel(id: 6, username: 'paul', email: 'paul@gmail.com', firstName: 'Paul', lastName: 'PK', allocatedAmount: 25000, role: 'EMPLOYEE', department: 'Engineering'),
        UserModel(id: 7, username: 'neha', email: 'neha@gmail.com', firstName: 'Neha', lastName: 'Singh', allocatedAmount: 8000, role: 'EMPLOYEE', department: 'Design'),
        UserModel(id: 8, username: 'ramu', email: 'ramu@gmail.com', firstName: 'Ramu', lastName: 'Sharma', allocatedAmount: 20000, role: 'EMPLOYEE', department: 'Sales'),
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
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List) {
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
      final rem = u.allocatedAmount - spent;

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
        usedAmount: spent,
        remainingAmount: rem,
      );
    }).toList();

    _storedUsers.clear();
    _storedUsers.addAll(updatedUsers);
    await _saveUsersToPrefs();

    return List.from(_storedUsers);
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
      return false;
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

  static bool isBudgetRequestOwnedByUser(BudgetRequestModel req, UserModel? user) {
    if (user == null) return false;
    final uname = user.username.trim().toLowerCase();
    final fname = user.fullName.trim().toLowerCase();
    final email = user.email.trim().toLowerCase();
    final first = user.firstName.trim().toLowerCase();
    final emailPrefix = email.contains('@') ? email.split('@').first : email;
    final reqUser = req.userName.trim().toLowerCase();

    if (reqUser.isEmpty) {
      return false;
    }

    if (reqUser == uname || reqUser == fname || reqUser == email || reqUser == first || reqUser == emailPrefix) {
      return true;
    }
    if (uname.isNotEmpty && (reqUser.contains(uname) || uname.contains(reqUser))) return true;
    if (fname.isNotEmpty && (reqUser.contains(fname) || fname.contains(reqUser))) return true;
    if (first.isNotEmpty && (reqUser.contains(first) || first.contains(reqUser))) return true;
    if (emailPrefix.isNotEmpty && (reqUser.contains(emailPrefix) || emailPrefix.contains(reqUser))) return true;

    return false;
  }

  static double calculateUserSpent(UserModel u, List<ExpenseModel> expenses) {
    double total = 0.0;
    for (var exp in expenses) {
      if (isExpenseOwnedByUser(exp, u)) {
        final st = exp.status.trim().toUpperCase();
        if (exp.isApproved || st == 'APPROVED' || st == 'PAID') {
          total += exp.amount;
        }
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
    double allocatedAmount = 0.0,
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
            'initial_allocated_amount': allocatedAmount,
          }),
        ).timeout(const Duration(seconds: 8));
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
      allocatedAmount: allocatedAmount,
      usedAmount: 0.0,
      remainingAmount: allocatedAmount,
    );
    _storedUsers.add(newUser);
    await _saveUsersToPrefs();
    return true;
  }

  // --- ROLES MANAGEMENT ---
  static final List<RoleModel> _defaultRoles = [
    RoleModel(
      id: 1,
      name: 'Founder',
      code: 'FOUNDER',
      description: 'Super User role with overall executive authority over all system features, financial approvals, budget allocations, and user management.',
      isSystemRole: true,
      canViewAllExpenses: true,
      canApproveExpenses: true,
      canAllocateBudget: true,
      canManageUsers: true,
      canViewAnalytics: true,
    ),
    RoleModel(
      id: 2,
      name: 'Admin',
      code: 'ADMIN',
      description: 'Full administrative control over all finances, users, approvals, and system settings.',
      isSystemRole: true,
      canViewAllExpenses: true,
      canApproveExpenses: true,
      canAllocateBudget: true,
      canManageUsers: true,
      canViewAnalytics: true,
    ),
    RoleModel(
      id: 2,
      name: 'Staff',
      code: 'STAFF',
      description: 'General staff member access to submit expenses and request budget allocations.',
      isSystemRole: true,
      canViewAllExpenses: false,
      canApproveExpenses: false,
      canAllocateBudget: false,
      canManageUsers: false,
      canViewAnalytics: false,
    ),
    RoleModel(
      id: 3,
      name: 'Accountant',
      code: 'ACCOUNTANT',
      description: 'Access to view financial reports, audit logs, and approve expense entries.',
      isSystemRole: true,
      canViewAllExpenses: true,
      canApproveExpenses: true,
      canAllocateBudget: false,
      canManageUsers: false,
      canViewAnalytics: true,
    ),
    RoleModel(
      id: 4,
      name: 'Finance Manager',
      code: 'MANAGER',
      description: 'Can manage team budgets, view all expenses, and approve budget and expense requests.',
      isSystemRole: true,
      canViewAllExpenses: true,
      canApproveExpenses: true,
      canAllocateBudget: true,
      canManageUsers: false,
      canViewAnalytics: true,
    ),
    RoleModel(
      id: 5,
      name: 'Finance Auditor',
      code: 'FINANCE',
      description: 'View-only access to financial reports, analytics, and expense audit logs.',
      isSystemRole: true,
      canViewAllExpenses: true,
      canApproveExpenses: false,
      canAllocateBudget: false,
      canManageUsers: false,
      canViewAnalytics: true,
    ),
    RoleModel(
      id: 6,
      name: 'Employee',
      code: 'EMPLOYEE',
      description: 'Standard employee access to submit expenses, request budgets, and view personal wallet.',
      isSystemRole: true,
      canViewAllExpenses: false,
      canApproveExpenses: false,
      canAllocateBudget: false,
      canManageUsers: false,
      canViewAnalytics: false,
    ),
  ];

  static Future<List<RoleModel>> getRoles() async {
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/roles/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List && results.isNotEmpty) {
            return (results).map((i) => RoleModel.fromJson(i)).toList();
          }
        }
      } catch (_) {}
    }
    return List.from(_defaultRoles);
  }

  static Future<bool> createRole(RoleModel role) async {
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/roles/');
      try {
        final response = await http.post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode(role.toJson()),
        ).timeout(const Duration(seconds: 8));
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> updateRole(RoleModel role) async {
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/roles/${role.id}/');
      try {
        final response = await http.patch(
          url,
          headers: await _getHeaders(),
          body: jsonEncode(role.toJson()),
        ).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> deleteRole(int roleId) async {
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/roles/$roleId/');
      try {
        final response = await http.delete(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 || response.statusCode == 204) {
          return true;
        }
      } catch (_) {}
    }
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
        ).timeout(const Duration(seconds: 8));
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
        final response = await http.delete(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 || response.statusCode == 204) {
          AuthService.setActiveBaseUrl(hostUrl);
          break;
        }
      } catch (_) {}
    }
    return true;
  }

  static final List<CategoryModel> _defaultCategories = [
    CategoryModel(id: 1, name: 'Software & SaaS Subscriptions', type: 'EXPENSE', icon: 'computer', color: '#8B5CF6'),
    CategoryModel(id: 2, name: 'Cloud Hosting & Infrastructure (AWS/Azure/GCP)', type: 'EXPENSE', icon: 'cloud', color: '#0EA5E9'),
    CategoryModel(id: 3, name: 'AI Tools & API Subscriptions (OpenAI/Claude)', type: 'EXPENSE', icon: 'psychology', color: '#EC4899'),
    CategoryModel(id: 4, name: 'Purchase of Domain or SSL Certificates', type: 'EXPENSE', icon: 'dns', color: '#2563EB'),
    CategoryModel(id: 5, name: 'Hardware & Dev Peripherals (Laptops/Monitors)', type: 'EXPENSE', icon: 'devices', color: '#6366F1'),
    CategoryModel(id: 6, name: 'Cybersecurity & Antivirus Software', type: 'EXPENSE', icon: 'security', color: '#EF4444'),
    CategoryModel(id: 7, name: 'DevOps & CI/CD Tools (GitHub/Docker)', type: 'EXPENSE', icon: 'integration_instructions', color: '#10B981'),
    CategoryModel(id: 8, name: 'IT Consultancy & Technical Services', type: 'EXPENSE', icon: 'engineering', color: '#F59E0B'),
    CategoryModel(id: 9, name: 'Network & High-Speed Internet', type: 'EXPENSE', icon: 'wifi', color: '#14B8A6'),
    CategoryModel(id: 10, name: 'Office Supplies & Tech Utilities', type: 'EXPENSE', icon: 'shopping_bag', color: '#64748B'),
    CategoryModel(id: 11, name: 'Travel & Client On-site Visits', type: 'EXPENSE', icon: 'directions_car', color: '#D97706'),
    CategoryModel(id: 12, name: 'Meals & Team Offsites', type: 'EXPENSE', icon: 'restaurant', color: '#F43F5E'),
    CategoryModel(id: 13, name: 'Others', type: 'EXPENSE', icon: 'more_horiz', color: '#9CA3AF'),
    CategoryModel(id: 14, name: 'Cloud Infrastructure & Hosting', type: 'EXPENSE', icon: 'cloud', color: '#0EA5E9'),
    CategoryModel(id: 15, name: 'API & Third-Party Services', type: 'EXPENSE', icon: 'category', color: '#2563EB'),
    CategoryModel(id: 16, name: 'Software Tools', type: 'EXPENSE', icon: 'computer', color: '#8B5CF6'),
  ];

  static Future<List<CategoryModel>> getCategories() async {
    List<CategoryModel> fetchedCategories = [];

    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/categories/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
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
    bool isAddition = true,
  }) async {
    await _ensureUsersLoaded();
    final index = _storedUsers.indexWhere((u) => u.id == employeeId);

    double targetTotal = amount;
    double incrementalAmount = amount;

    if (index != -1) {
      final currentAlloc = _storedUsers[index].allocatedAmount;
      if (isAddition) {
        targetTotal = currentAlloc + amount;
        incrementalAmount = amount;
      } else {
        targetTotal = amount;
        incrementalAmount = amount - currentAlloc;
      }
    }

    // 1. Send allocation record to /allocations/
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/allocations/');
      try {
        final resp = await http.post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'employee': employeeId,
            'allocated_amount': incrementalAmount,
            'note': note ?? '',
          }),
        ).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
        }
      } catch (_) {}
    }

    // 2. Also patch user to guarantee allocated_amount is saved directly on user profile in backend database
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/users/$employeeId/');
      try {
        final response = await http.patch(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'allocated_amount': targetTotal,
          }),
        ).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          await getUsers(); // Reload updated users list directly from PostgreSQL
          break;
        }
      } catch (_) {}
    }

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
        allocatedAmount: targetTotal,
        usedAmount: existing.usedAmount,
        remainingAmount: targetTotal - existing.usedAmount,
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
        ExpenseModel(id: 1, title: 'Server Hosting (AWS)', amount: 15000.0, categoryName: 'Cloud Hosting & Infrastructure (AWS/Azure/GCP)', dateTime: '2026-08-06', status: 'Approved', userName: 'paul_pk'),
        ExpenseModel(id: 2, title: 'OpenAI API Subscriptions', amount: 5000.0, categoryName: 'AI Tools & API Subscriptions (OpenAI/Claude)', dateTime: '2026-08-07', status: 'Approved', userName: 'john_doe'),
        ExpenseModel(id: 3, title: 'Team Lunch & Client Onsite', amount: 3500.0, categoryName: 'Meals & Team Offsites', dateTime: '2026-08-08', status: 'Approved', userName: 'rahul_sharma'),
      ]);
      await _saveExpensesToPrefs();
    }
  }

  static List<ExpenseModel> get storedExpenses => List.unmodifiable(_storedExpenses);

  // --- EXPENSES ---
  static Future<List<ExpenseModel>> getExpenses() async {
    await _ensureExpensesLoaded();
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/expenses/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List) {
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
            'category': categoryId,
            'category_name': catName,
            'user': currentUser?.id,
            'user_name': expUser,
            'date_time': dateTime ?? DateTime.now().toIso8601String(),
            'description': note ?? description ?? '',
            'status': 'APPROVED',
            if (receiptPath != null) 'receipt_image': receiptPath,
          }),
        ).timeout(const Duration(seconds: 8));

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
      status: 'APPROVED',
      description: note ?? description ?? '',
      userName: expUser,
      receiptImage: receiptPath,
    );

    _storedExpenses.removeWhere((e) => e.id == newId || e.id == realDbId);
    _storedExpenses.insert(0, newExp);
    await _saveExpensesToPrefs();

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
        ).timeout(const Duration(seconds: 8));

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
        final response = await http.delete(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
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
        ).timeout(const Duration(seconds: 8));

        final response = await http.patch(
          urlExpense,
          headers: await _getHeaders(),
          body: jsonEncode({'status': statusStr}),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          return true;
        }
      } catch (_) {}
    }
    return true;
  }

  // --- BUDGET REQUESTS ---
  static final List<BudgetRequestModel> _storedBudgetRequests = [];

  static Future<void> _saveBudgetRequestsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _storedBudgetRequests.map((r) => r.toJson()).toList();
      await prefs.setString('saved_budget_requests', jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<void> _ensureBudgetRequestsLoaded() async {
    if (_storedBudgetRequests.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('saved_budget_requests');
      if (savedStr != null && savedStr.isNotEmpty) {
        final List dynamicList = jsonDecode(savedStr);
        final loaded = dynamicList.map((i) => BudgetRequestModel.fromJson(Map<String, dynamic>.from(i))).toList();
        _storedBudgetRequests.clear();
        _storedBudgetRequests.addAll(loaded);
      }
    } catch (_) {}
    if (_storedBudgetRequests.isEmpty) {
      await _saveBudgetRequestsToPrefs();
    }
  }

  static Future<List<BudgetRequestModel>> getBudgetRequests() async {
    await _ensureBudgetRequestsLoaded();
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/budget-requests/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List) {
            final fetched = (results).map((i) => BudgetRequestModel.fromJson(i)).toList();
            _storedBudgetRequests.clear();
            _storedBudgetRequests.addAll(fetched);
            await _saveBudgetRequestsToPrefs();
            return List.from(_storedBudgetRequests);
          }
        }
      } catch (_) {}
    }
    return List.from(_storedBudgetRequests);
  }

  static Future<bool> submitBudgetRequest({
    required double requestAmount,
    required int categoryId,
    required String reason,
  }) async {
    await _ensureBudgetRequestsLoaded();

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
    final catName = categoryNames[categoryId] ?? 'General';

    final currentUser = await getCurrentUser();
    final uName = currentUser?.fullName.isNotEmpty == true
        ? currentUser!.fullName
        : (currentUser?.username.isNotEmpty == true ? currentUser!.username : 'Employee');

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
    final newId = now.millisecondsSinceEpoch % 1000000;

    final newRequest = BudgetRequestModel(
      id: newId,
      userName: uName,
      requestAmount: requestAmount,
      categoryName: catName,
      reason: reason,
      status: 'PENDING',
      createdAt: dateStr,
    );

    _storedBudgetRequests.insert(0, newRequest);
    await _saveBudgetRequestsToPrefs();

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
            'user_name': uName,
          }),
        ).timeout(const Duration(seconds: 8));
        if (response.statusCode == 201 || response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          try {
            final createdJson = jsonDecode(response.body);
            final backendReq = BudgetRequestModel.fromJson(createdJson);
            final tempIdx = _storedBudgetRequests.indexWhere((r) => r.id == newId);
            if (tempIdx != -1) {
              _storedBudgetRequests[tempIdx] = backendReq;
            } else {
              _storedBudgetRequests.insert(0, backendReq);
            }
            await _saveBudgetRequestsToPrefs();
          } catch (_) {}
          break;
        }
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> updateBudgetRequestStatus(int requestId, String status) async {
    await _ensureBudgetRequestsLoaded();
    final index = _storedBudgetRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final existing = _storedBudgetRequests[index];
      _storedBudgetRequests[index] = BudgetRequestModel(
        id: existing.id,
        userName: existing.userName,
        requestAmount: existing.requestAmount,
        categoryName: existing.categoryName,
        reason: existing.reason,
        status: status,
        createdAt: existing.createdAt,
      );
      await _saveBudgetRequestsToPrefs();

      if (status.toUpperCase() == 'APPROVED') {
        final users = await getUsers();
        final userIdx = users.indexWhere((u) => isBudgetRequestOwnedByUser(existing, u));

        if (userIdx != -1) {
          final targetUser = users[userIdx];
          await allocateBudget(
            employeeId: targetUser.id,
            amount: existing.requestAmount,
            isAddition: true,
            note: 'Approved from Budget Request: ${existing.reason}',
          );
        }
      }
    }

    final isApproved = status.toUpperCase() == 'APPROVED';
    final actionStr = isApproved ? 'approve' : 'reject';

    for (final hostUrl in AuthService.candidateBaseUrls) {
      final urlAction = Uri.parse('$hostUrl/approvals/$requestId/action/');
      final urlReq = Uri.parse('$hostUrl/budget-requests/$requestId/');
      final urlCustomAction = Uri.parse('$hostUrl/budget-requests/$requestId/$actionStr/');

      try {
        await http.post(
          urlAction,
          headers: await _getHeaders(),
          body: jsonEncode({
            'action': actionStr,
            'type': 'budget_request',
            'status': status.toUpperCase(),
          }),
        ).timeout(const Duration(seconds: 8));

        await http.post(
          urlCustomAction,
          headers: await _getHeaders(),
        ).timeout(const Duration(seconds: 8));

        await http.patch(
          urlReq,
          headers: await _getHeaders(),
          body: jsonEncode({'status': status.toUpperCase()}),
        ).timeout(const Duration(seconds: 8));
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
          final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
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
    for (final hostUrl in AuthService.candidateUrls) {
      final url = Uri.parse('$hostUrl/dashboard/founder/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          AuthService.setActiveBaseUrl(hostUrl);
          final data = jsonDecode(response.body);
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
        }
      } catch (_) {}
    }

    final users = await getUsers();
    final expenses = await getExpenses();

    double totalExpensesSum = expenses
        .where((e) => e.isApproved || e.status.toUpperCase() == 'APPROVED' || e.status.toUpperCase() == 'PAID')
        .fold(0.0, (s, e) => s + e.amount);
    double totalAllocated = 0.0;
    int overBudgetCount = 0;

    for (var u in users) {
      if (u.allocatedAmount > 0) {
        totalAllocated += u.allocatedAmount;
      }

      final spent = calculateUserSpent(u, expenses);

      if ((spent > u.allocatedAmount || (u.allocatedAmount - spent) < 0) && u.allocatedAmount > 0) {
        overBudgetCount++;
      }
    }

    final remaining = totalAllocated - totalExpensesSum;

    return {
      'remaining_budget': remaining,
      'total_allocated': totalAllocated,
      'total_expenses': totalExpensesSum,
      'total_users': users.length,
      'over_budget': overBudgetCount,
    };
  }

  static Future<Map<String, dynamic>?> getEmployeeDashboard() async {
    if (await AuthService.hasRealToken()) {
      for (final hostUrl in AuthService.candidateUrls) {
        final url = Uri.parse('$hostUrl/dashboards/employee/');
        try {
          final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
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
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 8));
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
    final bal = (num.tryParse(dash?['remaining_budget']?.toString() ?? '') ?? 0.0).toDouble();
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
    final bal = (num.tryParse(dash?['remaining_budget']?.toString() ?? '') ?? 0.0).toDouble();
    final exp = (num.tryParse(dash?['total_expenses']?.toString() ?? '') ?? 0.0).toDouble();
    final alloc = (num.tryParse(dash?['total_allocated']?.toString() ?? '') ?? 0.0).toDouble();
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

  static Future<List<TransactionModel>> getTransactions({String? type}) async {
    await _ensureExpensesLoaded();
    final list = _storedExpenses.map((e) => TransactionModel(
      id: e.id,
      accountId: 1,
      title: e.title,
      amount: e.amount,
      transactionType: 'EXPENSE',
      date: e.dateTime,
    )).toList();
    if (type != null && type.isNotEmpty && type != 'ALL') {
      return list.where((t) => t.transactionType.toUpperCase() == type.toUpperCase()).toList();
    }
    return list;
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

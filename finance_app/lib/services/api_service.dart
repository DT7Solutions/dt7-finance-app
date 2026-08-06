import 'dart:convert';
import 'package:http/http.dart' as http;
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
    if (_usersLoaded && _storedUsers.isNotEmpty) return;
    _usersLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('saved_users');
      if (savedStr != null && savedStr.isNotEmpty) {
        final List dynamicList = jsonDecode(savedStr);
        final loaded = dynamicList.map((i) => UserModel.fromJson(Map<String, dynamic>.from(i))).toList();
        _storedUsers.clear();
        _storedUsers.addAll(loaded);
        return;
      }
    } catch (_) {}
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
            final parsedIds = parsedUsers.map((u) => u.id).toSet();
            final localOnly = _storedUsers.where((u) => !parsedIds.contains(u.id)).toList();
            _storedUsers.clear();
            _storedUsers.addAll([...localOnly, ...parsedUsers]);
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

  static double calculateUserSpent(UserModel u, List<ExpenseModel> expenses) {
    final uname = u.username.trim().toLowerCase();
    final fname = u.fullName.trim().toLowerCase();
    final email = u.email.trim().toLowerCase();
    final first = u.firstName.trim().toLowerCase();

    double total = 0.0;
    for (var exp in expenses) {
      final expUser = exp.userName.trim().toLowerCase();
      if (expUser.isEmpty) continue;

      bool matches = false;
      if (expUser == uname || expUser == fname || expUser == email) {
        matches = true;
      } else if (uname.isNotEmpty && (expUser.contains(uname) || uname.contains(expUser))) {
        matches = true;
      } else if (fname.isNotEmpty && (expUser.contains(fname) || fname.contains(expUser))) {
        matches = true;
      } else if (first.isNotEmpty && (expUser.contains(first) || first.contains(expUser))) {
        matches = true;
      }

      if (matches) {
        total += exp.amount;
      }
    }
    return total;
  }

  static Future<UserModel?> getCurrentUser() async {
    final rawName = await AuthService.getCurrentUsername();
    final cleanInput = rawName.trim().toLowerCase();
    final users = await getUsers();

    for (var u in users) {
      if (u.email.toLowerCase() == cleanInput || u.username.toLowerCase() == cleanInput) {
        return u;
      }
    }
    return users.isNotEmpty ? users.first : null;
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

  // --- CATEGORIES ---
  static Future<List<CategoryModel>> getCategories() async {
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/categories/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List && results.isNotEmpty) {
            return (results).map((i) => CategoryModel.fromJson(i)).toList();
          }
        }
      } catch (_) {}
    }
    return [
      CategoryModel(id: 1, name: 'Software Tools', type: 'EXPENSE', icon: 'computer', color: '#8B5CF6'),
      CategoryModel(id: 2, name: 'AI Subscriptions', type: 'EXPENSE', icon: 'psychology', color: '#EC4899'),
      CategoryModel(id: 3, name: 'Travel & Transport', type: 'EXPENSE', icon: 'directions_car', color: '#2563EB'),
      CategoryModel(id: 4, name: 'Office Supplies', type: 'EXPENSE', icon: 'shopping_bag', color: '#F59E0B'),
      CategoryModel(id: 5, name: 'Fuel', type: 'EXPENSE', icon: 'local_gas_station', color: '#10B981'),
    ];
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
    if (_expensesLoaded && _storedExpenses.isNotEmpty) return;
    _expensesLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('saved_expenses');
      if (savedStr != null && savedStr.isNotEmpty) {
        final List dynamicList = jsonDecode(savedStr);
        final loaded = dynamicList.map((i) => ExpenseModel.fromJson(Map<String, dynamic>.from(i))).toList();
        _storedExpenses.clear();
        _storedExpenses.addAll(loaded);
        return;
      }
    } catch (_) {}
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
            final fetchedIds = fetched.map((e) => e.id).toSet();
            final localOnly = _storedExpenses.where((e) => !fetchedIds.contains(e.id)).toList();
            _storedExpenses.clear();
            _storedExpenses.addAll([...localOnly, ...fetched]);
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

    final catName = categoryId == 1
        ? 'Travel & Transport'
        : categoryId == 2
            ? 'Meals & Entertainment'
            : categoryId == 3
                ? 'Office Supplies'
                : 'Software & Tools';

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}, $timeStr';

    final currentUser = await getCurrentUser();
    final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
    final newExp = ExpenseModel(
      id: newId,
      title: title,
      amount: amount,
      categoryId: categoryId,
      categoryName: catName,
      dateTime: dateTime ?? date ?? dateStr,
      status: 'PENDING',
      description: note ?? description ?? '',
      userName: currentUser?.fullName ?? 'Current Employee',
    );

    _storedExpenses.insert(0, newExp);
    await _saveExpensesToPrefs();

    // Update currentUser usedAmount & remainingAmount
    if (currentUser != null) {
      final userIdx = _storedUsers.indexWhere((u) => u.id == currentUser.id || u.username == currentUser.username);
      if (userIdx != -1) {
        final u = _storedUsers[userIdx];
        final newUsed = u.usedAmount + amount;
        final newRem = (u.allocatedAmount - newUsed).clamp(0.0, double.infinity);
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
          usedAmount: newUsed,
          remainingAmount: newRem,
        );
      }
    }

    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/expenses/');
      try {
        await http.post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'title': title,
            'amount': amount,
            'category': categoryId,
            'date': date ?? dateTime ?? dateStr,
            'note': note ?? description ?? '',
          }),
        ).timeout(const Duration(milliseconds: 2000));
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String categoryName,
    String? status,
  }) async {
    await _ensureExpensesLoaded();

    final idx = _storedExpenses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final existing = _storedExpenses[idx];
      _storedExpenses[idx] = ExpenseModel(
        id: existing.id,
        title: title,
        amount: amount,
        categoryId: existing.categoryId,
        categoryName: categoryName,
        dateTime: existing.dateTime,
        status: status ?? existing.status,
        description: existing.description,
        userName: existing.userName,
      );
      await _saveExpensesToPrefs();
    }

    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/expenses/$id/');
      try {
        await http.patch(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'title': title,
            'amount': amount,
            'category_name': categoryName,
            if (status != null) 'status': status,
          }),
        ).timeout(const Duration(milliseconds: 2000));
      } catch (_) {}
    }
    return true;
  }

  static Future<bool> deleteExpense(int expenseId) async {
    await _ensureExpensesLoaded();
    _storedExpenses.removeWhere((e) => e.id == expenseId);
    await _saveExpensesToPrefs();
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/expenses/$expenseId/');
      try {
        await http.delete(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
      } catch (_) {}
    }
    return true;
  }

  // --- APPROVAL ACTIONS ---
  static Future<bool> submitApprovalAction(int id, String type, String action) async {
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/approvals/$id/');
      try {
        final response = await http.post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({'action': action, 'type': type}),
        ).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
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

    final totalSpentFinal = totalExpensesSum > 0 ? totalExpensesSum : users.fold(0.0, (s, u) => s + u.usedAmount);
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
      for (final hostUrl in AuthService.candidateBaseUrls) {
        final url = Uri.parse('$hostUrl/dashboards/employee/');
        try {
          final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
          if (response.statusCode == 200) {
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

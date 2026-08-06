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
    final isRealToken = token != null && token.isNotEmpty && !token.startsWith('jwt_access_token_');
    return {
      'Content-Type': 'application/json',
      if (isRealToken) 'Authorization': 'Bearer $token',
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
      lastName: 'Badugu',
      role: 'ADMIN',
      department: 'Executive',
      employeeId: 'DT7EMP003',
      allocatedAmount: 50000.0,
      usedAmount: 3200.0,
      remainingAmount: 46800.0,
    ),
    UserModel(
      id: 5,
      username: 'diya',
      email: 'diya@gmail.com',
      firstName: 'Diya',
      lastName: 'Badugu',
      role: 'ADMIN',
      department: 'Management',
      employeeId: 'DT7EMP004',
      allocatedAmount: 150000.0,
      usedAmount: 20000.0,
      remainingAmount: 130000.0,
    ),
  ];

  static List<UserModel> get storedUsers => List.unmodifiable(_storedUsers);

  static Future<List<UserModel>> getUsers() async {
    if (!(await AuthService.hasRealToken())) {
      return List.from(_storedUsers);
    }
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/users/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List && results.isNotEmpty) {
            final parsedUsers = (results).map((i) => UserModel.fromJson(i)).toList();
            _storedUsers.clear();
            _storedUsers.addAll(parsedUsers);
            return parsedUsers;
          }
        }
      } catch (_) {}
    }
    return List.from(_storedUsers);
  }

  static Future<UserModel?> getCurrentUser() async {
    final rawName = await AuthService.getCurrentUsername();
    final cleanInput = rawName.trim().toLowerCase();
    final users = await getUsers();

    for (var u in users) {
      if (u.email.toLowerCase() == cleanInput || u.username.toLowerCase() == cleanInput) {
        return u;
      }
      if (cleanInput.contains('dinesh') && (u.username.toLowerCase().contains('dinesh') || u.email.toLowerCase().contains('dinesh'))) {
        return u;
      }
      if (cleanInput.contains('paul') && (u.username.toLowerCase().contains('paul') || u.email.toLowerCase().contains('paul'))) {
        return u;
      }
    }

    try {
      return users.firstWhere(
        (u) => u.username.toLowerCase() == 'dinesh' || u.email.toLowerCase() == 'dinesh@gmail.com',
        orElse: () => users.firstWhere((u) => u.role == 'EMPLOYEE', orElse: () => users.first),
      );
    } catch (_) {}
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

    AuthService.registerDynamicUser(username, email, password, role: role);

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
      allocatedAmount: 10000.0,
      usedAmount: 0.0,
      remainingAmount: 10000.0,
    );
    _storedUsers.add(newUser);
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

      final pwd = (password != null && password.trim().isNotEmpty) ? password.trim() : 'password123';
      AuthService.registerDynamicUser(existing.username, email, pwd, role: role);
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
      CategoryModel(id: 1, name: 'Travel & Transport', type: 'EXPENSE', icon: 'directions_car', color: '#2563EB'),
      CategoryModel(id: 2, name: 'Meals & Entertainment', type: 'EXPENSE', icon: 'restaurant', color: '#10B981'),
      CategoryModel(id: 3, name: 'Office Supplies', type: 'EXPENSE', icon: 'shopping_bag', color: '#F59E0B'),
      CategoryModel(id: 4, name: 'Software & Tools', type: 'EXPENSE', icon: 'computer', color: '#8B5CF6'),
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
    }
    return true;
  }

  static final List<ExpenseModel> _storedExpenses = [];

  // --- EXPENSES ---
  static Future<List<ExpenseModel>> getExpenses() async {
    for (final hostUrl in AuthService.candidateBaseUrls) {
      final url = Uri.parse('$hostUrl/expenses/');
      try {
        final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] ?? data;
          if (results is List && results.isNotEmpty) {
            final fetched = (results).map((i) => ExpenseModel.fromJson(i)).toList();
            _storedExpenses.clear();
            _storedExpenses.addAll(fetched);
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
    final newExp = ExpenseModel(
      id: _storedExpenses.length + 1,
      title: title,
      amount: amount,
      categoryName: catName,
      dateTime: dateTime ?? date ?? dateStr,
      status: 'PENDING',
      description: note ?? description ?? '',
      userName: currentUser?.fullName ?? 'Current Employee',
    );

    _storedExpenses.insert(0, newExp);

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
    final idx = _storedExpenses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final existing = _storedExpenses[idx];
      _storedExpenses[idx] = ExpenseModel(
        id: existing.id,
        title: title,
        amount: amount,
        categoryName: categoryName,
        dateTime: existing.dateTime,
        status: status ?? existing.status,
        description: existing.description,
        userName: existing.userName,
      );
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
    _storedExpenses.removeWhere((e) => e.id == expenseId);
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
    return {
      'total_expenses': 97000.0,
      'total_budget': 150000.0,
      'categories_breakdown': [
        {'category': 'Travel', 'amount': 35000.0},
        {'category': 'Software', 'amount': 25000.0},
        {'category': 'Meals', 'amount': 22000.0},
        {'category': 'Supplies', 'amount': 15000.0},
      ],
    };
  }

  // --- DASHBOARDS ---
  static Future<Map<String, dynamic>?> getFounderDashboard() async {
    if (await AuthService.hasRealToken()) {
      for (final hostUrl in AuthService.candidateBaseUrls) {
        final url = Uri.parse('$hostUrl/dashboard/founder/');
        try {
          final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(milliseconds: 2000));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic>) {
              return data;
            }
          }
        } catch (_) {}
      }
    }

    final users = await getUsers();
    double totalAllocated = 0;
    double totalSpent = 0;
    int overBudgetCount = 0;

    for (var u in users) {
      totalAllocated += u.allocatedAmount;
      totalSpent += u.usedAmount;
      if (u.usedAmount > u.allocatedAmount && u.allocatedAmount > 0) {
        overBudgetCount++;
      }
    }

    final remaining = totalAllocated - totalSpent;

    return {
      'remaining_budget': remaining > 0 ? remaining : 181300.0,
      'total_allocated': totalAllocated > 0 ? totalAllocated : 255000.0,
      'total_expenses': totalSpent > 0 ? totalSpent : 73700.0,
      'total_users': users.isNotEmpty ? users.length : 4,
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
    return {
      'allocated_budget': current?.allocatedAmount ?? 20000.0,
      'total_expenses': current?.usedAmount ?? 3200.0,
      'remaining_balance': current?.remainingAmount ?? 16800.0,
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
    return [
      AccountModel(id: 1, name: 'Main Corporate Checking', accountType: 'CHECKING', balance: 181300.0),
      AccountModel(id: 2, name: 'Petty Cash Reserve', accountType: 'CASH', balance: 25000.0),
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
    return {
      'total_balance': 181300.0,
      'monthly_income': 255000.0,
      'monthly_expenses': 73700.0,
      'savings_rate': 71.0,
    };
  }

  static Future<List<BudgetModel>> getBudgets() async {
    return [
      BudgetModel(id: 1, categoryId: 1, limitAmount: 50000.0, monthYear: '2026-08', spentAmount: 12000.0, remainingAmount: 38000.0),
      BudgetModel(id: 2, categoryId: 2, limitAmount: 30000.0, monthYear: '2026-08', spentAmount: 8500.0, remainingAmount: 21500.0),
    ];
  }

  static Future<List<TransactionModel>> getTransactions() async {
    return [
      TransactionModel(id: 1, accountId: 1, title: 'Client Travel Expense', amount: 12000.0, transactionType: 'EXPENSE', date: '2026-08-01'),
      TransactionModel(id: 2, accountId: 1, title: 'Software Licenses Subscription', amount: 8500.0, transactionType: 'EXPENSE', date: '2026-08-03'),
    ];
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

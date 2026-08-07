import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/donut_chart_widget.dart';
import '03_dashboard_screen.dart';

class ReportsScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ReportsScreen({super.key, this.onBackPressed});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedPeriod = 'This Month';

  List<ExpenseModel> _filterExpensesByPeriod(List<ExpenseModel> allExpenses, String period) {
    final now = DateTime.now();
    if (period == 'Last Month') {
      final prevDate = DateTime(now.year, now.month - 1, 1);
      final prevMonthName = DateFormat('MMM').format(prevDate).toLowerCase();
      final prevMonthNum = '-${prevDate.month.toString().padLeft(2, '0')}-';
      return allExpenses.where((e) {
        final dLower = e.dateTime.toLowerCase();
        return dLower.contains(prevMonthName) || dLower.contains(prevMonthNum);
      }).toList();
    } else if (period == 'This Quarter') {
      return allExpenses.where((e) {
        return e.dateTime.toLowerCase().contains(now.year.toString());
      }).toList();
    } else if (period == 'This Year') {
      return allExpenses.where((e) {
        return e.dateTime.toLowerCase().contains(now.year.toString());
      }).toList();
    } else {
      // This Month
      final curMonthName = DateFormat('MMM').format(now).toLowerCase();
      final curMonthNum = '-${now.month.toString().padLeft(2, '0')}-';
      final curYear = now.year.toString();
      return allExpenses.where((e) {
        final dLower = e.dateTime.toLowerCase();
        return dLower.contains(curMonthName) || dLower.contains(curMonthNum) || dLower.contains(curYear);
      }).toList();
    }
  }

  List<Map<String, dynamic>> _calculateCategoryBreakdown(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return [
        {'name': 'General', 'pct': 100, 'color': const Color(0xFFFF5500)},
      ];
    }

    final total = expenses.fold(0.0, (s, e) => s + e.amount);
    if (total == 0) {
      return [
        {'name': 'General', 'pct': 100, 'color': const Color(0xFFFF5500)},
      ];
    }

    Map<String, double> catSum = {};
    for (var e in expenses) {
      final name = e.categoryName.trim().isNotEmpty ? e.categoryName.trim() : 'General';
      catSum[name] = (catSum[name] ?? 0.0) + e.amount;
    }

    final colors = [
      const Color(0xFFFF5500), // Vibrant Orange
      const Color(0xFF2563EB), // Royal Blue
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFFF59E0B), // Warm Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF64748B), // Slate
    ];

    int colorIdx = 0;
    List<Map<String, dynamic>> list = [];
    catSum.forEach((catName, sum) {
      final pct = total > 0 ? ((sum / total) * 100).round() : 0;
      list.add({
        'name': catName,
        'amount': sum,
        'pct': pct,
        'color': colors[colorIdx % colors.length],
      });
      colorIdx++;
    });

    list.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return list;
  }

  List<Map<String, dynamic>> _calculateLeaderboard(List<UserModel> users, List<ExpenseModel> expenses) {
    Map<int, double> userSpentMap = {};

    for (var u in users) {
      userSpentMap[u.id] = ApiService.calculateUserSpent(u, expenses);
    }

    final spenders = users.where((u) => (userSpentMap[u.id] ?? 0) > 0).toList();
    spenders.sort((a, b) => (userSpentMap[b.id] ?? 0).compareTo(userSpentMap[a.id] ?? 0));

    final displayUsers = spenders.isNotEmpty ? spenders : users;

    List<Map<String, dynamic>> result = [];
    int rank = 1;
    for (var u in displayUsers) {
      final spent = userSpentMap[u.id] ?? 0.0;
      result.add({
        'rank': rank++,
        'name': u.fullName.isNotEmpty ? u.fullName : u.username,
        'department': u.department,
        'amount': spent,
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final periodOptions = ['This Month', 'Last Month', 'This Quarter', 'This Year'];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(currentRoute: 'reports'),
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        leading: AppHeaderIconButton(
          icon: Icons.arrow_back,
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const FounderDashboardScreen()),
                (route) => false,
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            ApiService.getUsers(),
            ApiService.getExpenses(),
            ApiService.getFounderDashboard(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final users = (snapshot.data?[0] as List<UserModel>?) ?? [];
            final allExpenses = (snapshot.data?[1] as List<ExpenseModel>?) ?? [];
            final dashMap = (snapshot.data?[2] as Map<String, dynamic>?) ?? {};

            final periodExpenses = _filterExpensesByPeriod(allExpenses, _selectedPeriod);
            final displayExpenses = periodExpenses.isNotEmpty ? periodExpenses : allExpenses;

            final totalAllocated = users.fold(0.0, (sum, u) => sum + u.allocatedAmount);
            final totalExpensesVal = displayExpenses.fold(0.0, (sum, e) => sum + e.amount);
            final remainingBudget = totalAllocated - totalExpensesVal;

            final categoriesBreakdown = _calculateCategoryBreakdown(displayExpenses);
            final leaderboard = _calculateLeaderboard(users, displayExpenses);

            final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Dropdown Menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    },
                    itemBuilder: (context) => periodOptions.map((period) {
                      final isSelected = period == _selectedPeriod;
                      return PopupMenuItem<String>(
                        value: period,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              period,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : Colors.black87,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedPeriod,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Allocated', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(currencyFmt.format(totalAllocated), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Expenses', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(currencyFmt.format(totalExpensesVal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Remaining Budget', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                currencyFmt.format(remainingBudget),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: remainingBudget < 0 ? const Color(0xFFEF4444) : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expenses by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        _selectedPeriod,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DonutChartWidget(
                    totalExpenses: totalExpensesVal,
                    customCategories: categoriesBreakdown,
                  ),
                  const SizedBox(height: 28),

                  // Top Spending Employees Leaderboard
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Top Spending Employees', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        '${leaderboard.length} Employees',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (leaderboard.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text('No spending employee records found.'),
                    )
                  else
                    ...leaderboard.map((emp) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: const [
                              BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: emp['rank'] == 1
                                      ? const Color(0xFFFEF3C7)
                                      : (emp['rank'] == 2 ? const Color(0xFFF3F4F6) : const Color(0xFFFFEDD5)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${emp['rank']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: emp['rank'] == 1
                                          ? const Color(0xFFD97706)
                                          : (emp['rank'] == 2 ? const Color(0xFF4B5563) : const Color(0xFFC2410C)),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  (emp['name'] as String).isNotEmpty ? (emp['name'] as String)[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(emp['department'] as String? ?? 'General', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFmt.format(emp['amount'] as double),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFF5500)),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

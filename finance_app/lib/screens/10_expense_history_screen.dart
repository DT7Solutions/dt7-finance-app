import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/status_badge.dart';
import '03_dashboard_screen.dart';
import '06_employee_dashboard_screen.dart';
import '09_expense_detail_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  List<ExpenseModel> _history = [];
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';

  final List<String> _periodOptions = [
    'This Month',
    'Last Month',
    'This Year',
    'All Time',
  ];

  final List<String> _categoryOptions = [
    'All',
    'Software Tools',
    'AI Subscriptions',
    'Purchase of Domain or Server',
    'Cloud Infrastructure & Hosting',
    'API & Third-Party Services',
    'Hardware & Dev Peripherals',
    'Travel & Client Visits',
    'Office Supplies & Utilities',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final currentUser = await ApiService.getCurrentUser();
      final list = await ApiService.getExpenses();

      final userExpenses = list.where((e) => ApiService.isExpenseOwnedByUser(e, currentUser)).toList();

      if (mounted) {
        setState(() {
          _history = userExpenses;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 16.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter History',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Category:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categoryOptions.map((cat) {
                          final isSel = _categoryFilter == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.primary : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setSheetState(() => _categoryFilter = cat);
                              setState(() => _categoryFilter = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'APPROVED', 'PENDING', 'REJECTED'].map((st) {
                          final isSel = _statusFilter == st;
                          return ChoiceChip(
                            label: Text(st),
                            selected: isSel,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.primary : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setSheetState(() => _statusFilter = st);
                              setState(() => _statusFilter = st);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Apply Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var rawList = List<ExpenseModel>.from(_history);
    final now = DateTime.now();

    // Period Filter logic
    if (_selectedPeriod == 'This Month') {
      final curMonthName = DateFormat('MMM').format(now).toLowerCase();
      final curMonthNum = '-${now.month.toString().padLeft(2, '0')}-';
      final curYear = now.year.toString();
      rawList = rawList.where((e) {
        final dLower = e.dateTime.toLowerCase();
        return dLower.contains(curMonthName) || dLower.contains(curMonthNum) || dLower.contains(curYear);
      }).toList();
    } else if (_selectedPeriod == 'Last Month') {
      final prevDate = DateTime(now.year, now.month - 1, 1);
      final prevMonthName = DateFormat('MMM').format(prevDate).toLowerCase();
      final prevMonthNum = '-${prevDate.month.toString().padLeft(2, '0')}-';
      rawList = rawList.where((e) {
        final dLower = e.dateTime.toLowerCase();
        return dLower.contains(prevMonthName) || dLower.contains(prevMonthNum);
      }).toList();
    } else if (_selectedPeriod == 'This Year') {
      final curYear = now.year.toString();
      rawList = rawList.where((e) {
        return e.dateTime.toLowerCase().contains(curYear);
      }).toList();
    }

    if (_categoryFilter != 'All') {
      rawList = rawList.where((e) => e.categoryName.toLowerCase().contains(_categoryFilter.toLowerCase())).toList();
    }
    if (_statusFilter != 'All') {
      rawList = rawList.where((e) => e.status.toUpperCase() == _statusFilter.toUpperCase()).toList();
    }

    final displayHistory = rawList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        leading: AppHeaderIconButton(
          icon: Icons.arrow_back,
          onPressed: () async {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              return;
            }
            final role = await AuthService.getUserRole();
            if (context.mounted) {
              if (role == 'EMPLOYEE') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen()),
                  (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const FounderDashboardScreen()),
                  (route) => false,
                );
              }
            }
          },
        ),
        actions: [
          AppHeaderIconButton(
            icon: Icons.tune,
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Interactive Period Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    items: _periodOptions.map((period) {
                      final isSel = period == _selectedPeriod;
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(
                          period,
                          style: TextStyle(
                            color: isSel ? AppColors.primary : const Color(0xFF374151),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPeriod = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : displayHistory.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No expense history found',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try selecting "All Time" or changing category filters.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: displayHistory.length,
                            itemBuilder: (ctx, idx) {
                              final item = displayHistory[idx];
                              return InkWell(
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ExpenseDetailScreen(expense: item)),
                                  );
                                  if (res == true) _loadHistory();
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.categoryName} • ${item.formattedDate}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${item.amount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          StatusBadge(status: item.status),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/status_badge.dart';
import '03_dashboard_screen.dart';
import '06_employee_dashboard_screen.dart';
import '07_add_expense_screen.dart';
import '09_expense_detail_screen.dart';

class MyExpensesScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const MyExpensesScreen({super.key, this.onBackPressed});

  @override
  State<MyExpensesScreen> createState() => _MyExpensesScreenState();
}

class _MyExpensesScreenState extends State<MyExpensesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final currentUser = await ApiService.getCurrentUser();
    final list = await ApiService.getExpenses();

    final userExpenses = list.where((e) {
      if (currentUser == null) return false;
      final uName = currentUser.username.trim().toLowerCase();
      final fName = currentUser.fullName.trim().toLowerCase();
      final expUser = e.userName.trim().toLowerCase();

      return (uName.isNotEmpty && expUser == uName) ||
          (fName.isNotEmpty && expUser == fName) ||
          (uName.isNotEmpty && expUser.contains(uName)) ||
          (fName.isNotEmpty && expUser.contains(fName));
    }).toList();

    if (mounted) {
      setState(() {
        _expenses = userExpenses;
        _isLoading = false;
      });
    }
  }

  void _showEditExpenseSheet(BuildContext context, ExpenseModel exp) {
    final titleController = TextEditingController(text: exp.title);
    final amountController = TextEditingController(text: exp.amount.toStringAsFixed(0));
    String selectedCategory = exp.categoryName;
    final categories = [
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
                            'Edit Expense',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Category:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSel = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.primary : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setSheetState(() => selectedCategory = cat);
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
                          onPressed: () async {
                            final newAmount = double.tryParse(amountController.text) ?? exp.amount;
                            final newTitle = titleController.text.trim().isEmpty ? exp.title : titleController.text.trim();
                            await ApiService.updateExpense(
                              id: exp.id,
                              title: newTitle,
                              amount: newAmount,
                              categoryName: selectedCategory,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadExpenses();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Expense updated successfully!'),
                                  backgroundColor: AppColors.approvedGreen,
                                ),
                              );
                            }
                          },
                          child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showDeleteConfirmationDialog(BuildContext context, ExpenseModel exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${exp.title}"? This action cannot be undone.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.deleteExpense(exp.id);
              _loadExpenses();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense deleted successfully!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final categories = [
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
                            'Filter Expenses',
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
                        children: categories.map((cat) {
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
    var rawList = List<ExpenseModel>.from(_expenses);

    if (_categoryFilter != 'All') {
      rawList = rawList.where((e) => e.categoryName.toLowerCase().contains(_categoryFilter.toLowerCase())).toList();
    }
    if (_statusFilter != 'All') {
      rawList = rawList.where((e) => e.status.toUpperCase() == _statusFilter.toUpperCase()).toList();
    }

    final filters = ['All', 'This Month', 'This Week', 'Custom'];
    final displayList = rawList;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(currentRoute: 'expenses'),
      appBar: AppBar(
        title: const Text('My Expenses'),
        leading: AppHeaderIconButton(
          icon: Icons.arrow_back,
          onPressed: () async {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
              return;
            }
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
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
              if (res == true) _loadExpenses();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Filter Horizontal Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((f) {
                    final isSelected = _selectedFilter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Expense Items List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : displayList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No expenses found',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap "+" to submit your first expense claim.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: displayList.length,
                            itemBuilder: (ctx, idx) {
                              final exp = displayList[idx];
                              return InkWell(
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ExpenseDetailScreen(expense: exp)),
                                  );
                                  if (res == true) {
                                    _loadExpenses();
                                  }
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
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    exp.title,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryLight,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    exp.categoryName,
                                                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₹${exp.amount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(exp.dateTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                          Row(
                                            children: [
                                              StatusBadge(status: exp.status),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                                onPressed: () => _showEditExpenseSheet(context, exp),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                onPressed: () => _showDeleteConfirmationDialog(context, exp),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                              ),
                                            ],
                                          ),
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

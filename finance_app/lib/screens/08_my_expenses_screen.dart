import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
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

  bool _isFounder = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final currentUser = await ApiService.getCurrentUser();
    final role = await AuthService.getUserRole();
    final isFounder = (role == 'FOUNDER' || (currentUser != null && currentUser.role == 'FOUNDER'));
    final list = await ApiService.getExpenses();

    final userExpenses = isFounder ? list : list.where((e) => ApiService.isExpenseOwnedByUser(e, currentUser)).toList();

    if (mounted) {
      setState(() {
        _isFounder = isFounder;
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

              if (_isFounder) _buildExpenseBreakdownByUserSection(),

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

  Widget _buildExpenseBreakdownByUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense Breakdown by User',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Who spent the total expenses amount',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _showExpenseBreakdownModal(context),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<dynamic>>(
          future: Future.wait([
            ApiService.getUsers(),
            ApiService.getExpenses(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
              );
            }
            final users = (snapshot.data?[0] as List<UserModel>?) ?? [];
            final allExpenses = (snapshot.data?[1] as List<ExpenseModel>?) ?? [];

            Map<int, List<ExpenseModel>> userExpenseMap = {};
            Map<int, double> userSpentMap = {};

            for (var u in users) {
              final uExpenses = allExpenses.where((e) => ApiService.isExpenseOwnedByUser(e, u)).toList();
              userExpenseMap[u.id] = uExpenses;
              userSpentMap[u.id] = ApiService.calculateUserSpent(u, allExpenses);
            }

            final totalExpensesSum = allExpenses.fold(0.0, (s, e) => s + e.amount);
            final spenders = users.where((u) => (userSpentMap[u.id] ?? 0) > 0).toList();
            spenders.sort((a, b) => (userSpentMap[b.id] ?? 0).compareTo(userSpentMap[a.id] ?? 0));

            final displayUsers = spenders.isNotEmpty ? spenders.take(3).toList() : users.take(3).toList();

            if (displayUsers.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: displayUsers.map((u) {
                final spent = userSpentMap[u.id] ?? 0.0;
                final uExpenses = userExpenseMap[u.id] ?? [];
                final pct = totalExpensesSum > 0 ? ((spent / totalExpensesSum) * 100).toStringAsFixed(0) : '0';
                final isOver = (spent > u.allocatedAmount || u.remainingAmount < 0) && u.allocatedAmount > 0;

                return InkWell(
                  onTap: () => _showExpenseBreakdownModal(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOver ? const Color(0xFFFFF1F2).withOpacity(0.6) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOver ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                        width: isOver ? 1.5 : 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isOver ? const Color(0xFFFEF2F2) : AppColors.primaryLight,
                              child: Text(
                                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isOver ? const Color(0xFFEF4444) : AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${u.department} • ${uExpenses.length} Claims',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${spent.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF5500)),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOver ? const Color(0xFFFEF2F2) : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOver ? '🚨 OVER BUDGET' : '$pct% of expenses',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isOver ? const Color(0xFFEF4444) : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _showExpenseBreakdownModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        String filterUserMode = 'All';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expense Breakdown by User',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Who spent the total expenses amount & their claims',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
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

                        Map<int, List<ExpenseModel>> userExpenseMap = {};
                        Map<int, double> userSpentMap = {};

                        for (var u in users) {
                          final uExpenses = allExpenses.where((e) => ApiService.isExpenseOwnedByUser(e, u)).toList();
                          userExpenseMap[u.id] = uExpenses;
                          userSpentMap[u.id] = ApiService.calculateUserSpent(u, allExpenses);
                        }

                        final totalExpenseAmount = allExpenses.fold(0.0, (s, e) => s + e.amount);

                        List<UserModel> filteredUsers = List.from(users);
                        if (filterUserMode == 'Spenders') {
                          filteredUsers = filteredUsers.where((u) => (userSpentMap[u.id] ?? 0) > 0).toList();
                        } else if (filterUserMode == 'Over Budget') {
                          filteredUsers = filteredUsers.where((u) {
                            final spent = userSpentMap[u.id] ?? 0;
                            return (spent > u.allocatedAmount || u.remainingAmount < 0) && u.allocatedAmount > 0;
                          }).toList();
                        }

                        filteredUsers.sort((a, b) {
                          final spentA = userSpentMap[a.id] ?? 0;
                          final spentB = userSpentMap[b.id] ?? 0;
                          return spentB.compareTo(spentA);
                        });

                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x20FF5500),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TOTAL EXPENSES AMOUNT',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${totalExpenseAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${users.length} Employees',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: ['All', 'Spenders', 'Over Budget'].map((mode) {
                                  final isSel = filterUserMode == mode;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(mode),
                                      selected: isSel,
                                      selectedColor: AppColors.primaryLight,
                                      labelStyle: TextStyle(
                                        color: isSel ? AppColors.primary : Colors.grey.shade700,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setModalState(() => filterUserMode = mode);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Expanded(
                              child: filteredUsers.isEmpty
                                  ? const Center(child: Text('No matching spending records found'))
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (context, idx) {
                                        final u = filteredUsers[idx];
                                        final spent = userSpentMap[u.id] ?? 0.0;
                                        final uExpenses = userExpenseMap[u.id] ?? [];
                                        final pct = totalExpenseAmount > 0 ? ((spent / totalExpenseAmount) * 100).toStringAsFixed(0) : '0';
                                        final isOver = (spent > u.allocatedAmount || u.remainingAmount < 0) && u.allocatedAmount > 0;

                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: isOver ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                                              width: isOver ? 1.5 : 1.0,
                                            ),
                                          ),
                                          color: isOver ? const Color(0xFFFFF1F2).withOpacity(0.5) : Colors.grey.shade50,
                                          child: ExpansionTile(
                                            shape: const Border(),
                                            leading: CircleAvatar(
                                              backgroundColor: isOver ? const Color(0xFFFEF2F2) : AppColors.primaryLight,
                                              child: Text(
                                                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isOver ? const Color(0xFFEF4444) : AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    u.fullName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                ),
                                                Text(
                                                  '₹${spent.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    color: Color(0xFFFF5500),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Row(
                                              children: [
                                                Text(
                                                  '${u.department} • ${uExpenses.length} Claims',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isOver ? const Color(0xFFFEF2F2) : AppColors.primaryLight,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    isOver ? '🚨 OVER BUDGET' : '$pct% of expenses',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: isOver ? const Color(0xFFEF4444) : AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            children: [
                                              if (uExpenses.isEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.all(12.0),
                                                  child: Text(
                                                    'Allocated budget spent without individual claims submitted.',
                                                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                                  ),
                                                )
                                              else
                                                ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: uExpenses.length,
                                                  itemBuilder: (ctx, eIdx) {
                                                    final exp = uExpenses[eIdx];
                                                    return Container(
                                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                      padding: const EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: Colors.grey.shade200),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(exp.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                                                Text('${exp.categoryName} • ${exp.dateTime}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                                              ],
                                                            ),
                                                          ),
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              Text('₹${exp.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                              StatusBadge(status: exp.status),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

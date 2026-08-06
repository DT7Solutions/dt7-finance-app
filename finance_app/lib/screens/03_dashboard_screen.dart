import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/app_notification_icon_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/donut_chart_widget.dart';
import '02_login_screen.dart';
import '04_users_screen.dart';
import '05_allocate_budget_screen.dart';
import '08_my_expenses_screen.dart';
import '11_approvals_screen.dart';
import '13_reports_screen.dart';
import '14_activity_log_screen.dart';
import '15_profile_screen.dart';

class FounderDashboardScreen extends StatefulWidget {
  final bool showBreakdownOnLoad;

  const FounderDashboardScreen({super.key, this.showBreakdownOnLoad = false});

  @override
  State<FounderDashboardScreen> createState() => _FounderDashboardScreenState();
}

class _FounderDashboardScreenState extends State<FounderDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  String _selectedFilter = 'This Month';
  Map<String, dynamic>? _dashboardData;
  List<ExpenseModel> _allExpenses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    if (widget.showBreakdownOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBudgetSpendingBreakdownModal(context);
      });
    }
  }

  final List<Map<String, dynamic>> _notifications = [];

  int get _unreadCount => _notifications.where((n) => !n['isRead']).length;

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
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
                        Row(
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_unreadCount new',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            _markAllAsRead();
                            setModalState(() {});
                          },
                          child: const Text(
                            'Mark all as read',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _notifications.isEmpty
                        ? Center(
                            child: Text(
                              'No notifications',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              final isUnread = !(item['isRead'] as bool);

                              IconData itemIcon;
                              Color iconBg;
                              Color iconColor;

                              switch (item['type']) {
                                case 'warning':
                                  itemIcon = Icons.warning_amber_rounded;
                                  iconBg = const Color(0xFFFEF2F2);
                                  iconColor = const Color(0xFFEF4444);
                                  break;
                                case 'expense':
                                  itemIcon = Icons.receipt_long_rounded;
                                  iconBg = const Color(0xFFEFF6FF);
                                  iconColor = const Color(0xFF3B82F6);
                                  break;
                                case 'user':
                                  itemIcon = Icons.person_add_rounded;
                                  iconBg = const Color(0xFFECFDF5);
                                  iconColor = const Color(0xFF10B981);
                                  break;
                                default:
                                  itemIcon = Icons.info_outline_rounded;
                                  iconBg = const Color(0xFFFFF7ED);
                                  iconColor = AppColors.primary;
                              }

                              return InkWell(
                                onTap: () {
                                  _markAsRead(item['id'] as int);
                                  setModalState(() {});
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isUnread ? Colors.orange.shade50.withValues(alpha: 0.3) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isUnread ? const Color(0xFFFFD4C0) : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: iconBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(itemIcon, color: iconColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item['title'] as String,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                      color: const Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  item['time'] as String,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['message'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
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
            );
          },
        );
      },
    );
  }

  Future<void> _loadDashboard() async {
    final data = await ApiService.getFounderDashboard();
    final expenses = await ApiService.getExpenses();
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _allExpenses = expenses;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprovalAction(ExpenseModel exp, String action) async {
    final statusStr = action == 'approve' ? 'APPROVED' : 'REJECTED';
    await ApiService.updateExpense(
      id: exp.id,
      title: exp.title,
      amount: exp.amount,
      categoryName: exp.categoryName,
      status: statusStr,
    );
    await _loadDashboard();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense ${action == 'approve' ? 'approved' : 'rejected'} successfully!'),
          backgroundColor: action == 'approve' ? AppColors.approvedGreen : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPendingApprovalsSection(List<ExpenseModel> pendingExpenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Pending Approvals Queue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: pendingExpenses.isNotEmpty ? const Color(0xFFFFF5ED) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pendingExpenses.isNotEmpty ? const Color(0xFFFFD4C0) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '${pendingExpenses.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: pendingExpenses.isNotEmpty ? const Color(0xFFFF5500) : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApprovalsScreen()),
              ).then((_) => _loadDashboard()),
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
        if (pendingExpenses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.approvedGreen, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Approval Queue Clear!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                      ),
                      Text(
                        'No pending expense claims require review right now.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingExpenses.length > 3 ? 3 : pendingExpenses.length,
            itemBuilder: (context, index) {
              final exp = pendingExpenses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                exp.userName.isNotEmpty ? exp.userName[0].toUpperCase() : 'E',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                                ),
                                Text(
                                  '${exp.userName} • ${exp.categoryName}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '₹${exp.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                              label: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _handleApprovalAction(exp, 'reject'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.approvedGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.check, size: 14, color: Colors.white),
                              label: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _handleApprovalAction(exp, 'approve'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formatted = formatter.format(absAmount);
    return isNegative ? '- $formatted' : formatted;
  }

  void _showAddUserModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedRole = 'EMPLOYEE';
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                        'Create New User Account',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Neha Singh',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'e.g. neha@dt7.agency',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'User Role',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'EMPLOYEE', child: Text('Employee')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin / Founder')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'User Password',
                      hintText: 'Create a custom password for user',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setModalState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Initial Allocated Amount (₹)',
                      hintText: 'Enter amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: CustomButton(
                      text: 'Create User Account',
                      onPressed: () async {
                        final fullName = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final password = passwordCtrl.text.trim();

                        if (fullName.isEmpty || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter full name and email address'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a password for the new user'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final uname = email.split('@').first.replaceAll('.', '_');

                        await ApiService.addUser(
                          username: uname,
                          email: email,
                          password: password,
                          fullName: fullName,
                          role: selectedRole,
                        );

                        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        if (amount > 0) {
                          final users = await ApiService.getUsers();
                          final createdUser = users.firstWhere(
                            (u) => u.email == email || u.username == uname,
                            orElse: () => users.last,
                          );
                          await ApiService.allocateBudget(employeeId: createdUser.id, amount: amount);
                        }

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _loadDashboard();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('User "$fullName" created with password "$password"!'),
                              duration: const Duration(seconds: 5),
                              backgroundColor: AppColors.approvedGreen,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBudgetSpendingBreakdownModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        String filterMode = 'All';

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
                              'Budget Spending Breakdown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Who spent the budget & who spent over budget',
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
                    child: FutureBuilder<List<UserModel>>(
                      future: ApiService.getUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final users = snapshot.data ?? [];
                        final overBudgetUsers = users.where((u) => (u.usedAmount > u.allocatedAmount || u.remainingAmount < 0) && u.allocatedAmount > 0).toList();
                        final displayUsers = filterMode == 'OverBudget' ? overBudgetUsers : users;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text('All Users (${users.length})'),
                                    selected: filterMode == 'All',
                                    selectedColor: AppColors.primaryLight,
                                    labelStyle: TextStyle(
                                      color: filterMode == 'All' ? AppColors.primary : Colors.black87,
                                      fontWeight: filterMode == 'All' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (_) => setModalState(() => filterMode = 'All'),
                                  ),
                                  const SizedBox(width: 10),
                                  ChoiceChip(
                                    label: Text('Over Budget (${overBudgetUsers.length})'),
                                    selected: filterMode == 'OverBudget',
                                    selectedColor: const Color(0xFFFEF2F2),
                                    labelStyle: TextStyle(
                                      color: filterMode == 'OverBudget' ? const Color(0xFFEF4444) : Colors.black87,
                                      fontWeight: filterMode == 'OverBudget' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    avatar: overBudgetUsers.isNotEmpty
                                        ? const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444))
                                        : null,
                                    onSelected: (_) => setModalState(() => filterMode = 'OverBudget'),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: displayUsers.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            filterMode == 'OverBudget' ? Icons.check_circle_outline : Icons.people_outline,
                                            size: 48,
                                            color: filterMode == 'OverBudget' ? AppColors.approvedGreen : Colors.grey,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            filterMode == 'OverBudget' ? 'No users over budget!' : 'No users found',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            filterMode == 'OverBudget' ? 'All users are within their allocated limits.' : '',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      itemCount: displayUsers.length,
                                      itemBuilder: (context, index) {
                                        final u = displayUsers[index];
                                        final isOver = (u.usedAmount > u.allocatedAmount || u.remainingAmount < 0) && u.allocatedAmount > 0;
                                        final remainingRem = u.allocatedAmount - u.usedAmount;
                                        final progress = u.allocatedAmount > 0 ? (u.usedAmount / u.allocatedAmount).clamp(0.0, 1.0) : 0.0;
                                        final percentText = u.allocatedAmount > 0 ? '${((u.usedAmount / u.allocatedAmount) * 100).round()}%' : '0%';

                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 14),
                                          elevation: 0.5,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: isOver ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                                              width: isOver ? 1.5 : 1.0,
                                            ),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isOver ? const Color(0xFFFFF1F2).withOpacity(0.5) : Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 20,
                                                          backgroundColor: isOver ? const Color(0xFFFEF2F2) : AppColors.primaryLight,
                                                          child: Text(
                                                            u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: isOver ? const Color(0xFFEF4444) : AppColors.primary,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              u.fullName,
                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                                                            ),
                                                            Text(
                                                              '${u.department} • ${u.employeeId}',
                                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: isOver ? const Color(0xFFFEF2F2) : AppColors.approvedGreen.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: isOver ? const Color(0xFFFCA5A5) : AppColors.approvedGreen.withOpacity(0.3),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        isOver ? '🚨 OVER BUDGET' : 'WITHIN BUDGET',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: isOver ? const Color(0xFFEF4444) : AppColors.approvedGreen,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 14),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Allocated', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                        const SizedBox(height: 2),
                                                        Text('₹${u.allocatedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        const Text('Used Budget', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                        const SizedBox(height: 2),
                                                        Text('₹${u.usedAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isOver ? const Color(0xFFEF4444) : Colors.black87)),
                                                      ],
                                                    ),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(isOver ? 'Deficit' : 'Remaining', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          _formatCurrency(remainingRem),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            color: remainingRem < 0 ? const Color(0xFFEF4444) : AppColors.approvedGreen,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: LinearProgressIndicator(
                                                          value: progress,
                                                          minHeight: 6,
                                                          backgroundColor: Colors.grey.shade100,
                                                          valueColor: AlwaysStoppedAnimation<Color>(
                                                            isOver ? const Color(0xFFEF4444) : (progress > 0.8 ? Colors.orange : AppColors.primary),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(percentText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOver ? const Color(0xFFEF4444) : Colors.grey.shade700)),
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
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                        label: const Text('Reallocate / Adjust Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 2);
                        },
                      ),
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

  Widget _buildFounderTab() {
    if (_isLoading && _dashboardData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final remaining = (_dashboardData?['remaining_budget'] as double?) ?? 0.0;
    final allocated = (_dashboardData?['total_allocated'] as double?) ?? 0.0;
    final expenses = (_dashboardData?['total_expenses'] as double?) ?? 0.0;
    final users = (_dashboardData?['total_users'] as int?) ?? 0;
    final overBudget = (_dashboardData?['over_budget'] as int?) ?? 0;
    final isNegative = remaining < 0;
    final pendingExpenses = _allExpenses.where((e) => e.isPending).toList();

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 1. Top Header Bar (Hamburger Menu, Dashboard Title, Notification Bell)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppHeaderIconButton(
                icon: Icons.menu,
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              AppNotificationIconButton(
                unreadCount: _unreadCount,
                onTap: () => _showNotificationsModal(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Profile Greeting Row + Month Dropdown Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.asset(
                          'assets/images/founder_avatar.png',
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => CircleAvatar(
                            radius: 23,
                            backgroundColor: AppColors.primaryLight,
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'Hello, Founder ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text('👋', style: TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Month Filter Pill Dropdown
              _buildMonthDropdown(),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Hero Card - Total Balance (Navigates to Budget Spending Breakdown)
          InkWell(
            onTap: () => _showBudgetSpendingBreakdownModal(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isNegative ? const Color(0xFFFEF2F2) : const Color(0xFFFFF5ED), // Red tint when negative
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isNegative ? const Color(0xFFFCA5A5) : const Color(0xFFFFD4C0),
                  width: isNegative ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isNegative ? const Color(0xFF991B1B) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(remaining),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isNegative ? const Color(0xFFEF4444) : const Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNegative ? 'Remaining Budget (Deficit)' : 'Remaining Budget',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isNegative ? const Color(0xFFDC2626) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isNegative ? const Color(0xFFFEF2F2) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isNegative ? const Color(0xFFEF4444) : const Color(0xFFFFA066),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isNegative
                          ? const Icon(Icons.trending_down, size: 26, color: Color(0xFFEF4444))
                          : const StatTrendIcon(
                              size: 26,
                              color: Color(0xFFFF5500),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. 2x2 Metric Cards Grid with Small Colored Icons & Functional Taps
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total Allocated',
                  amount: _formatCurrency(allocated),
                  iconData: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Total Expenses',
                  amount: _formatCurrency(expenses),
                  iconData: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFFFF5500),
                  iconBgColor: const Color(0xFFFFF5ED),
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total Users',
                  amount: '$users',
                  iconData: Icons.people_outline,
                  iconColor: const Color(0xFF10B981),
                  iconBgColor: const Color(0xFFECFDF5),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Over Budget',
                  amount: '$overBudget',
                  iconData: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFEF4444),
                  iconBgColor: const Color(0xFFFEF2F2),
                  onTap: () => _showBudgetSpendingBreakdownModal(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. Quick Action Row: Add User & Allocate Budget
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Add New User',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => _showAddUserModal(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Allocate Budget',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6. Pending Approvals Queue Section
          _buildPendingApprovalsSection(pendingExpenses),
          const SizedBox(height: 20),

          // 7. Expenses Overview Header + Donut Chart (Functional Header Tap)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => _currentIndex = 4),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                  child: Row(
                    children: const [
                      Text(
                        'Expenses Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF1F2937)),
                    ],
                  ),
                ),
              ),
              _buildMonthDropdown(),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _currentIndex = 4),
            borderRadius: BorderRadius.circular(16),
            child: DonutChartWidget(totalExpenses: expenses),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

  String get _currentRouteName {
    switch (_currentIndex) {
      case 0:
        return '';
      case 1:
        return 'users';
      case 2:
        return 'allocate';
      case 3:
        return 'expenses';
      case 4:
        return 'reports';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildFounderTab(),
      UsersScreen(onBackPressed: () => setState(() => _currentIndex = 0)),
      AllocateBudgetScreen(onBackPressed: () => setState(() => _currentIndex = 0)),
      MyExpensesScreen(onBackPressed: () => setState(() => _currentIndex = 0)),
      ReportsScreen(onBackPressed: () => setState(() => _currentIndex = 0)),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: AppDrawer(
          currentRoute: _currentRouteName,
          onSelectTab: (idx) => setState(() => _currentIndex = idx),
          onShowBudgetBreakdown: () => _showBudgetSpendingBreakdownModal(context),
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                label: const Text('Add User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => _showAddUserModal(context),
              )
            : null,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
        ),
        bottomNavigationBar: _buildCustomBottomNavBar(),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    final options = ['This Month', 'Last Month', 'This Quarter', 'This Year'];
    return PopupMenuButton<String>(
      onSelected: (val) {
        setState(() {
          _selectedFilter = val;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 36),
      itemBuilder: (context) => options.map((opt) {
        final isSelected = opt == _selectedFilter;
        return PopupMenuItem<String>(
          value: opt,
          child: Text(
            opt,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : const Color(0xFF1F2937),
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_selectedFilter ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1F2937)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBottomNavBar() {
    final items = [
      {'label': 'Dashboard', 'icon': Icons.home_rounded, 'inactiveIcon': Icons.home_outlined},
      {'label': 'Users', 'icon': Icons.people_rounded, 'inactiveIcon': Icons.people_outline_rounded},
      {'label': 'Allocate', 'icon': Icons.local_offer_rounded, 'inactiveIcon': Icons.local_offer_outlined},
      {'label': 'Expenses', 'icon': Icons.receipt_long_rounded, 'inactiveIcon': Icons.receipt_long_outlined},
      {'label': 'Reports', 'icon': Icons.pie_chart_rounded, 'inactiveIcon': Icons.pie_chart_outline_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = _currentIndex == index;
          final item = items[index];

          return InkWell(
            onTap: () => setState(() => _currentIndex = index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        item['inactiveIcon'] as IconData,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.amount,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: iconColor.withValues(alpha: 0.15),
        highlightColor: iconColor.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 16,
                    color: iconColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatTrendIcon extends StatelessWidget {
  final double size;
  final Color color;

  const StatTrendIcon({
    super.key,
    this.size = 24.0,
    this.color = const Color(0xFFFF5500),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StatTrendIconPainter(color: color),
      ),
    );
  }
}

class _StatTrendIconPainter extends CustomPainter {
  final Color color;

  _StatTrendIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Base horizontal line
    final baseLineY = size.height * 0.84;
    canvas.drawLine(
      Offset(size.width * 0.1, baseLineY),
      Offset(size.width * 0.9, baseLineY),
      linePaint,
    );

    // 2. Upward trending line
    final path = Path();
    final p0 = Offset(size.width * 0.12, size.height * 0.60);
    final p1 = Offset(size.width * 0.38, size.height * 0.35);
    final p2 = Offset(size.width * 0.58, size.height * 0.46);
    final p3 = Offset(size.width * 0.82, size.height * 0.20);

    path.moveTo(p0.dx, p0.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);

    canvas.drawPath(path, linePaint);

    // 3. Node & arrow tip at top-right end
    canvas.drawCircle(p3, 2.5, fillPaint);

    final arrowPath = Path();
    arrowPath.moveTo(p3.dx - 4.5, p3.dy);
    arrowPath.lineTo(p3.dx, p3.dy);
    arrowPath.lineTo(p3.dx, p3.dy + 4.5);
    canvas.drawPath(arrowPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF374151),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}


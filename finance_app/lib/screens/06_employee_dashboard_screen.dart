import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '02_login_screen.dart';
import '07_add_expense_screen.dart';
import '08_my_expenses_screen.dart';
import '10_expense_history_screen.dart';
import '15_profile_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _currentIndex = 0;
  List<ExpenseModel> _recentExpenses = [];
  UserModel? _currentUser;
  String? _profilePhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await ApiService.getCurrentUser();
    final expenses = await ApiService.getExpenses();
    final photo = await AuthService.getProfilePhoto();

    final allocated = user?.allocatedAmount ?? 0.0;
    final userExpenses = expenses.where((e) {
      final uName = (user?.username ?? '').toLowerCase();
      final fName = (user?.fullName ?? '').toLowerCase();
      final expUser = e.userName.toLowerCase();
      return expUser == uName || expUser == fName || (uName.isNotEmpty && expUser.contains(uName));
    }).toList();

    final totalUsed = userExpenses.isNotEmpty
        ? userExpenses.fold(0.0, (sum, exp) => sum + exp.amount)
        : (user?.usedAmount ?? 0.0);

    final remaining = allocated - totalUsed;

    if (mounted) {
      setState(() {
        _profilePhotoUrl = photo;
        _currentUser = user != null
            ? UserModel(
                id: user.id,
                username: user.username,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                role: user.role,
                department: user.department,
                employeeId: user.employeeId,
                allocatedAmount: allocated,
                usedAmount: totalUsed,
                remainingAmount: remaining,
              )
            : null;
        _recentExpenses = userExpenses.isNotEmpty ? userExpenses.take(5).toList() : expenses.take(5).toList();
        _isLoading = false;
      });
    }
  }



  Widget _buildAvatarImage(String path, {required double size}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.6, color: AppColors.primary),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.6, color: AppColors.primary),
      );
    } else {
      return Icon(Icons.person, size: size * 0.6, color: AppColors.primary);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final name = _currentUser?.fullName.isNotEmpty == true 
        ? _currentUser!.fullName 
        : (_currentUser?.firstName.isNotEmpty == true 
            ? '${_currentUser!.firstName} ${_currentUser!.lastName}'.trim()
            : (_currentUser?.username ?? ''));
    final allocated = _currentUser?.allocatedAmount ?? 0.0;
    final used = _currentUser?.usedAmount ?? 0.0;
    final remaining = _currentUser?.remainingAmount ?? (allocated - used);
    final isOverspent = remaining < 0;
    final overspendAmount = (used - allocated).clamp(0.0, double.infinity);
    final progress = allocated > 0 ? (used / allocated).clamp(0.0, 1.0) : 0.0;
    final percentVal = allocated > 0 ? ((used / allocated) * 100).round() : 0;
    final percentText = isOverspent ? '$percentVal% Used (Over Budget)' : '$percentVal% Used';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                        _loadData();
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: _buildAvatarImage(
                            _profilePhotoUrl ?? 'assets/images/founder_avatar.png',
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hey, $name 👋', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Text('Good morning!', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      tooltip: 'Logout',
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Overspend Warning Banner (if over budget)
            if (isOverspent) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budget Overspent Alert!',
                            style: TextStyle(
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You have overspent by ₹${overspendAmount.toStringAsFixed(0)}. Please contact founder/admin for budget reallocation.',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Allocated Amount Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isOverspent ? const Color(0xFFFEF2F2) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOverspent ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                  width: isOverspent ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Allocated Budget', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${allocated.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Used Budget', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${used.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isOverspent ? Colors.redAccent : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isOverspent ? 'Overspent Extra' : 'Remaining',
                            style: TextStyle(
                              fontSize: 10,
                              color: isOverspent ? Colors.redAccent : Colors.grey,
                              fontWeight: isOverspent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOverspent
                                ? '- ₹${overspendAmount.toStringAsFixed(0)}'
                                : '₹${remaining.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isOverspent ? Colors.redAccent : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverspent ? Colors.redAccent : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      percentText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isOverspent ? FontWeight.bold : FontWeight.normal,
                        color: isOverspent ? Colors.redAccent : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.add_circle_outline,
                    label: 'Add Expense',
                    color: AppColors.primary,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                      );
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'My Expenses',
                    color: Colors.blue,
                    onTap: () {
                      setState(() => _currentIndex = 1);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.history,
                    label: 'History',
                    color: Colors.purple,
                    onTap: () {
                      setState(() => _currentIndex = 2);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Expenses List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Expenses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    setState(() => _currentIndex = 1);
                  },
                  child: const Text('See All', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Expenses List
            _recentExpenses.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No Expenses Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                        SizedBox(height: 4),
                        Text('Tap "+ Add Expense" to create your first expense claim.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentExpenses.length,
                    itemBuilder: (context, index) {
                      final exp = _recentExpenses[index];
                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: const Icon(Icons.receipt, color: AppColors.primary, size: 20),
                          ),
                          title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${exp.categoryName} • ${exp.dateTime}', style: const TextStyle(fontSize: 11)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${exp.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                exp.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: exp.isApproved ? AppColors.approvedGreen : (exp.isPending ? Colors.orange : Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const MyExpensesScreen(),
          const ExpenseHistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _loadData();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

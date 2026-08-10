import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_tile.dart';
import '../accounts/accounts_screen.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;
  UserModel? _user;
  Map<String, dynamic>? _analytics;
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await AuthService.fetchUserProfile();
    final analytics = await ApiService.getAnalyticsSummary();
    final transactions = await ApiService.getTransactions();

    if (mounted) {
      setState(() {
        _user = user;
        _analytics = analytics;
        _recentTransactions = transactions.take(5).toList();
        _isLoading = false;
      });
    }
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalBalance = _analytics?['total_balance'] ?? 0.0;
    final totalIncome = _analytics?['total_income'] ?? 0.0;
    final totalExpense = _analytics?['total_expense'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${_user?.firstName.isNotEmpty == true ? _user!.firstName : _user?.username ?? "User"} 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Financial Overview',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Total Balance Gradient Card
            StatCard(
              title: 'Total Net Balance',
              amount: '\$${totalBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
              color: Colors.white,
              gradient: AppColors.primaryGradient,
            ),
            const SizedBox(height: 16),

            // Income & Expense Sub-Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Monthly Income',
                    amount: '\$${totalIncome.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: AppColors.incomeGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Monthly Expense',
                    amount: '\$${totalExpense.toStringAsFixed(2)}',
                    icon: Icons.trending_down,
                    color: AppColors.expenseRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Quick Actions Bar
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      label: 'Add Transaction',
                      icon: Icons.add_circle_outline,
                      color: AppColors.primary,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
                        );
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      label: 'Manage Accounts',
                      icon: Icons.account_balance,
                      color: AppColors.secondary,
                      onTap: () {
                        setState(() => _currentIndex = 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Recent Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _currentIndex = 2);
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_recentTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No transactions recorded yet.'),
              )
            else
              ..._recentTransactions.map(
                (tx) => TransactionTile(
                  title: tx.title,
                  categoryName: tx.categoryDetail?.name ?? 'General',
                  date: tx.date,
                  amount: tx.amount,
                  isIncome: tx.isIncome,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildDashboardTab(),
      const AccountsScreen(),
      const TransactionsScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _loadData();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), activeIcon: Icon(Icons.account_balance), label: 'Accounts'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

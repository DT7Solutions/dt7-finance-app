import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/donut_chart_widget.dart';
import '04_users_screen.dart';
import '05_allocate_budget_screen.dart';
import '08_my_expenses_screen.dart';
import '13_reports_screen.dart';

class FounderDashboardScreen extends StatefulWidget {
  const FounderDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FounderDashboardScreen> createState() => _FounderDashboardScreenState();
}

class _FounderDashboardScreenState extends State<FounderDashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getFounderDashboard();
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    }
  }

  Widget _buildFounderTab() {
    final remaining = _dashboardData?['remaining_budget'] ?? 53000.0;
    final allocated = _dashboardData?['total_allocated'] ?? 150000.0;
    final expenses = _dashboardData?['total_expenses'] ?? 97000.0;
    final users = _dashboardData?['total_users'] ?? 5;
    final overBudget = _dashboardData?['over_budget'] ?? 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text('Hello, Founder ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('👋', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Text('Welcome back!', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Text('This Month ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Icon(Icons.keyboard_arrow_down, size: 14),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total Balance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Balance', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${remaining.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text('Remaining Budget', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.show_chart, color: AppColors.primary, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metric Grid 2x2
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total Allocated',
                  amount: '₹${allocated.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Total Expenses',
                  amount: '₹${expenses.toStringAsFixed(0)}',
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Over Budget',
                  amount: '$overBudget',
                  textColor: AppColors.rejectedRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Expenses Overview Donut Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expenses Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: const [
                    Text('This Month ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Icon(Icons.keyboard_arrow_down, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DonutChartWidget(totalExpenses: expenses),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildFounderTab(),
      const UsersScreen(),
      const AllocateBudgetScreen(),
      const MyExpensesScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: _isLoading ? const Center(child: CircularProgressIndicator()) : screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Allocate'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Reports'),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color? textColor;

  const _MetricCard({required this.title, required this.amount, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

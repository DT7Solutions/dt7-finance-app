import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/donut_chart_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    await ApiService.getReports();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = [
      {'rank': 1, 'name': 'Rahul Sharma', 'amount': 25000.0},
      {'rank': 2, 'name': 'John Doe', 'amount': 18500.0},
      {'rank': 3, 'name': 'Priya Patel', 'amount': 15600.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('This Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Total Allocated', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('₹1,50,000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Total Expenses', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('₹97,000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Remaining Budget', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('₹53,000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Expenses by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const DonutChartWidget(totalExpenses: 97000),
              const SizedBox(height: 28),

              // Top Spending Employees Leaderboard
              const Text('Top Spending Employees', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ...leaderboard.map((emp) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                    child: Row(
                      children: [
                        Text('${emp['rank']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13)),
                        const SizedBox(width: 14),
                        CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight, child: const Icon(Icons.person, size: 18, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(emp['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Text('₹${(emp['amount'] as double).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

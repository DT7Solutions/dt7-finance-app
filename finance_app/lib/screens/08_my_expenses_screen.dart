import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '09_expense_detail_screen.dart';

class MyExpensesScreen extends StatefulWidget {
  const MyExpensesScreen({Key? key}) : super(key: key);

  @override
  State<MyExpensesScreen> createState() => _MyExpensesScreenState();
}

class _MyExpensesScreenState extends State<MyExpensesScreen> {
  String _selectedFilter = 'All';
  List<ExpenseModel> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final list = await ApiService.getExpenses();
    if (mounted) {
      setState(() {
        _expenses = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _expenses.isNotEmpty
        ? _expenses
        : [
            ExpenseModel(id: 1, title: 'Travel to Client', amount: 500, categoryName: 'Travel', dateTime: '04 Aug 2026, 02:30 PM', status: 'APPROVED'),
            ExpenseModel(id: 2, title: 'Lunch with Team', amount: 200, categoryName: 'Food', dateTime: '04 Aug 2026, 01:15 PM', status: 'APPROVED'),
            ExpenseModel(id: 3, title: 'Fuel Expense', amount: 1000, categoryName: 'Fuel', dateTime: '03 Aug 2026, 05:45 PM', status: 'APPROVED'),
            ExpenseModel(id: 4, title: 'Office Supplies', amount: 1200, categoryName: 'Office', dateTime: '02 Aug 2026, 11:30 AM', status: 'PENDING'),
            ExpenseModel(id: 5, title: 'Internet Bill', amount: 600, categoryName: 'Office', dateTime: '01 Aug 2026, 09:00 AM', status: 'APPROVED'),
          ];

    final filters = ['All', 'This Month', 'This Week', 'Custom'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
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
                child: ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (ctx, idx) {
                    final exp = displayList[idx];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ExpenseDetailScreen(expense: exp)),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text(exp.categoryName, style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                Text('₹${exp.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(exp.dateTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                StatusBadge(status: exp.status),
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

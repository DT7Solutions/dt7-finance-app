import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import '09_expense_detail_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  List<ExpenseModel> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await ApiService.getExpenses();
    if (mounted) {
      setState(() {
        _history = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayHistory = _history.isNotEmpty
        ? _history
        : [
            ExpenseModel(id: 1, title: 'Travel to Client', amount: 500, categoryName: 'Travel', dateTime: '04 Aug 2026', status: 'APPROVED'),
            ExpenseModel(id: 2, title: 'Lunch with Team', amount: 200, categoryName: 'Food', dateTime: '04 Aug 2026', status: 'APPROVED'),
            ExpenseModel(id: 3, title: 'Fuel Expense', amount: 1000, categoryName: 'Fuel', dateTime: '03 Aug 2026', status: 'APPROVED'),
            ExpenseModel(id: 4, title: 'Office Supplies', amount: 1200, categoryName: 'Office', dateTime: '02 Aug 2026', status: 'PENDING'),
            ExpenseModel(id: 5, title: 'Internet Bill', amount: 600, categoryName: 'Office', dateTime: '01 Aug 2026', status: 'APPROVED'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Filter Dropdown
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

              Expanded(
                child: ListView.builder(
                  itemCount: displayHistory.length,
                  itemBuilder: (ctx, idx) {
                    final item = displayHistory[idx];
                    return InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ExpenseDetailScreen(expense: item)));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(item.dateTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

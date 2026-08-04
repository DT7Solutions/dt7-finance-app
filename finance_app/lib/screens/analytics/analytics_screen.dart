import 'package:flutter/material.dart';
import '../../models/budget_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/budget_progress_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _summary;
  List<BudgetModel> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final summary = await ApiService.getAnalyticsSummary();
    final budgets = await ApiService.getBudgets();

    if (mounted) {
      setState(() {
        _summary = summary;
        _budgets = budgets;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final income = _summary?['total_income'] ?? 0.0;
    final expense = _summary?['total_expense'] ?? 0.0;
    final savings = _summary?['net_savings'] ?? 0.0;
    final breakdown = (_summary?['category_breakdown'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Budgets')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Net Savings Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Net Savings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            '\$${savings.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: savings >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Income: \$${income.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.incomeGreen, fontWeight: FontWeight.w600)),
                              Text('Expenses: \$${expense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.expenseRed, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Spending by Category
                    const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (breakdown.isEmpty)
                      const Text('No expense data available for this period.')
                    else
                      ...breakdown.map((item) {
                        final catName = item['category__name'] ?? 'General';
                        final amt = item['total'] ?? 0.0;
                        final double pct = expense > 0 ? (amt / expense) * 100 : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(catName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '\$${amt.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.expenseRed),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 28),

                    // Active Budgets
                    const Text('Category Budgets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_budgets.isEmpty)
                      const Text('No category budgets defined.')
                    else
                      ..._budgets.map(
                        (b) => BudgetProgressBar(
                          categoryName: b.categoryDetail?.name ?? 'Category',
                          spent: b.spentAmount,
                          limit: b.limitAmount,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Detail'),
        actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Graphic Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.local_gas_station, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(expense.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              StatusBadge(status: expense.status),
              const SizedBox(height: 12),
              Text(
                '₹${expense.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),

              // Detail Table
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    _DetailRow(label: 'Category', value: expense.categoryName),
                    const Divider(height: 20),
                    _DetailRow(label: 'Date & Time', value: expense.dateTime.isNotEmpty ? expense.dateTime : '03 Aug 2026, 05:45 PM'),
                    const Divider(height: 20),
                    _DetailRow(label: 'Description', value: expense.description.isNotEmpty ? expense.description : 'Fuel filled for office visit to client location.'),
                    const Divider(height: 20),
                    _DetailRow(label: 'Added By', value: expense.userName.isNotEmpty ? expense.userName : 'John Doe'),
                    const Divider(height: 20),
                    _DetailRow(label: 'Payment Mode', value: expense.paymentMode),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Receipt Image Preview Box
              const Align(alignment: Alignment.centerLeft, child: Text('Receipt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              const SizedBox(height: 8),
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.receipt_long, size: 40, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Edit & Delete Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await ApiService.deleteExpense(expense.id);
                        if (context.mounted) Navigator.pop(context, true);
                      },
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

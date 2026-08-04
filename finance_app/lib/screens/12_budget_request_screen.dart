import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class BudgetRequestScreen extends StatefulWidget {
  const BudgetRequestScreen({Key? key}) : super(key: key);

  @override
  State<BudgetRequestScreen> createState() => _BudgetRequestScreenState();
}

class _BudgetRequestScreenState extends State<BudgetRequestScreen> {
  final _amountController = TextEditingController(text: '5000');
  final _reasonController = TextEditingController(
    text: 'Need additional budget for outstation client visit and hotel stay.',
  );
  int? _selectedCategoryId = 1;
  List<CategoryModel> _categories = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await ApiService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (cats.isNotEmpty) _selectedCategoryId = cats.first.id;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_amountController.text.isEmpty || _reasonController.text.isEmpty || _selectedCategoryId == null) return;

    setState(() => _isSubmitting = true);
    final amt = double.tryParse(_amountController.text) ?? 5000.0;

    await ApiService.submitBudgetRequest(
      amount: amt,
      categoryId: _selectedCategoryId!,
      reason: _reasonController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget request submitted!'), backgroundColor: AppColors.approvedGreen),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reqAmount = double.tryParse(_amountController.text) ?? 5000.0;
    final currentBalance = 2200.0;
    final afterBalance = currentBalance - reqAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Request')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Request Amount (₹)',
                hint: '5000',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: (_categories.isNotEmpty
                        ? _categories
                        : [
                            CategoryModel(id: 1, name: 'Travel', type: 'EXPENSE', icon: 'directions_car', color: '#3B82F6'),
                            CategoryModel(id: 2, name: 'Food', type: 'EXPENSE', icon: 'restaurant', color: '#10B981'),
                          ])
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Reason for Request',
                hint: 'Enter reason...',
                controller: _reasonController,
              ),

              // Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Balance', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text('₹${currentBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('After Request Balance', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text(
                          '₹${afterBalance.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.rejectedRed),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Submit Request',
                onPressed: _handleSubmit,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

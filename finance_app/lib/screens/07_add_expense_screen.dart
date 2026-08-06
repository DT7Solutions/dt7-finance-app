import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

import '03_dashboard_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  int? _selectedCategoryId = 3;
  List<CategoryModel> _categories = [];
  bool _isSaving = false;

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

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty || _selectedCategoryId == null) return;

    setState(() => _isSaving = true);
    final amt = double.tryParse(_amountController.text) ?? 1200.0;
    final dtStr = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(_selectedDateTime);

    await ApiService.createExpense(
      title: _titleController.text.trim(),
      amount: amt,
      categoryId: _selectedCategoryId!,
      description: _descriptionController.text.trim(),
      dateTime: dtStr,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!'), backgroundColor: AppColors.approvedGreen),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        leading: AppHeaderIconButton(
          icon: Icons.arrow_back,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FounderDashboardScreen()),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Expense Title',
                hint: 'e.g. Fuel for Office Visit',
                controller: _titleController,
              ),

              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: (_categories.isNotEmpty
                        ? _categories
                        : [
                            CategoryModel(id: 3, name: 'Fuel', type: 'EXPENSE', icon: 'local_gas_station', color: '#F59E0B'),
                            CategoryModel(id: 1, name: 'Travel', type: 'EXPENSE', icon: 'directions_car', color: '#3B82F6'),
                            CategoryModel(id: 2, name: 'Food', type: 'EXPENSE', icon: 'restaurant', color: '#10B981'),
                          ])
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Amount (₹)',
                hint: '1200',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              CustomTextField(
                label: 'Description',
                hint: 'Enter description...',
                controller: _descriptionController,
              ),

              const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('04 Aug 2026, 02:30 PM').format(_selectedDateTime)),
                      const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Upload Bill / Receipt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: const Icon(Icons.receipt_long, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)),
                    child: const Icon(Icons.add, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Save Expense',
                onPressed: _handleSave,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

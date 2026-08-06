import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _transactionType = 'EXPENSE';
  DateTime _selectedDate = DateTime.now();
  int? _selectedAccountId;
  int? _selectedCategoryId;

  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final accounts = await ApiService.getAccounts();
    final categories = await ApiService.getCategories();

    if (mounted) {
      setState(() {
        _accounts = accounts;
        _categories = categories;
        if (accounts.isNotEmpty) _selectedAccountId = accounts.first.id;
        final filteredCats = categories.where((c) => c.type == _transactionType).toList();
        if (filteredCats.isNotEmpty) _selectedCategoryId = filteredCats.first.id;
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedAccountId == null ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final result = await ApiService.createTransaction(
      accountId: _selectedAccountId!,
      categoryId: _selectedCategoryId!,
      title: _titleController.text.trim(),
      amount: amount,
      transactionType: _transactionType,
      date: dateStr,
      notes: _notesController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _categories.where((c) => c.type == _transactionType).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Segmented Toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _transactionType = 'EXPENSE';
                              final cats = _categories.where((c) => c.type == 'EXPENSE').toList();
                              _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _transactionType == 'EXPENSE' ? AppColors.expenseRed : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                color: _transactionType == 'EXPENSE' ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _transactionType = 'INCOME';
                              final cats = _categories.where((c) => c.type == 'INCOME').toList();
                              _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _transactionType == 'INCOME' ? AppColors.incomeGreen : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Income',
                              style: TextStyle(
                                color: _transactionType == 'INCOME' ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Transaction Title',
                    hint: 'e.g. Grocery Shopping, Monthly Salary',
                    controller: _titleController,
                  ),
                  CustomTextField(
                    label: 'Amount (\$)',
                    hint: '0.00',
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const Text('Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  () {
                    final Map<int, dynamic> uniqueAcc = {};
                    for (final a in _accounts) {
                      uniqueAcc.putIfAbsent(a.id, () => a);
                    }
                    final accList = uniqueAcc.values.toList();
                    final effAccId = (accList.any((a) => a.id == _selectedAccountId))
                        ? _selectedAccountId
                        : (accList.isNotEmpty ? accList.first.id : null);

                    return DropdownButtonFormField<int>(
                      value: effAccId,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: accList
                          .map((acc) => DropdownMenuItem<int>(
                                value: acc.id,
                                child: Text('${acc.name} (\$${acc.balance.toStringAsFixed(2)})'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    );
                  }(),
                  const SizedBox(height: 14),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  () {
                    final Map<int, dynamic> uniqueCat = {};
                    for (final c in filteredCategories) {
                      uniqueCat.putIfAbsent(c.id, () => c);
                    }
                    final catList = uniqueCat.values.toList();
                    final effCatId = (catList.any((c) => c.id == _selectedCategoryId))
                        ? _selectedCategoryId
                        : (catList.isNotEmpty ? catList.first.id : null);

                    return DropdownButtonFormField<int>(
                      value: effCatId,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: catList
                          .map((cat) => DropdownMenuItem<int>(
                                value: cat.id,
                                child: Text(cat.name),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    );
                  }(),
                  const SizedBox(height: 14),
                  const Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Notes (Optional)',
                    hint: 'Add additional details...',
                    controller: _notesController,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Save Transaction',
                    onPressed: _saveTransaction,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
    );
  }
}

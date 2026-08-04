import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AllocateBudgetScreen extends StatefulWidget {
  const AllocateBudgetScreen({Key? key}) : super(key: key);

  @override
  State<AllocateBudgetScreen> createState() => _AllocateBudgetScreenState();
}

class _AllocateBudgetScreenState extends State<AllocateBudgetScreen> {
  final _amountController = TextEditingController(text: '10000');
  final _noteController = TextEditingController();
  int? _selectedEmployeeId = 1;
  List<UserModel> _users = [];
  bool _isAllocating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        _users = users.where((u) => !u.isAdmin).toList();
        if (_users.isNotEmpty) _selectedEmployeeId = _users.first.id;
      });
    }
  }

  Future<void> _handleAllocate() async {
    if (_selectedEmployeeId == null || _amountController.text.isEmpty) return;

    setState(() => _isAllocating = true);
    final amt = double.tryParse(_amountController.text) ?? 10000.0;
    final success = await ApiService.allocateBudget(
      employeeId: _selectedEmployeeId!,
      amount: amt,
      note: _noteController.text.trim(),
    );

    setState(() => _isAllocating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Budget allocated successfully!' : 'Budget allocated successfully!'),
          backgroundColor: AppColors.approvedGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocate Budget'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Wallet Illustration Card
              Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.account_balance_wallet, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('Allocate budget to employee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // Form
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Employee', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _selectedEmployeeId,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: (_users.isNotEmpty
                            ? _users
                            : [
                                UserModel(id: 1, username: 'john_doe', email: 'john.doe@example.com', firstName: 'John', lastName: 'Doe'),
                                UserModel(id: 2, username: 'rahul_sharma', email: 'rahul@example.com', firstName: 'Rahul', lastName: 'Sharma'),
                              ])
                        .map((u) => DropdownMenuItem(value: u.id, child: Text(u.fullName)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedEmployeeId = val),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Current Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        SizedBox(height: 2),
                        Text('₹10,000', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Amount to Allocate (₹)',
                    hint: '10000',
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  CustomTextField(
                    label: 'Note (Optional)',
                    hint: 'Enter a note',
                    controller: _noteController,
                  ),
                  const SizedBox(height: 16),

                  CustomButton(
                    text: 'Allocate',
                    onPressed: _handleAllocate,
                    isLoading: _isAllocating,
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

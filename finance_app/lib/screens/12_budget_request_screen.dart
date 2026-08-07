import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/budget_request_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_badge.dart';
import '03_dashboard_screen.dart';

class BudgetRequestScreen extends StatefulWidget {
  const BudgetRequestScreen({Key? key}) : super(key: key);

  @override
  State<BudgetRequestScreen> createState() => _BudgetRequestScreenState();
}

class _BudgetRequestScreenState extends State<BudgetRequestScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  int? _selectedCategoryId = 1;
  List<CategoryModel> _categories = [];
  UserModel? _currentUser;
  List<BudgetRequestModel> _myRequests = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await ApiService.getCategories();
    final user = await ApiService.getCurrentUser();
    final allReqs = await ApiService.getBudgetRequests();
    final myReqs = allReqs.where((r) => ApiService.isBudgetRequestOwnedByUser(r, user)).toList();

    if (mounted) {
      setState(() {
        _categories = cats;
        _currentUser = user;
        _myRequests = myReqs;
        if (cats.isNotEmpty) _selectedCategoryId = cats.first.id;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reasonStr = _reasonController.text.trim();

    if (amt <= 0 || reasonStr.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid request amount and reason.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await ApiService.submitBudgetRequest(
      requestAmount: amt,
      categoryId: _selectedCategoryId!,
      reason: reasonStr,
    );

    await _loadCategories();
    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget request submitted successfully!'), backgroundColor: AppColors.approvedGreen),
      );
      _amountController.clear();
      _reasonController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocated = _currentUser?.allocatedAmount ?? 25000.0;
    final reqAmount = double.tryParse(_amountController.text) ?? 0.0;
    final newBudgetAfterApproval = allocated + reqAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Request'),
        leading: AppHeaderIconButton(
          icon: Icons.arrow_back,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Request Amount (₹)',
                hint: 'Enter Amount',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              () {
                final raw = _categories.isNotEmpty
                    ? _categories
                    : [
                        CategoryModel(id: 1, name: 'Software Tools', type: 'EXPENSE', icon: 'computer', color: '#8B5CF6'),
                        CategoryModel(id: 2, name: 'AI Subscriptions', type: 'EXPENSE', icon: 'psychology', color: '#EC4899'),
                        CategoryModel(id: 3, name: 'Travel & Transport', type: 'EXPENSE', icon: 'directions_car', color: '#3B82F6'),
                      ];
                final Map<int, CategoryModel> uniqueMap = {};
                for (final c in raw) {
                  uniqueMap.putIfAbsent(c.id, () => c);
                }
                final categoryList = uniqueMap.values.toList();
                final effVal = (categoryList.any((c) => c.id == _selectedCategoryId))
                    ? _selectedCategoryId
                    : (categoryList.isNotEmpty ? categoryList.first.id : null);

                return DropdownButtonFormField<int>(
                  value: effVal,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: categoryList
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                );
              }(),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Reason for Request',
                hint: 'Enter Reason',
                controller: _reasonController,
              ),

              // Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Allocated Budget', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text('₹${allocated.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Additional Request Amount', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text('+ ₹${reqAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Projected Budget Post-Approval', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        Text(
                          '₹${newBudgetAfterApproval.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.approvedGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Submit Budget Request',
                onPressed: _handleSubmit,
                isLoading: _isSubmitting,
              ),

              const SizedBox(height: 32),
              const Text(
                'My Budget Requests Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              if (_myRequests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text('No budget requests submitted yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _myRequests.length,
                  itemBuilder: (ctx, idx) {
                    final req = _myRequests[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                req.categoryName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                              ),
                              StatusBadge(status: req.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                req.createdAt,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                              Text(
                                '₹${req.requestAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                              ),
                            ],
                          ),
                          if (req.reason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Reason: ${req.reason}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

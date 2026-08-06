import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/status_badge.dart';
import '03_dashboard_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late ExpenseModel _currentExpense;
  bool _isFounderOrAdmin = false;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expense;
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final role = await AuthService.getUserRole();
    if (mounted) {
      setState(() {
        _isFounderOrAdmin = role == 'FOUNDER' || role == 'ADMIN';
      });
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('software') || lower.contains('tool') || lower.contains('app')) {
      return Icons.computer_rounded;
    } else if (lower.contains('ai') || lower.contains('subscription') || lower.contains('gpt')) {
      return Icons.psychology_rounded;
    } else if (lower.contains('travel') || lower.contains('transport') || lower.contains('cab')) {
      return Icons.directions_car_rounded;
    } else if (lower.contains('office') || lower.contains('supply') || lower.contains('stationery')) {
      return Icons.shopping_bag_rounded;
    } else if (lower.contains('fuel') || lower.contains('gas')) {
      return Icons.local_gas_station_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  Color _getCategoryColor(String categoryName) {
    return AppColors.primary;
  }

  void _showEditSheet(BuildContext context) {
    final titleCtrl = TextEditingController(text: _currentExpense.title);
    final amountCtrl = TextEditingController(text: _currentExpense.amount.toStringAsFixed(0));
    String selectedCategory = _currentExpense.categoryName;

    final categories = [
      'Software Tools',
      'AI Subscriptions',
      'Purchase of Domain or Server',
      'Cloud Infrastructure & Hosting',
      'API & Third-Party Services',
      'Hardware & Dev Peripherals',
      'Travel & Client Visits',
      'Office Supplies & Utilities',
      'Others',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Expense Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Expense Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSel = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.primary : Colors.black87,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setSheetState(() => selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final newAmount = double.tryParse(amountCtrl.text) ?? _currentExpense.amount;
                        final newTitle = titleCtrl.text.trim().isEmpty ? _currentExpense.title : titleCtrl.text.trim();
                        await ApiService.updateExpense(
                          id: _currentExpense.id,
                          title: newTitle,
                          amount: newAmount,
                          categoryName: selectedCategory,
                        );
                        setState(() {
                          _currentExpense = ExpenseModel(
                            id: _currentExpense.id,
                            title: newTitle,
                            amount: newAmount,
                            categoryId: _currentExpense.categoryId,
                            categoryName: selectedCategory,
                            dateTime: _currentExpense.dateTime,
                            status: _currentExpense.status,
                            description: _currentExpense.description,
                            userName: _currentExpense.userName,
                            paymentMode: _currentExpense.paymentMode,
                            receiptImage: _currentExpense.receiptImage,
                            approvedBy: _currentExpense.approvedBy,
                            approvalDate: _currentExpense.approvalDate,
                          );
                        });
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Expense details updated successfully!'),
                              backgroundColor: AppColors.approvedGreen,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_currentExpense.title}"? This action will restore the allocated budget.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.deleteExpense(_currentExpense.id);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(_currentExpense.categoryName);
    final catIcon = _getCategoryIcon(_currentExpense.categoryName);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Expense Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _showEditSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HERO EXPENSE HEADER CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catColor, catColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: catColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      child: Icon(catIcon, size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentExpense.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: _currentExpense.status),
                    const SizedBox(height: 16),
                    Text(
                      '₹${_currentExpense.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- INFORMATION GRID CARD ---
              const Text(
                'Expense Breakdown',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: _currentExpense.categoryName,
                      badgeColor: catColor,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date & Time',
                      value: _currentExpense.dateTime.isNotEmpty ? _currentExpense.dateTime : '06 Aug 2026, 02:30 PM',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.payment_outlined,
                      label: 'Payment Mode',
                      value: _currentExpense.paymentMode,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Claimed By',
                      value: _currentExpense.userName.isNotEmpty ? _currentExpense.userName : 'Employee User',
                    ),
                    if (_currentExpense.approvedBy.isNotEmpty) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Approved By',
                        value: _currentExpense.approvedBy,
                        badgeColor: AppColors.approvedGreen,
                      ),
                    ],
                    if (_currentExpense.approvalDate.isNotEmpty) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.event_available_outlined,
                        label: 'Approval Date',
                        value: _currentExpense.approvalDate,
                      ),
                    ],
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Description / Notes',
                      value: _currentExpense.description.isNotEmpty
                          ? _currentExpense.description
                          : 'Expenses incurred for official business operations.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- RECEIPT ATTACHMENT CARD ---
              const Text(
                'Receipt Attachment',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: catColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_currentExpense.title}_Receipt.pdf',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Attached • Verified Voucher',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Viewing digital voucher receipt preview'), backgroundColor: AppColors.primary),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- ACTION BUTTONS ---
              if (_isFounderOrAdmin || _currentExpense.isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Approve Claim'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.approvedGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final currentUser = await ApiService.getCurrentUser();
                          final approver = currentUser?.fullName.isNotEmpty == true
                              ? currentUser!.fullName
                              : (currentUser?.username.isNotEmpty == true ? currentUser!.username : 'Founder');
                          final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

                          await ApiService.updateExpense(
                            id: _currentExpense.id,
                            title: _currentExpense.title,
                            amount: _currentExpense.amount,
                            categoryName: _currentExpense.categoryName,
                            status: 'APPROVED',
                            approvedBy: approver,
                            approvalDate: nowStr,
                          );
                          setState(() {
                            _currentExpense = ExpenseModel(
                              id: _currentExpense.id,
                              title: _currentExpense.title,
                              amount: _currentExpense.amount,
                              categoryId: _currentExpense.categoryId,
                              categoryName: _currentExpense.categoryName,
                              dateTime: _currentExpense.dateTime,
                              status: 'APPROVED',
                              description: _currentExpense.description,
                              userName: _currentExpense.userName,
                              paymentMode: _currentExpense.paymentMode,
                              receiptImage: _currentExpense.receiptImage,
                              approvedBy: approver,
                              approvalDate: nowStr,
                            );
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense claim approved successfully!'),
                                backgroundColor: AppColors.approvedGreen,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Reject Claim'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final currentUser = await ApiService.getCurrentUser();
                          final approver = currentUser?.fullName.isNotEmpty == true
                              ? currentUser!.fullName
                              : (currentUser?.username.isNotEmpty == true ? currentUser!.username : 'Founder');
                          final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

                          await ApiService.updateExpense(
                            id: _currentExpense.id,
                            title: _currentExpense.title,
                            amount: _currentExpense.amount,
                            categoryName: _currentExpense.categoryName,
                            status: 'REJECTED',
                            approvedBy: approver,
                            approvalDate: nowStr,
                          );
                          setState(() {
                            _currentExpense = ExpenseModel(
                              id: _currentExpense.id,
                              title: _currentExpense.title,
                              amount: _currentExpense.amount,
                              categoryId: _currentExpense.categoryId,
                              categoryName: _currentExpense.categoryName,
                              dateTime: _currentExpense.dateTime,
                              status: 'REJECTED',
                              description: _currentExpense.description,
                              userName: _currentExpense.userName,
                              paymentMode: _currentExpense.paymentMode,
                              receiptImage: _currentExpense.receiptImage,
                              approvedBy: approver,
                              approvalDate: nowStr,
                            );
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense claim rejected.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Claim'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showEditSheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete Claim'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _confirmDelete(context),
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
  final IconData icon;
  final String label;
  final String value;
  final Color? badgeColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: badgeColor ?? const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

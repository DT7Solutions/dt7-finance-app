import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({Key? key}) : super(key: key);

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  String _selectedTab = 'Pending';

  final List<Map<String, dynamic>> _pendingApprovals = [
    {'id': 1, 'title': 'Travel to Client', 'category': 'Travel', 'user': 'John Doe', 'date': '04 Aug 2026', 'amount': 2500.0},
    {'id': 2, 'title': 'Hotel Booking', 'category': 'Travel', 'user': 'Priya Patel', 'date': '03 Aug 2026', 'amount': 4200.0},
    {'id': 3, 'title': 'Office Supplies', 'category': 'Office', 'user': 'Amit Verma', 'date': '03 Aug 2026', 'amount': 1200.0},
  ];

  Future<void> _handleAction(int id, String action) async {
    await ApiService.submitApprovalAction(id, 'expense', action);
    setState(() {
      _pendingApprovals.removeWhere((item) => item['id'] == id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense ${action}d successfully!'), backgroundColor: AppColors.approvedGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Tabs
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'Pending'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'Pending' ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Pending (${_pendingApprovals.length})',
                          style: TextStyle(
                            color: _selectedTab == 'Pending' ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'Approved'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'Approved' ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Approved',
                          style: TextStyle(
                            color: _selectedTab == 'Approved' ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'Rejected'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'Rejected' ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Rejected',
                          style: TextStyle(
                            color: _selectedTab == 'Rejected' ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pending Approvals List
              Expanded(
                child: _pendingApprovals.isEmpty
                    ? const Center(child: Text('No pending approvals'))
                    : ListView.builder(
                        itemCount: _pendingApprovals.length,
                        itemBuilder: (ctx, idx) {
                          final item = _pendingApprovals[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                      child: Text(item['category'] as String, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item['user'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['date'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                    Text('₹${(item['amount'] as double).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Reject / Approve Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () => _handleAction(item['id'] as int, 'reject'),
                                        child: const Text('Reject', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () => _handleAction(item['id'] as int, 'approve'),
                                        child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

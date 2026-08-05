import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/status_badge.dart';
import '03_dashboard_screen.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

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

  final List<Map<String, dynamic>> _approvedApprovals = [
    {'id': 101, 'title': 'Software Subscription', 'category': 'Office', 'user': 'Neha Singh', 'date': '02 Aug 2026', 'amount': 1500.0},
    {'id': 102, 'title': 'Team Lunch', 'category': 'Food', 'user': 'Rahul Sharma', 'date': '01 Aug 2026', 'amount': 3200.0},
  ];

  final List<Map<String, dynamic>> _rejectedApprovals = [
    {'id': 201, 'title': 'Luxury Taxi Service', 'category': 'Travel', 'user': 'John Doe', 'date': '31 Jul 2026', 'amount': 8500.0},
  ];

  Future<void> _handleAction(int id, String action) async {
    ApiService.submitApprovalAction(id, 'expense', action);

    final idx = _pendingApprovals.indexWhere((item) => item['id'] == id);
    if (idx != -1) {
      final item = Map<String, dynamic>.from(_pendingApprovals.removeAt(idx));
      if (action == 'approve') {
        _approvedApprovals.insert(0, item);
      } else {
        _rejectedApprovals.insert(0, item);
      }
      setState(() {});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense ${action == 'approve' ? 'approved' : 'rejected'} successfully!'),
          backgroundColor: action == 'approve' ? AppColors.approvedGreen : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _selectedTab == 'Pending'
        ? _pendingApprovals
        : _selectedTab == 'Approved'
            ? _approvedApprovals
            : _rejectedApprovals;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'approvals'),
      appBar: AppBar(
        title: const Text('Approvals'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Tabs Header
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
                          'Approved (${_approvedApprovals.length})',
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
                          'Rejected (${_rejectedApprovals.length})',
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

              // Approvals Queue List
              Expanded(
                child: displayList.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_selectedTab.toLowerCase()} approvals',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayList.length,
                        itemBuilder: (ctx, idx) {
                          final item = displayList[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item['category'] as String,
                                        style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['user'] as String,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['date'] as String,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                    ),
                                    Text(
                                      '₹${(item['amount'] as double).toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Action Buttons or Status Badge
                                if (_selectedTab == 'Pending')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.grey.shade300),
                                            alignment: Alignment.center,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          onPressed: () => _handleAction(item['id'] as int, 'reject'),
                                          child: const Text(
                                            'Reject',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            alignment: Alignment.center,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          onPressed: () => _handleAction(item['id'] as int, 'approve'),
                                          child: const Text(
                                            'Approve',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: StatusBadge(
                                      status: _selectedTab == 'Approved' ? 'APPROVED' : 'REJECTED',
                                    ),
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

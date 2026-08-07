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
  String _selectedType = 'All'; // 'All', 'Expenses', or 'Budget Requests'
  bool _isLoading = true;

  List<Map<String, dynamic>> _pendingApprovals = [];
  List<Map<String, dynamic>> _approvedApprovals = [];
  List<Map<String, dynamic>> _rejectedApprovals = [];

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    final expenses = await ApiService.getExpenses();
    final reqs = await ApiService.getBudgetRequests();

    final pendingExp = expenses.where((e) => e.isPending).map((e) => {
      'id': e.id,
      'type': 'expense',
      'title': e.title,
      'category': e.categoryName,
      'user': e.userName,
      'date': e.dateTime,
      'amount': e.amount,
      'reason': e.description ?? '',
    }).toList();

    final approvedExp = expenses.where((e) => e.isApproved).map((e) => {
      'id': e.id,
      'type': 'expense',
      'title': e.title,
      'category': e.categoryName,
      'user': e.userName,
      'date': e.dateTime,
      'amount': e.amount,
      'reason': e.description ?? '',
    }).toList();

    final rejectedExp = expenses.where((e) => e.isRejected).map((e) => {
      'id': e.id,
      'type': 'expense',
      'title': e.title,
      'category': e.categoryName,
      'user': e.userName,
      'date': e.dateTime,
      'amount': e.amount,
      'reason': e.description ?? '',
    }).toList();

    final pendingReq = reqs.where((r) => r.status == 'PENDING').map((r) => {
      'id': r.id,
      'type': 'budget_request',
      'title': 'Budget Request: ${r.categoryName}',
      'category': r.categoryName,
      'user': r.userName,
      'date': r.createdAt,
      'amount': r.requestAmount,
      'reason': r.reason,
    }).toList();

    final approvedReq = reqs.where((r) => r.status == 'APPROVED').map((r) => {
      'id': r.id,
      'type': 'budget_request',
      'title': 'Budget Request: ${r.categoryName}',
      'category': r.categoryName,
      'user': r.userName,
      'date': r.createdAt,
      'amount': r.requestAmount,
      'reason': r.reason,
    }).toList();

    final rejectedReq = reqs.where((r) => r.status == 'REJECTED').map((r) => {
      'id': r.id,
      'type': 'budget_request',
      'title': 'Budget Request: ${r.categoryName}',
      'category': r.categoryName,
      'user': r.userName,
      'date': r.createdAt,
      'amount': r.requestAmount,
      'reason': r.reason,
    }).toList();

    if (mounted) {
      setState(() {
        if (_selectedType == 'Expenses') {
          _pendingApprovals = pendingExp;
          _approvedApprovals = approvedExp;
          _rejectedApprovals = rejectedExp;
        } else if (_selectedType == 'Budget Requests') {
          _pendingApprovals = pendingReq;
          _approvedApprovals = approvedReq;
          _rejectedApprovals = rejectedReq;
        } else {
          _pendingApprovals = [...pendingReq, ...pendingExp];
          _approvedApprovals = [...approvedReq, ...approvedExp];
          _rejectedApprovals = [...rejectedReq, ...rejectedExp];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(int id, String action, String type) async {
    final newStatus = action == 'approve' ? 'APPROVED' : 'REJECTED';
    if (type == 'budget_request') {
      await ApiService.updateBudgetRequestStatus(id, newStatus);
    } else {
      final expenses = await ApiService.getExpenses();
      final expIdx = expenses.indexWhere((e) => e.id == id);
      if (expIdx != -1) {
        final exp = expenses[expIdx];
        await ApiService.updateExpense(
          id: exp.id,
          title: exp.title,
          amount: exp.amount,
          categoryName: exp.categoryName,
          status: newStatus,
        );
      } else {
        await ApiService.submitApprovalAction(id, 'expense', action);
      }
    }
    await _loadApprovals();

    if (mounted) {
      final label = type == 'budget_request' ? 'Budget Request' : 'Expense';
      final isApproved = action == 'approve';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApproved
                ? (type == 'budget_request' ? '$label approved & allocated successfully!' : '$label approved successfully!')
                : '$label rejected!'),
          backgroundColor: isApproved ? AppColors.approvedGreen : Colors.redAccent,
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
              // Type Selector (All vs Expenses vs Budget Requests)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = 'All');
                          _loadApprovals();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedType == 'All' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedType == 'All'
                                ? [const BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 2))]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'All Requests',
                            style: TextStyle(
                              color: _selectedType == 'All' ? AppColors.primary : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = 'Expenses');
                          _loadApprovals();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedType == 'Expenses' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedType == 'Expenses'
                                ? [const BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 2))]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Expenses',
                            style: TextStyle(
                              color: _selectedType == 'Expenses' ? AppColors.primary : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = 'Budget Requests');
                          _loadApprovals();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedType == 'Budget Requests' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedType == 'Budget Requests'
                                ? [const BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 2))]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Budget Req.',
                            style: TextStyle(
                              color: _selectedType == 'Budget Requests' ? AppColors.primary : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

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
              const SizedBox(height: 16),

              // Approvals Queue List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadApprovals,
                  color: AppColors.primary,
                  child: displayList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Text(
                                  'No ${_selectedTab.toLowerCase()} ${_selectedType.toLowerCase()}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          itemBuilder: (ctx, idx) {
                            final item = displayList[idx];
                            final itemType = item['type'] as String? ?? 'expense';
                            final reasonStr = item['reason'] as String? ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
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
                                      Expanded(
                                        child: Text(
                                          item['title'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: itemType == 'budget_request' ? const Color(0xFFECFDF5) : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item['category'] as String,
                                          style: TextStyle(
                                            color: itemType == 'budget_request' ? const Color(0xFF10B981) : Colors.blue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['user'] as String,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  if (reasonStr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Reason: $reasonStr',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item['date'] as String,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                      ),
                                      Text(
                                        '₹${(item['amount'] as double).toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
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
                                            onPressed: () => _handleAction(item['id'] as int, 'reject', itemType),
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
                                            onPressed: () => _handleAction(item['id'] as int, 'approve', itemType),
                                            child: Text(
                                              itemType == 'budget_request' ? 'Approve & Allocate' : 'Approve',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

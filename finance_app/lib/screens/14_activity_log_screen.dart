import 'package:flutter/material.dart';
import '../models/activity_log_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({Key? key}) : super(key: key);

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<ActivityLogModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await ApiService.getActivityLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLogs = _logs.isNotEmpty
        ? _logs
        : [
            ActivityLogModel(id: 1, userName: 'Admin', title: 'Budget allocated to John Doe', description: '₹10,000 allocated', timestamp: '04 Aug 2026, 10:30 AM'),
            ActivityLogModel(id: 2, userName: 'John Doe', title: 'Expense added by John Doe', description: 'Fuel Expense - ₹500', timestamp: '04 Aug 2026, 11:15 AM'),
            ActivityLogModel(id: 3, userName: 'Admin', title: 'Expense approved', description: 'Travel to Client - ₹500', timestamp: '04 Aug 2026, 11:30 AM'),
            ActivityLogModel(id: 4, userName: 'Admin', title: 'Budget increased for John Doe', description: '₹5,000 added', timestamp: '04 Aug 2026, 12:10 PM'),
            ActivityLogModel(id: 5, userName: 'John Doe', title: 'Budget request submitted', description: 'John Doe - ₹5,000', timestamp: '04 Aug 2026, 12:20 PM'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: displayLogs.length,
            itemBuilder: (ctx, idx) {
              final log = displayLogs[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(log.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text(log.timestamp, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

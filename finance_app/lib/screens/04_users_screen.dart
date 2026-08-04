import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> _users = [];

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
      });
    }
  }

  void _showAddUserModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'password123');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
            const SizedBox(height: 12),
            TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Create User',
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                  final uname = emailCtrl.text.split('@').first.replaceAll('.', '_');
                  await ApiService.addUser(
                    username: uname,
                    email: emailCtrl.text.trim(),
                    password: passwordCtrl.text,
                    fullName: nameCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  _loadUsers();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Default fallback users if API loading offline
    final displayUsers = _users.isNotEmpty
        ? _users
        : [
            UserModel(id: 1, username: 'john_doe', email: 'john.doe@example.com', firstName: 'John', lastName: 'Doe', allocatedAmount: 10000),
            UserModel(id: 2, username: 'rahul_sharma', email: 'rahul@example.com', firstName: 'Rahul', lastName: 'Sharma', allocatedAmount: 20000),
            UserModel(id: 3, username: 'priya_patel', email: 'priya@example.com', firstName: 'Priya', lastName: 'Patel', allocatedAmount: 15000),
            UserModel(id: 4, username: 'amit_verma', email: 'amit@example.com', firstName: 'Amit', lastName: 'Verma', allocatedAmount: 5000),
            UserModel(id: 5, username: 'neha_singh', email: 'neha@example.com', firstName: 'Neha', lastName: 'Singh', allocatedAmount: 8000),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {})],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: const Icon(Icons.tune, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Users List
              Expanded(
                child: ListView.builder(
                  itemCount: displayUsers.length,
                  itemBuilder: (ctx, idx) {
                    final u = displayUsers[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(Icons.person, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(u.email, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${u.allocatedAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              const Text('Active', style: TextStyle(fontSize: 10, color: AppColors.approvedGreen, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddUserModal,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ Add User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

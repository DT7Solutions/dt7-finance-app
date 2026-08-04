import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '02_login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {})],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Avatar & Name
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.person, size: 50, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text('John Doe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('Sales Department', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 24),

              // Details Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                  children: const [
                    _ProfileDetailRow(label: 'Employee ID', value: 'DT7EMP001'),
                    Divider(height: 20),
                    _ProfileDetailRow(label: 'Email', value: 'john.doe@example.com'),
                    Divider(height: 20),
                    _ProfileDetailRow(label: 'Phone', value: '+91 98765 43210'),
                    Divider(height: 20),
                    _ProfileDetailRow(label: 'Join Date', value: '01 Jan 2024'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Options
              _ProfileOptionTile(icon: Icons.lock_outline, title: 'Change Password', onTap: () {}),
              _ProfileOptionTile(icon: Icons.notifications_none, title: 'Notification Settings', onTap: () {}),
              _ProfileOptionTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
              const SizedBox(height: 16),

              // Logout Option
              InkWell(
                onTap: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
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

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOptionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
        leading: Icon(icon, size: 20, color: Colors.grey.shade700),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ),
    );
  }
}

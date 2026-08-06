import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/02_login_screen.dart';
import '../screens/03_dashboard_screen.dart';
import '../screens/04_users_screen.dart';
import '../screens/05_allocate_budget_screen.dart';
import '../screens/08_my_expenses_screen.dart';
import '../screens/11_approvals_screen.dart';
import '../screens/13_reports_screen.dart';
import '../screens/14_activity_log_screen.dart';
import '../screens/15_profile_screen.dart';

class AppDrawer extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<int>? onSelectTab;
  final VoidCallback? onShowBudgetBreakdown;

  const AppDrawer({
    super.key,
    this.currentRoute = '',
    this.onSelectTab,
    this.onShowBudgetBreakdown,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  UserModel? _user;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final u = await ApiService.getCurrentUser();
    final p = await AuthService.getProfilePhoto();
    if (mounted) {
      setState(() {
        _user = u;
        _profilePhotoUrl = p;
      });
    }
  }

  // Fast zero-delay page transition helper
  PageRouteBuilder _fastRoute(Widget screen) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 100),
      reverseTransitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.pushReplacement(context, _fastRoute(screen));
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.fullName.isNotEmpty == true
        ? _user!.fullName
        : (_user?.firstName.isNotEmpty == true
            ? '${_user!.firstName} ${_user!.lastName}'.trim()
            : (_user?.username.isNotEmpty == true ? _user!.username : 'Founder'));
    final emailStr = _user?.email.isNotEmpty == true ? _user!.email : 'founder@dt7.agency';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                    ? (_profilePhotoUrl!.startsWith('http')
                        ? Image.network(_profilePhotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: AppColors.primary))
                        : Image.asset(_profilePhotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: AppColors.primary)))
                    : Image.asset(
                        'assets/images/founder_avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            accountName: Text(
              'Hello, $displayName 👋',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              emailStr,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerTile(
                  icon: Icons.dashboard_rounded,
                  title: 'Founder Dashboard',
                  isSelected: widget.currentRoute == 'dashboard',
                  onTap: () => _navigate(context, const FounderDashboardScreen()),
                ),
                _DrawerTile(
                  icon: Icons.people_alt_rounded,
                  title: 'Manage Users & Teams',
                  isSelected: widget.currentRoute == 'users',
                  onTap: () => _navigate(context, const UsersScreen()),
                ),
                _DrawerTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Allocate Employee Budget',
                  isSelected: widget.currentRoute == 'allocate_budget',
                  onTap: () => _navigate(context, const AllocateBudgetScreen()),
                ),
                _DrawerTile(
                  icon: Icons.fact_check_rounded,
                  title: 'Approval Requests',
                  isSelected: widget.currentRoute == 'approvals',
                  onTap: () => _navigate(context, const ApprovalsScreen()),
                ),
                _DrawerTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'My Expenses Claims',
                  isSelected: widget.currentRoute == 'expenses',
                  onTap: () => _navigate(context, const MyExpensesScreen()),
                ),
                _DrawerTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Analytics & Financial Reports',
                  isSelected: widget.currentRoute == 'reports',
                  onTap: () => _navigate(context, const ReportsScreen()),
                ),
                _DrawerTile(
                  icon: Icons.history_rounded,
                  title: 'Audit & Activity Log',
                  isSelected: widget.currentRoute == 'activity_log',
                  onTap: () => _navigate(context, const ActivityLogScreen()),
                ),
                _DrawerTile(
                  icon: Icons.pie_chart_rounded,
                  title: 'Budget Spending Breakdown',
                  isSelected: widget.currentRoute == 'budget_breakdown',
                  onTap: () {
                    if (widget.onShowBudgetBreakdown != null) {
                      Navigator.pop(context);
                      widget.onShowBudgetBreakdown!();
                    } else {
                      _navigate(context, const FounderDashboardScreen(showBreakdownOnLoad: true));
                    }
                  },
                ),
                const Divider(),
                _DrawerTile(
                  icon: Icons.person_rounded,
                  title: 'Profile Settings',
                  isSelected: widget.currentRoute == 'profile',
                  onTap: () => _navigate(context, const ProfileScreen()),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      _fastRoute(const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
      ),
    );
  }
}

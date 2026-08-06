import 'dart:async';
import 'package:flutter/material.dart';
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

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<int>? onSelectTab;
  final VoidCallback? onShowBudgetBreakdown;

  const AppDrawer({
    super.key,
    this.currentRoute = '',
    this.onSelectTab,
    this.onShowBudgetBreakdown,
  });

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
                child: Image.asset(
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
            accountName: const Text(
              'Hello, Founder 👋',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            accountEmail: const Text(
              'founder@dt7.agency',
              style: TextStyle(
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
                  title: 'Dashboard',
                  isSelected: currentRoute == 'dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) {
                      onSelectTab!(0);
                    } else if (currentRoute != 'dashboard') {
                      _navigate(context, const FounderDashboardScreen());
                    }
                  },
                ),
                _DrawerTile(
                  icon: Icons.people_rounded,
                  title: 'Users Management',
                  isSelected: currentRoute == 'users',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) {
                      onSelectTab!(1);
                    } else if (currentRoute != 'users') {
                      _navigate(context, const UsersScreen());
                    }
                  },
                ),
                _DrawerTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Allocate Budget',
                  isSelected: currentRoute == 'allocate',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) {
                      onSelectTab!(2);
                    } else if (currentRoute != 'allocate') {
                      Navigator.push(context, _fastRoute(const AllocateBudgetScreen()));
                    }
                  },
                ),
                _DrawerTile(
                  icon: Icons.account_tree_outlined,
                  title: 'Budget Spending Breakdown',
                  isSelected: currentRoute == 'breakdown',
                  onTap: () {
                    Navigator.pop(context);
                    if (onShowBudgetBreakdown != null) {
                      onShowBudgetBreakdown!();
                    } else {
                      Navigator.push(
                        context,
                        _fastRoute(const FounderDashboardScreen(showBreakdownOnLoad: true)),
                      );
                    }
                  },
                ),
                _DrawerTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'My Expenses',
                  isSelected: currentRoute == 'expenses',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) {
                      onSelectTab!(3);
                    } else if (currentRoute != 'expenses') {
                      _navigate(context, const MyExpensesScreen());
                    }
                  },
                ),
                _DrawerTile(
                  icon: Icons.pie_chart_rounded,
                  title: 'Reports & Analytics',
                  isSelected: currentRoute == 'reports',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) {
                      onSelectTab!(4);
                    } else if (currentRoute != 'reports') {
                      _navigate(context, const ReportsScreen());
                    }
                  },
                ),
                const Divider(height: 20),
                _DrawerTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Approvals Queue',
                  isSelected: currentRoute == 'approvals',
                  onTap: () {
                    if (currentRoute == 'approvals') {
                      Navigator.pop(context);
                    } else {
                      _navigate(context, const ApprovalsScreen());
                    }
                  },
                ),
                _DrawerTile(
                  icon: Icons.history_rounded,
                  title: 'Activity Logs',
                  isSelected: currentRoute == 'activity',
                  onTap: () {
                    if (currentRoute == 'activity') {
                      Navigator.pop(context);
                    } else {
                      _navigate(context, const ActivityLogScreen());
                    }
                  },
                ),
                _DrawerTile(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  isSelected: currentRoute == 'profile',
                  onTap: () {
                    if (currentRoute == 'profile') {
                      Navigator.pop(context);
                    } else {
                      _navigate(context, const ProfileScreen());
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  _fastRoute(const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<_DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<_DrawerTile> {
  bool _isPressed = false;
  double _glowOpacity = 0.16;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isSelected) {
      _startGlowPulse();
    }
  }

  @override
  void didUpdateWidget(covariant _DrawerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && _timer == null) {
      _startGlowPulse();
    } else if (!widget.isSelected && _timer != null) {
      _stopGlowPulse();
    }
  }

  void _startGlowPulse() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (mounted && widget.isSelected) {
        setState(() {
          _glowOpacity = _glowOpacity == 0.16 ? 0.38 : 0.16;
        });
      }
    });
  }

  void _stopGlowPulse() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _glowOpacity = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTap() async {
    setState(() => _isPressed = true);
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) {
      setState(() => _isPressed = false);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final scale = _isPressed ? 0.94 : (active ? 1.02 : 1.0);
    final currentGlow = _isPressed ? 0.30 : (active ? _glowOpacity : 0.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.primary.withValues(alpha: 0.4),
            highlightColor: AppColors.primary.withValues(alpha: 0.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (active || _isPressed)
                    ? AppColors.primary.withValues(alpha: currentGlow)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (active || _isPressed)
                      ? AppColors.primary.withValues(alpha: 0.8)
                      : Colors.transparent,
                  width: (active || _isPressed) ? 2.0 : 1.0,
                ),
                boxShadow: (active || _isPressed)
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      key: ValueKey('${widget.title}_$active'),
                      color: (active || _isPressed) ? AppColors.primary : Colors.grey.shade700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (active || _isPressed) ? FontWeight.bold : FontWeight.w500,
                        color: (active || _isPressed) ? AppColors.primary : const Color(0xFF374151),
                      ),
                    ),
                  ),
                  if (active || _isPressed)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 6,
                            spreadRadius: 1.5,
                          )
                        ],
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
}

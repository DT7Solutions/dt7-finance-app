import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/app_notification_icon_button.dart';
import '../widgets/custom_button.dart';
import '02_login_screen.dart';
import '05_allocate_budget_screen.dart';
import '08_my_expenses_screen.dart';
import '11_approvals_screen.dart';
import '13_reports_screen.dart';
import '14_activity_log_screen.dart';
import '15_profile_screen.dart';

import '03_dashboard_screen.dart';
import '16_roles_screen.dart';
import '../models/role_model.dart';

class UsersScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const UsersScreen({super.key, this.onBackPressed});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<UserModel> _users = [];
  String _roleFilter = 'All';
  String _searchQuery = '';

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 16.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
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
                            'Filter Users',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Filter by Role:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Founder', 'Admin', 'Employee'].map((role) {
                          final isSel = _roleFilter == role;
                          return ChoiceChip(
                            label: Text(role),
                            selected: isSel,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.primary : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setSheetState(() => _roleFilter = role);
                              setState(() => _roleFilter = role);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: CustomButton(
                          text: 'Apply Filter',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Over Budget Alert',
      'message': '2 departments have exceeded their monthly allocated budget limits.',
      'time': '10m ago',
      'type': 'warning',
      'isRead': false,
    },
    {
      'id': 2,
      'title': 'Pending Expense Request',
      'message': 'Travel expense of ₹15,000 submitted for review.',
      'time': '45m ago',
      'type': 'expense',
      'isRead': false,
    },
    {
      'id': 3,
      'title': 'New User Onboarded',
      'message': 'Rahul Sharma joined the Finance team.',
      'time': '2h ago',
      'type': 'user',
      'isRead': false,
    },
  ];

  int get _unreadCount => _notifications.where((n) => !n['isRead']).length;

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_unreadCount new',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            _markAllAsRead();
                            setModalState(() {});
                          },
                          child: const Text(
                            'Mark all as read',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _notifications.isEmpty
                        ? Center(
                            child: Text(
                              'No notifications',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              final isUnread = !(item['isRead'] as bool);

                              IconData itemIcon;
                              Color iconBg;
                              Color iconColor;

                              switch (item['type']) {
                                case 'warning':
                                  itemIcon = Icons.warning_amber_rounded;
                                  iconBg = const Color(0xFFFEF2F2);
                                  iconColor = const Color(0xFFEF4444);
                                  break;
                                case 'expense':
                                  itemIcon = Icons.receipt_long_rounded;
                                  iconBg = const Color(0xFFEFF6FF);
                                  iconColor = const Color(0xFF3B82F6);
                                  break;
                                case 'user':
                                  itemIcon = Icons.person_add_rounded;
                                  iconBg = const Color(0xFFECFDF5);
                                  iconColor = const Color(0xFF10B981);
                                  break;
                                default:
                                  itemIcon = Icons.info_outline_rounded;
                                  iconBg = const Color(0xFFFFF7ED);
                                  iconColor = AppColors.primary;
                              }

                              return InkWell(
                                onTap: () {
                                  _markAsRead(item['id'] as int);
                                  setModalState(() {});
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isUnread ? Colors.orange.shade50.withValues(alpha: 0.3) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isUnread ? const Color(0xFFFFD4C0) : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: iconBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(itemIcon, color: iconColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item['title'] as String,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                      color: const Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  item['time'] as String,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['message'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
      });
    }
  }

  void _showAddUserModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'password123');
    final amountCtrl = TextEditingController();
    String selectedRole = 'EMPLOYEE';
    bool obscurePassword = true;
    List<RoleModel> availableRoles = [];
    bool isRolesLoading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isRolesLoading) {
            ApiService.getRoles().then((roles) {
              if (ctx.mounted) {
                setModalState(() {
                  availableRoles = roles;
                  isRolesLoading = false;
                  if (roles.isNotEmpty && !roles.any((r) => r.code == selectedRole)) {
                    selectedRole = roles.first.code;
                  }
                });
              }
            });
          }

          return SafeArea(
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
                          'Add New User',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g. Neha Singh',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'e.g. neha@dt7.agency',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'User Password',
                        hintText: 'Create a custom password for user',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setModalState(() => obscurePassword = !obscurePassword);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: availableRoles.any((r) => r.code == selectedRole) ? selectedRole : (availableRoles.isNotEmpty ? availableRoles.first.code : 'EMPLOYEE'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'User Role',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: (availableRoles.isNotEmpty
                              ? availableRoles
                              : [
                                  RoleModel(id: 1, name: 'Founder', code: 'FOUNDER'),
                                  RoleModel(id: 2, name: 'Admin', code: 'ADMIN'),
                                  RoleModel(id: 3, name: 'Staff', code: 'STAFF'),
                                  RoleModel(id: 4, name: 'Accountant', code: 'ACCOUNTANT'),
                                  RoleModel(id: 5, name: 'Finance Manager', code: 'MANAGER'),
                                  RoleModel(id: 6, name: 'Finance Auditor', code: 'FINANCE'),
                                  RoleModel(id: 7, name: 'Employee', code: 'EMPLOYEE'),
                                ])
                          .map((r) => DropdownMenuItem<String>(
                                value: r.code,
                                child: Text(r.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Initial Allocated Amount (₹)',
                        hintText: 'Enter amount',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: CustomButton(
                        text: 'Create User',
                        onPressed: () async {
                          final fullName = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final password = passwordCtrl.text.trim();
                          final initAlloc = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                          if (fullName.isEmpty || email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter full name and email address'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          if (password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a password for the new user'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final uname = email.split('@').first.replaceAll('.', '_');

                          await ApiService.addUser(
                            username: uname,
                            email: email,
                            password: password,
                            fullName: fullName,
                            role: selectedRole,
                            allocatedAmount: initAlloc,
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            _loadUsers();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('User "$fullName" created with role $selectedRole! Budget allocated: ₹${initAlloc.toStringAsFixed(0)}'),
                                duration: const Duration(seconds: 5),
                                backgroundColor: AppColors.approvedGreen,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditUserModal(UserModel user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email);
    final passwordCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: user.allocatedAmount.toStringAsFixed(0));
    String selectedRole = user.role.isNotEmpty ? user.role : (user.isAdmin ? 'ADMIN' : 'EMPLOYEE');
    bool obscureEditPassword = true;
    List<RoleModel> availableRoles = [];
    bool isRolesLoading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isRolesLoading) {
            ApiService.getRoles().then((roles) {
              if (ctx.mounted) {
                setModalState(() {
                  availableRoles = roles;
                  isRolesLoading = false;
                  if (roles.isNotEmpty && !roles.any((r) => r.code == selectedRole)) {
                    selectedRole = roles.first.code;
                  }
                });
              }
            });
          }

          return SafeArea(
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
                        Text(
                          'Edit User (${user.firstName})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: availableRoles.any((r) => r.code == selectedRole) ? selectedRole : (availableRoles.isNotEmpty ? availableRoles.first.code : 'EMPLOYEE'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'User Role',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: (availableRoles.isNotEmpty
                              ? availableRoles
                              : [
                                  RoleModel(id: 1, name: 'Founder', code: 'FOUNDER'),
                                  RoleModel(id: 2, name: 'Admin', code: 'ADMIN'),
                                  RoleModel(id: 3, name: 'Staff', code: 'STAFF'),
                                  RoleModel(id: 4, name: 'Accountant', code: 'ACCOUNTANT'),
                                  RoleModel(id: 5, name: 'Finance Manager', code: 'MANAGER'),
                                  RoleModel(id: 6, name: 'Finance Auditor', code: 'FINANCE'),
                                  RoleModel(id: 7, name: 'Employee', code: 'EMPLOYEE'),
                                ])
                          .map((r) => DropdownMenuItem<String>(
                                value: r.code,
                                child: Text(r.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscureEditPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password (Optional)',
                        hintText: 'Leave blank to keep unchanged',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureEditPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureEditPassword = !obscureEditPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Allocated Amount (₹)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: CustomButton(
                        text: 'Save Changes',
                        onPressed: () async {
                          final fullName = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final allocated = double.tryParse(amountCtrl.text.trim()) ?? user.allocatedAmount;

                          if (fullName.isEmpty || email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          await ApiService.updateUser(
                            id: user.id,
                            fullName: fullName,
                            email: email,
                            role: selectedRole,
                            allocatedAmount: allocated,
                            password: passwordCtrl.text.trim().isNotEmpty ? passwordCtrl.text.trim() : null,
                          );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _loadUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('User "$fullName" updated successfully!'),
                              backgroundColor: AppColors.approvedGreen,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete User Account', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleDeleteUser(user);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  }

  Future<void> _handleDeleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
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
              child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Confirm User Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete user "${user.fullName}"?',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${user.email}\nThis operation will remove the user account and revoke all access. This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteUser(user.id);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "${user.fullName}" deleted successfully!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var rawList = _users.isNotEmpty
        ? _users
        : [
            UserModel(id: 1, username: 'john_doe', email: 'john.doe@example.com', firstName: 'John', lastName: 'Doe', allocatedAmount: 10000, role: 'FOUNDER'),
            UserModel(id: 2, username: 'rahul_sharma', email: 'rahul@example.com', firstName: 'Rahul', lastName: 'Sharma', allocatedAmount: 20000, role: 'EMPLOYEE'),
            UserModel(id: 3, username: 'priya_patel', email: 'priya@example.com', firstName: 'Priya', lastName: 'Patel', allocatedAmount: 15000, role: 'EMPLOYEE'),
            UserModel(id: 4, username: 'amit_verma', email: 'amit@example.com', firstName: 'Amit', lastName: 'Verma', allocatedAmount: 5000, role: 'EMPLOYEE'),
            UserModel(id: 5, username: 'neha_singh', email: 'neha@example.com', firstName: 'Neha', lastName: 'Singh', allocatedAmount: 8000, role: 'EMPLOYEE'),
          ];

    if (_searchQuery.isNotEmpty) {
      rawList = rawList.where((u) =>
        u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        u.email.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    if (_roleFilter != 'All') {
      rawList = rawList.where((u) {
        if (_roleFilter == 'Founder') return u.isFounder || u.role == 'FOUNDER' || u.username.toLowerCase().contains('founder');
        if (_roleFilter == 'Admin') return u.isAdmin || u.role == 'ADMIN' || u.username.toLowerCase().contains('admin');
        if (_roleFilter == 'Employee') return u.role == 'EMPLOYEE' || (!u.isAdmin && !u.isFounder && u.role != 'ADMIN' && u.role != 'FOUNDER');
        return true;
      }).toList();
    }

    final displayUsers = rawList;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(currentRoute: 'users'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Top Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppHeaderIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () {
                      if (widget.onBackPressed != null) {
                        widget.onBackPressed!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const FounderDashboardScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const Text(
                    'Users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  AppNotificationIconButton(
                    unreadCount: _unreadCount,
                    onTap: () => _showNotificationsModal(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar & Functional Filter Icon
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _showFilterSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _roleFilter != 'All' ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _roleFilter != 'All' ? AppColors.primary : Colors.grey.shade200,
                        ),
                      ),
                      child: Icon(
                        Icons.tune,
                        size: 20,
                        color: _roleFilter != 'All' ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RolesScreen()));
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings_outlined, size: 18, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Roles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
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
                    final isOverspent = u.remainingAmount < 0 || (u.usedAmount > u.allocatedAmount && u.allocatedAmount > 0);
                    final overspendAmt = (u.usedAmount - u.allocatedAmount).clamp(0.0, double.infinity);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOverspent ? const Color(0xFFFEF2F2) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOverspent ? const Color(0xFFFCA5A5) : Colors.grey.shade100,
                          width: isOverspent ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isOverspent ? Colors.red.shade100 : AppColors.primaryLight,
                            child: Icon(
                              isOverspent ? Icons.warning_amber_rounded : Icons.person,
                              color: isOverspent ? Colors.redAccent : AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(u.email, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                if (isOverspent) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Over Budget by ₹${overspendAmt.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Allocated: ₹${u.allocatedAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                u.role,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: u.isFounder ? Colors.purple : (u.isAdmin || u.role == 'ADMIN' ? AppColors.primary : AppColors.approvedGreen),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Used: ₹${u.usedAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isOverspent ? Colors.redAccent : Colors.grey.shade600,
                                  fontWeight: isOverspent ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                isOverspent ? 'Remaining: -₹${overspendAmt.toStringAsFixed(0)}' : 'Available: ₹${u.remainingAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOverspent ? Colors.redAccent : AppColors.approvedGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                            onPressed: () => _showEditUserModal(u),
                            tooltip: 'Edit User',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _handleDeleteUser(u),
                            tooltip: 'Delete User',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Add User Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _showAddUserModal,
                  child: const Center(
                    child: Text(
                      '+ Add User',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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

class _DrawerTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF374151),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../models/role_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/custom_button.dart';

class RolesScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const RolesScreen({super.key, this.onBackPressed});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<RoleModel> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    final roles = await ApiService.getRoles();
    if (mounted) {
      setState(() {
        _roles = roles;
        _isLoading = false;
      });
    }
  }

  void _showAddEditRoleModal([RoleModel? roleToEdit]) {
    final nameCtrl = TextEditingController(text: roleToEdit?.name ?? '');
    final codeCtrl = TextEditingController(text: roleToEdit?.code ?? '');
    final descCtrl = TextEditingController(text: roleToEdit?.description ?? '');

    bool viewAll = roleToEdit?.canViewAllExpenses ?? false;
    bool approve = roleToEdit?.canApproveExpenses ?? false;
    bool allocate = roleToEdit?.canAllocateBudget ?? false;
    bool manageUsers = roleToEdit?.canManageUsers ?? false;
    bool analytics = roleToEdit?.canViewAnalytics ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
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
                        roleToEdit == null ? 'Create New Role' : 'Edit Role (${roleToEdit.name})',
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
                      labelText: 'Role Name',
                      hintText: 'e.g. Regional Manager',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    enabled: roleToEdit == null || !roleToEdit.isSystemRole,
                    decoration: InputDecoration(
                      labelText: 'Role Code',
                      hintText: 'e.g. REGIONAL_MGR',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe access permissions for this role',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Role Permissions',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('View All Company Expenses'),
                    subtitle: const Text('Allow viewing expenses from all users across teams'),
                    value: viewAll,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => viewAll = val),
                  ),
                  SwitchListTile(
                    title: const Text('Approve Expenses & Requests'),
                    subtitle: const Text('Can approve or reject pending expenses & budget requests'),
                    value: approve,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => approve = val),
                  ),
                  SwitchListTile(
                    title: const Text('Allocate Employee Budgets'),
                    subtitle: const Text('Can allocate and update budget limits for employees'),
                    value: allocate,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => allocate = val),
                  ),
                  SwitchListTile(
                    title: const Text('Manage Users & Roles'),
                    subtitle: const Text('Can create, edit, or delete user accounts and roles'),
                    value: manageUsers,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => manageUsers = val),
                  ),
                  SwitchListTile(
                    title: const Text('View Analytics & Financial Reports'),
                    subtitle: const Text('Access to financial dashboards, leaderboard, and audit logs'),
                    value: analytics,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => analytics = val),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: CustomButton(
                      text: roleToEdit == null ? 'Create Role' : 'Save Changes',
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final code = codeCtrl.text.trim().toUpperCase().replaceAll(' ', '_');

                        if (name.isEmpty || code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter role name and code'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final roleObj = RoleModel(
                          id: roleToEdit?.id ?? 0,
                          name: name,
                          code: code,
                          description: descCtrl.text.trim(),
                          isSystemRole: roleToEdit?.isSystemRole ?? false,
                          canViewAllExpenses: viewAll,
                          canApproveExpenses: approve,
                          canAllocateBudget: allocate,
                          canManageUsers: manageUsers,
                          canViewAnalytics: analytics,
                        );

                        if (roleToEdit == null) {
                          await ApiService.createRole(roleObj);
                        } else {
                          await ApiService.updateRole(roleObj);
                        }

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _loadRoles();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(roleToEdit == null ? 'Role "$name" created successfully!' : 'Role "$name" updated!'),
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
        ),
      ),
    );
  }

  Future<void> _deleteRole(RoleModel role) async {
    if (role.isSystemRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System default roles cannot be deleted.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete role "${role.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteRole(role.id);
      _loadRoles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(currentRoute: 'roles'),
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
                    icon: Icons.menu,
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Text(
                    'Roles & Permissions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                    onPressed: () => _showAddEditRoleModal(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView.separated(
                        itemCount: _roles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final role = _roles[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          role.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (role.isSystemRole)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'SYSTEM',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                          onPressed: () => _showAddEditRoleModal(role),
                                        ),
                                        if (!role.isSystemRole)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            onPressed: () => _deleteRole(role),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (role.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    role.description,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _buildPermBadge('View All Expenses', role.canViewAllExpenses),
                                    _buildPermBadge('Approve Requests', role.canApproveExpenses),
                                    _buildPermBadge('Allocate Budget', role.canAllocateBudget),
                                    _buildPermBadge('Manage Users', role.canManageUsers),
                                    _buildPermBadge('Analytics & Reports', role.canViewAnalytics),
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

  Widget _buildPermBadge(String label, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isEnabled ? Colors.green.shade200 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isEnabled ? AppColors.approvedGreen : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
              color: isEnabled ? const Color(0xFF065F46) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

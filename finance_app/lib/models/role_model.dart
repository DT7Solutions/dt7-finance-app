class RoleModel {
  final int id;
  final String name;
  final String code;
  final String description;
  final bool isSystemRole;
  final bool canViewAllExpenses;
  final bool canApproveExpenses;
  final bool canAllocateBudget;
  final bool canManageUsers;
  final bool canViewAnalytics;

  RoleModel({
    required this.id,
    required this.name,
    required this.code,
    this.description = '',
    this.isSystemRole = false,
    this.canViewAllExpenses = false,
    this.canApproveExpenses = false,
    this.canAllocateBudget = false,
    this.canManageUsers = false,
    this.canViewAnalytics = false,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Employee',
      code: json['code']?.toString() ?? 'EMPLOYEE',
      description: json['description']?.toString() ?? '',
      isSystemRole: json['is_system_role'] == true,
      canViewAllExpenses: json['can_view_all_expenses'] == true,
      canApproveExpenses: json['can_approve_expenses'] == true,
      canAllocateBudget: json['can_allocate_budget'] == true,
      canManageUsers: json['can_manage_users'] == true,
      canViewAnalytics: json['can_view_analytics'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'is_system_role': isSystemRole,
      'can_view_all_expenses': canViewAllExpenses,
      'can_approve_expenses': canApproveExpenses,
      'can_allocate_budget': canAllocateBudget,
      'can_manage_users': canManageUsers,
      'can_view_analytics': canViewAnalytics,
    };
  }
}

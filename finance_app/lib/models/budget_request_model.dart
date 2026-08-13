class BudgetRequestModel {
  final int id;
  final String userName;
  final double requestAmount;
  final String categoryName;
  final String reason;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final String createdAt;

  BudgetRequestModel({
    required this.id,
    required this.userName,
    required this.requestAmount,
    required this.categoryName,
    required this.reason,
    this.status = 'PENDING',
    required this.createdAt,
  });

  factory BudgetRequestModel.fromJson(Map<String, dynamic> json) {
    String uName = (json['user_name'] ?? json['userName'] ?? json['employee_name'] ?? json['submitted_by'] ?? '').toString();
    if (uName.isEmpty && json['user'] != null) {
      final u = json['user'];
      if (u is Map) {
        uName = (u['username'] ?? u['full_name'] ?? u['first_name'] ?? u['email'] ?? '').toString();
      } else if (u is String && u.trim().isNotEmpty) {
        uName = u.trim();
      }
    }
    if (uName.isEmpty) uName = 'Employee';

    final cat = json['category_name'] ?? json['categoryName'] ?? (json['category'] is Map ? json['category']['name'] : null);

    return BudgetRequestModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      userName: uName,
      requestAmount: double.tryParse(json['request_amount']?.toString() ?? json['requestAmount']?.toString() ?? json['amount']?.toString() ?? '0') ?? 0.0,
      categoryName: (cat != null && cat.toString().trim().isNotEmpty) ? cat.toString() : 'General',
      reason: (json['reason'] ?? json['description'] ?? json['note'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? json['date'] ?? '').toString(),
    );
  }

  String get formattedDate {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final m = months[dt.month - 1];
      final d = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d $m ${dt.year}, $hour:$min $ampm';
    } catch (_) {
      return createdAt;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'request_amount': requestAmount,
      'category_name': categoryName,
      'reason': reason,
      'status': status,
      'created_at': createdAt,
    };
  }
}

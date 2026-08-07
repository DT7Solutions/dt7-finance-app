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
    return BudgetRequestModel(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? json['userName'] ?? '',
      requestAmount: double.tryParse(json['request_amount']?.toString() ?? json['requestAmount']?.toString() ?? '0') ?? 0.0,
      categoryName: json['category_name'] ?? json['categoryName'] ?? 'General',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
    );
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

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
      userName: json['user_name'] ?? '',
      requestAmount: double.tryParse(json['request_amount'].toString()) ?? 0.0,
      categoryName: json['category_name'] ?? 'General',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] ?? '',
    );
  }
}

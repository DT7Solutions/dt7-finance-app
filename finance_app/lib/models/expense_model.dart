class ExpenseModel {
  final int id;
  final String title;
  final double amount;
  final int? categoryId;
  final String categoryName;
  final String categoryColor;
  final String userName;
  final String description;
  final String dateTime;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final String paymentMode;
  final String? receiptImage;
  final String approvedBy;
  final String approvalDate;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    this.categoryId,
    this.categoryName = 'General',
    this.categoryColor = '#FF5500',
    this.userName = '',
    this.description = '',
    required this.dateTime,
    this.status = 'PENDING',
    this.paymentMode = 'Cash',
    this.receiptImage,
    this.approvedBy = '',
    this.approvalDate = '',
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      categoryId: json['category'],
      categoryName: json['category_name'] ?? (json['category_details'] is Map ? json['category_details']['name'] : 'General'),
      categoryColor: json['category_color'] ?? '#FF5500',
      userName: json['user_name'] ?? (json['employee_name'] ?? ''),
      description: json['description'] ?? json['note'] ?? '',
      dateTime: json['date_time'] ?? json['created_at'] ?? json['date'] ?? '',
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      paymentMode: json['payment_mode'] ?? 'Cash',
      receiptImage: json['receipt_image'] ?? json['receipt'] ?? json['bill_image'],
      approvedBy: json['approved_by'] ?? json['reviewed_by'] ?? '',
      approvalDate: json['approval_date'] ?? json['reviewed_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': categoryId,
      'category_name': categoryName,
      'category_color': categoryColor,
      'user_name': userName,
      'description': description,
      'date_time': dateTime,
      'status': status,
      'payment_mode': paymentMode,
      'receipt_image': receiptImage,
      'approved_by': approvedBy,
      'approval_date': approvalDate,
    };
  }

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
}

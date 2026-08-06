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
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      categoryId: json['category'],
      categoryName: json['category_name'] ?? 'General',
      categoryColor: json['category_color'] ?? '#FF5500',
      userName: json['user_name'] ?? '',
      description: json['description'] ?? '',
      dateTime: json['date_time'] ?? '',
      status: json['status'] ?? 'PENDING',
      paymentMode: json['payment_mode'] ?? 'Cash',
      receiptImage: json['receipt_image'],
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
    };
  }

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
}

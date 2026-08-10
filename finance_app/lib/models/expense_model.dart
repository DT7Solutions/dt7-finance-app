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
    String extractUserName(Map<String, dynamic> json) {
      if (json['user_name'] != null && json['user_name'].toString().trim().isNotEmpty) {
        return json['user_name'].toString();
      }
      if (json['employee_name'] != null && json['employee_name'].toString().trim().isNotEmpty) {
        return json['employee_name'].toString();
      }
      if (json['created_by'] != null && json['created_by'].toString().trim().isNotEmpty) {
        return json['created_by'].toString();
      }
      if (json['submitted_by'] != null && json['submitted_by'].toString().trim().isNotEmpty) {
        return json['submitted_by'].toString();
      }
      if (json['user'] != null) {
        final u = json['user'];
        if (u is Map) {
          return (u['username'] ?? u['full_name'] ?? u['first_name'] ?? u['email'] ?? '').toString();
        } else if (u is String && u.trim().isNotEmpty) {
          return u;
        }
      }
      if (json['employee'] != null) {
        final emp = json['employee'];
        if (emp is Map) {
          return (emp['username'] ?? emp['full_name'] ?? emp['first_name'] ?? emp['email'] ?? '').toString();
        } else if (emp is String && emp.trim().isNotEmpty) {
          return emp;
        }
      }
      return '';
    }

    return ExpenseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      categoryId: json['category'] is int ? json['category'] : null,
      categoryName: json['category_name'] ?? (json['category_details'] is Map ? json['category_details']['name'] : 'General'),
      categoryColor: json['category_color'] ?? '#FF5500',
      userName: extractUserName(json),
      description: json['description'] ?? json['note'] ?? '',
      dateTime: (json['date_time'] ?? json['created_at'] ?? json['date'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      paymentMode: json['payment_mode'] ?? 'Cash',
      receiptImage: json['receipt_image'] ?? json['receipt'] ?? json['bill_image'],
      approvedBy: (json['approved_by'] ?? json['reviewed_by'] ?? '').toString(),
      approvalDate: (json['approval_date'] ?? json['reviewed_at'] ?? '').toString(),
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

  String get formattedDate {
    if (dateTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateTime).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final m = months[dt.month - 1];
      final d = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d $m ${dt.year}, $hour:$min $ampm';
    } catch (_) {
      return dateTime;
    }
  }

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
}

import 'category_model.dart';

class TransactionModel {
  final int id;
  final int accountId;
  final String accountName;
  final int? categoryId;
  final CategoryModel? categoryDetail;
  final String title;
  final double amount;
  final String transactionType; // INCOME, EXPENSE, TRANSFER
  final String date;
  final String? notes;

  TransactionModel({
    required this.id,
    required this.accountId,
    this.accountName = '',
    this.categoryId,
    this.categoryDetail,
    required this.title,
    required this.amount,
    required this.transactionType,
    required this.date,
    this.notes,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      accountId: json['account'] is int ? json['account'] : (json['account']?['id'] ?? 0),
      accountName: json['account_name'] ?? '',
      categoryId: json['category'],
      categoryDetail: json['category_detail'] != null 
          ? CategoryModel.fromJson(json['category_detail']) 
          : null,
      title: json['title'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      transactionType: json['transaction_type'] ?? 'EXPENSE',
      date: json['date'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account': accountId,
      'category': categoryId,
      'title': title,
      'amount': amount,
      'transaction_type': transactionType,
      'date': date,
      'notes': notes,
    };
  }

  bool get isIncome => transactionType == 'INCOME';
}

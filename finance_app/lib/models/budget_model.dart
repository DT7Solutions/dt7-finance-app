import 'category_model.dart';

class BudgetModel {
  final int id;
  final int categoryId;
  final CategoryModel? categoryDetail;
  final double limitAmount;
  final String monthYear;
  final double spentAmount;
  final double remainingAmount;

  BudgetModel({
    required this.id,
    required this.categoryId,
    this.categoryDetail,
    required this.limitAmount,
    required this.monthYear,
    this.spentAmount = 0.0,
    this.remainingAmount = 0.0,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? 0,
      categoryId: json['category'] is int ? json['category'] : (json['category']?['id'] ?? 0),
      categoryDetail: json['category_detail'] != null 
          ? CategoryModel.fromJson(json['category_detail']) 
          : null,
      limitAmount: double.tryParse(json['limit_amount'].toString()) ?? 0.0,
      monthYear: json['month_year'] ?? '',
      spentAmount: double.tryParse(json['spent_amount'].toString()) ?? 0.0,
      remainingAmount: double.tryParse(json['remaining_amount'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': categoryId,
      'limit_amount': limitAmount,
      'month_year': monthYear,
    };
  }

  double get percentageSpent {
    if (limitAmount <= 0) return 0.0;
    final ratio = spentAmount / limitAmount;
    return ratio > 1.0 ? 1.0 : ratio;
  }
}

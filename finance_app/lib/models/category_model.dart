class CategoryModel {
  final int id;
  final String name;
  final String type; // 'INCOME' or 'EXPENSE'
  final String icon;
  final String color;
  final bool isCustom;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'EXPENSE',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#4F46E5',
      isCustom: json['is_custom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_custom': isCustom,
    };
  }
}

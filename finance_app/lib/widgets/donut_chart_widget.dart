import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DonutChartWidget extends StatelessWidget {
  final double totalExpenses;
  final List<Map<String, dynamic>>? customCategories;

  const DonutChartWidget({
    super.key,
    required this.totalExpenses,
    this.customCategories,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final defaultCategories = [
      {
        'name': 'Travel',
        'pct': 35,
        'color': const Color(0xFFFF5500), // Vibrant Orange
      },
      {
        'name': 'Food',
        'pct': 25,
        'color': const Color(0xFFF59E0B), // Warm Amber
      },
      {
        'name': 'Fuel',
        'pct': 18,
        'color': const Color(0xFF2563EB), // Royal Blue
      },
      {
        'name': 'Office',
        'pct': 12,
        'color': const Color(0xFF10B981), // Emerald Green
      },
      {
        'name': 'Others',
        'pct': 10,
        'color': const Color(0xFF8B5CF6), // Purple
      },
    ];

    final categories = customCategories ?? defaultCategories;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Donut Chart Container
        SizedBox(
          height: 130,
          width: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 38,
                  startDegreeOffset: 270,
                  sections: categories.map((cat) {
                    final catColor = cat['color'] as Color;
                    return PieChartSectionData(
                      color: catColor,
                      value: (cat['pct'] as num).toDouble(),
                      title: '',
                      radius: 20,
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatCurrency(totalExpenses),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Expenses',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Legend List with Exact Matching Colors
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: categories.map((cat) {
              final catColor = cat['color'] as Color;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: catColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cat['pct']}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

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
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 46,
                  startDegreeOffset: 270,
                  sections: categories.map((cat) {
                    final catColor = cat['color'] as Color;
                    return PieChartSectionData(
                      color: catColor,
                      value: (cat['pct'] as num).toDouble(),
                      title: '',
                      radius: 22,
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatCurrency(totalExpenses),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Expenses',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Legend List with Exact Matching Colors
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: categories.map((cat) {
              final catColor = cat['color'] as Color;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${cat['pct']}%',
                      style: const TextStyle(
                        fontSize: 13,
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

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class DonutChartWidget extends StatelessWidget {
  final double totalExpenses;

  const DonutChartWidget({Key? key, required this.totalExpenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Travel', 'pct': 40, 'color': const Color(0xFF3B82F6)},
      {'name': 'Food', 'pct': 20, 'color': const Color(0xFF10B981)},
      {'name': 'Fuel', 'pct': 15, 'color': const Color(0xFFF59E0B)},
      {'name': 'Office', 'pct': 10, 'color': AppColors.primary},
      {'name': 'Others', 'pct': 15, 'color': const Color(0xFF8B5CF6)},
    ];

    return Row(
      children: [
        // Donut Chart Container
        SizedBox(
          height: 140,
          width: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 42,
                  sections: categories.map((cat) {
                    return PieChartSectionData(
                      color: cat['color'] as Color,
                      value: (cat['pct'] as int).toDouble(),
                      title: '',
                      radius: 20,
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${totalExpenses.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Total Expenses',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Legend List
        Expanded(
          child: Column(
            children: categories.map((cat) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: cat['color'] as Color),
                        const SizedBox(width: 8),
                        Text(cat['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text('${cat['pct']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

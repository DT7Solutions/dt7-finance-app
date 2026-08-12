import 'package:flutter/material.dart';
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
    if (amount.isNaN || amount.isInfinite) return '₹0';
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  static final List<Color> _palette = [
    const Color(0xFFFF5500), // Vibrant Orange
    const Color(0xFF2563EB), // Royal Blue
    const Color(0xFF10B981), // Emerald Green
    const Color(0xFFF59E0B), // Warm Amber
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF43F5E), // Rose
    const Color(0xFFD97706), // Warm Bronze
    const Color(0xFF64748B), // Slate
  ];

  Color _parseColor(dynamic colorVal, int fallbackIndex) {
    if (colorVal is Color) return colorVal;
    if (colorVal is String && colorVal.trim().isNotEmpty) {
      final hex = colorVal.replaceAll('#', '').trim();
      if (hex.length == 6 || hex.length == 8) {
        try {
          final hexToUse = hex.length == 6 ? 'FF$hex' : hex;
          return Color(int.parse(hexToUse, radix: 16));
        } catch (_) {}
      }
    }
    return _palette[fallbackIndex % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final defaultCategories = [
      {
        'name': 'Travel',
        'pct': 35,
        'color': const Color(0xFFFF5500),
      },
      {
        'name': 'Food',
        'pct': 25,
        'color': const Color(0xFFF59E0B),
      },
      {
        'name': 'Fuel',
        'pct': 18,
        'color': const Color(0xFF2563EB),
      },
      {
        'name': 'Office',
        'pct': 12,
        'color': const Color(0xFF10B981),
      },
      {
        'name': 'Others',
        'pct': 10,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    final rawCategories = (customCategories != null && customCategories!.isNotEmpty)
        ? customCategories!
        : defaultCategories;

    // Resolve unique color mapping per category index
    final Set<int> usedColors = {};
    final List<Map<String, dynamic>> categories = [];
    for (int i = 0; i < rawCategories.length; i++) {
      final item = Map<String, dynamic>.from(rawCategories[i]);
      Color c = _parseColor(item['color'], i);
      if (usedColors.contains(c.toARGB32())) {
        c = _palette[i % _palette.length];
      }
      usedColors.add(c.toARGB32());
      item['color'] = c;
      categories.add(item);
    }

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
              CustomPaint(
                size: const Size(130, 130),
                painter: _DonutChartPainter(
                  categories: categories,
                  colorParser: _parseColor,
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

        // Legend List with Safe Parsing
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: categories.asMap().entries.map((entry) {
              final index = entry.key;
              final cat = entry.value;
              final catColor = _parseColor(cat['color'], index);
              final name = (cat['name'] ?? cat['category'] ?? 'General').toString();
              final pct = (num.tryParse((cat['pct'] ?? cat['percentage'])?.toString() ?? '') ?? 0).toInt();

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
                        name,
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
                      '$pct%',
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

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final Color Function(dynamic colorVal, int index) colorParser;

  _DonutChartPainter({required this.categories, required this.colorParser});

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 16.0;
    final radius = (size.width - strokeWidth) / 2;

    double totalPct = 0;
    for (var cat in categories) {
      final p = (num.tryParse((cat['pct'] ?? cat['percentage'])?.toString() ?? '') ?? 0).toDouble();
      totalPct += p > 0 ? p : 1.0;
    }
    if (totalPct <= 0 || totalPct.isNaN || totalPct.isInfinite) totalPct = 1.0;

    double startAngle = -1.5707963267948966; // -90 degrees (top)

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final p = (num.tryParse((cat['pct'] ?? cat['percentage'])?.toString() ?? '') ?? 0).toDouble();
      final pctVal = p > 0 ? p : 1.0;
      double sweepAngle = (pctVal / totalPct) * 2 * 3.141592653589793;
      if (sweepAngle.isNaN || sweepAngle.isInfinite) sweepAngle = 0.1;

      final paint = Paint()
        ..color = colorParser(cat['color'], i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      final drawSweep = (sweepAngle - 0.04).clamp(0.001, 6.28);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        drawSweep,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

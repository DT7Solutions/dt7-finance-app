import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final String categoryName;
  final double spent;
  final double limit;

  const BudgetProgressBar({
    Key? key,
    required this.categoryName,
    required this.spent,
    required this.limit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > limit;
    final progressColor = isOverBudget
        ? const Color(0xFFEF4444)
        : ratio > 0.8
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isOverBudget ? const Color(0xFFEF4444) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isOverBudget
                ? 'Over budget by ₹${(spent - limit).toStringAsFixed(0)}!'
                : '${((1 - ratio) * 100).toStringAsFixed(0)}% remaining',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
              color: isOverBudget ? const Color(0xFFEF4444) : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

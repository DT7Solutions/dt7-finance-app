import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        bg = AppColors.approvedGreen.withOpacity(0.12);
        fg = AppColors.approvedGreen;
        label = 'Approved';
        break;
      case 'REJECTED':
        bg = AppColors.rejectedRed.withOpacity(0.12);
        fg = AppColors.rejectedRed;
        label = 'Rejected';
        break;
      case 'PENDING':
      default:
        bg = AppColors.pendingOrange.withOpacity(0.12);
        fg = AppColors.pendingOrange;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

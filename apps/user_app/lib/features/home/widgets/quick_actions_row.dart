import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildActionChip(context, Icons.directions_car, 'Offer Ride', isSpecial: true),
          const SizedBox(width: 12),
          _buildActionChip(context, Icons.work, 'Office'),
          const SizedBox(width: 12),
          _buildActionChip(context, Icons.home, 'Home'),
          const SizedBox(width: 12),
          _buildActionChip(context, Icons.airplanemode_active, 'Airport'),
          const SizedBox(width: 12),
          _buildActionChip(context, Icons.add, 'Add Place', isAdd: true),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, IconData icon, String label,
      {bool isAdd = false, bool isSpecial = false}) {
    return InkWell(
      onTap: () {
        if (isSpecial) context.push('/offer-ride');
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSpecial
              ? AppColors.accentCoral
              : (isAdd ? Colors.white : AppColors.primaryNavy),
          borderRadius: BorderRadius.circular(24),
          border: isAdd ? Border.all(color: AppColors.grey.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: (isAdd || isSpecial) ? Colors.white : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

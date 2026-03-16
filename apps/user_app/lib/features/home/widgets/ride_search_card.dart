import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';

class RideSearchCard extends StatelessWidget {
  const RideSearchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocationField(
            icon: Icons.my_location,
            label: 'From',
            value: 'Current Location',
            isSource: true,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 44),
            child: Divider(height: 1),
          ),
          _buildLocationField(
            icon: Icons.location_on,
            label: 'To',
            value: 'Where to?',
            isSource: false,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSelector(
                  icon: Icons.calendar_today,
                  label: 'Today, Now',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelector(
                  icon: Icons.person,
                  label: '1 Passenger',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Find Rides',
            onPressed: () => context.push('/rides'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required IconData icon,
    required String label,
    required String value,
    required bool isSource,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isSource ? AppColors.trustBlue : AppColors.accentCoral),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
          if (isSource)
            const Icon(Icons.swap_vert, color: AppColors.grey)
        ],
      ),
    );
  }

  Widget _buildSelector({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryNavy),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

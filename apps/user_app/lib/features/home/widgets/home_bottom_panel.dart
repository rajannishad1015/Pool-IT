import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';

class HomeBottomPanel extends StatelessWidget {
  const HomeBottomPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          const Text(
            'Where are you going?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 16),
          // Location Inputs
          _buildInput(
            onTap: () {}, // Trigger location picker
            icon: Icons.radio_button_checked,
            iconColor: Colors.orange,
            text: 'My Current Location',
            isPlaceholder: false,
          ),
          const SizedBox(height: 10),
          _buildInput(
            onTap: () => context.push('/rides'), // Simulated search trigger
            icon: Icons.location_on,
            iconColor: Colors.redAccent,
            text: 'Enter destination',
            isPlaceholder: true,
          ),
          const SizedBox(height: 10),
          // Time Selectors
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  onTap: () {}, // Open Date Picker
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.trustBlue,
                  text: 'Today',
                  isPlaceholder: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  onTap: () {}, // Open Time Picker
                  icon: Icons.access_time,
                  iconColor: AppColors.trustBlue,
                  text: 'Now',
                  isPlaceholder: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Find Rides',
              onPressed: () => context.push('/rides'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInput({
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isPlaceholder,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Very light grey/blue
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPlaceholder ? Colors.blueGrey : AppColors.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

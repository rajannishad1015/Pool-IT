import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ride Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(Icons.calendar_today, 'Today, 9:15 AM'),
                    const Divider(height: 24),
                    _buildSummaryRow(Icons.directions_car, 'Amit Sharma • Honda City'),
                    const Divider(height: 24),
                    _buildSummaryRow(Icons.event_seat, '1 Seat'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.trustBlue),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.trustBlue.withValues(alpha: 0.05),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.trustBlue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SmartPool Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Balance: ₹1,250', style: TextStyle(fontSize: 12, color: AppColors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: AppColors.trustBlue),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Driver Note (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'e.g. I will wait near the main gate',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Fare', style: TextStyle(fontSize: 18)),
                const Text(
                  '₹85',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accentCoral),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Confirm Booking',
              onPressed: () => _showSuccess(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your seat is successfully reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'View Ride',
              onPressed: () {
                context.pop(); // Close dialog
                context.go('/home'); // Go to home (or active ride)
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryNavy),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/wallet_providers.dart';
import '../../core/providers/ride_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../shared/widgets/primary_button.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? bookingData;

  const BookingConfirmationScreen({super.key, this.bookingData});

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  bool _isConfirming = false;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.bookingData;

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Booking')),
        body: const Center(
          child: Text('No booking data available'),
        ),
      );
    }

    final ride = data['ride'] as Map<String, dynamic>;
    final seats = data['seats'] as int? ?? 1;
    final driver = ride['profiles'] as Map<String, dynamic>?;
    final vehicle = ride['vehicles'] as Map<String, dynamic>?;
    final departureTime = DateTime.parse(ride['departure_time']);
    final baseFare = (ride['base_fare'] as num).toDouble();
    final totalFare = baseFare * seats;

    final dateFormatter = DateFormat('EEE, MMM d');
    final timeFormatter = DateFormat('h:mm a');

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
                    _buildSummaryRow(
                      Icons.calendar_today,
                      '${dateFormatter.format(departureTime)}, ${timeFormatter.format(departureTime)}',
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      Icons.directions_car,
                      '${driver?['full_name'] ?? 'Driver'} • ${vehicle != null ? '${vehicle['make']} ${vehicle['model']}' : 'Vehicle'}',
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      Icons.event_seat,
                      '$seats ${seats == 1 ? 'Seat' : 'Seats'}',
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      Icons.location_on,
                      '${ride['origin_name']} → ${ride['destination_name']}',
                    ),
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
            Consumer(
              builder: (context, ref, child) {
                final balanceAsync = ref.watch(walletBalanceProvider);
                return balanceAsync.when(
                  data: (balance) {
                    final hasEnough = balance >= totalFare;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: hasEnough
                              ? AppColors.trustBlue
                              : Colors.red.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: hasEnough
                            ? AppColors.trustBlue.withValues(alpha: 0.05)
                            : Colors.red.withValues(alpha: 0.05),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color:
                                hasEnough ? AppColors.trustBlue : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SmartPool Wallet',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Balance: ₹${balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasEnough
                                        ? AppColors.grey
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasEnough)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.trustBlue,
                            )
                          else
                            TextButton(
                              onPressed: () => context.push('/wallet'),
                              child: const Text('Top Up'),
                            ),
                        ],
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Error loading balance'),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Driver Note (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'e.g. I will wait near the main gate',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Fare', style: TextStyle(fontSize: 18)),
                Text(
                  '₹${totalFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentCoral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Confirm Booking',
              isLoading: _isConfirming,
              onPressed: () => _confirmBooking(ride, seats, totalFare),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking(
    Map<String, dynamic> ride,
    int seats,
    double totalFare,
  ) async {
    setState(() => _isConfirming = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw 'User not logged in';

      // Process payment
      final walletService = ref.read(walletServiceProvider);
      await walletService.processPayment(
        userId: user.id,
        amount: totalFare,
        rideId: ride['id'],
        description:
            'Ride booking: ${ride['origin_name']} to ${ride['destination_name']}',
      );

      // Create booking
      final rideService = ref.read(rideServiceProvider);
      await rideService.bookRide(
        rideId: ride['id'],
        passengerId: user.id,
        seats: seats,
        fare: totalFare,
      );

      ref.invalidate(walletBalanceProvider);
      if (!mounted) return;
      _showSuccess(context, ride);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _showSuccess(BuildContext context, Map<String, dynamic> ride) {
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
                context.go('/active-ride', extra: {
                  'rideId': ride['id'],
                  'driverId': ride['driver_id'],
                });
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

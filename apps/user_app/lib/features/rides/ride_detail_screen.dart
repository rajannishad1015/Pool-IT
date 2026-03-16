import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ride_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../core/providers/wallet_providers.dart';
import '../../shared/widgets/primary_button.dart';

class RideDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? ride;

  const RideDetailScreen({super.key, this.ride});

  @override
  ConsumerState<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends ConsumerState<RideDetailScreen> {
  int _selectedSeats = 1;
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    if (ride == null) {
      return const Scaffold(body: Center(child: Text('Ride not found')));
    }

    final driver = ride['profiles'] as Map<String, dynamic>?;
    final vehicle = ride['vehicles'] as Map<String, dynamic>?;
    final departureTime = DateTime.parse(ride['departure_time']);
    final availableSeats = ride['seats_available'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryNavy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFE2E8F0),
                child: Stack(
                  children: [
                    // Mock Map Background
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.network(
                          'https://api.mapbox.com/styles/v1/mapbox/light-v10/static/78.9629,20.5937,5/800x400?access_token=pk.dummy', // Placeholder
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.map_rounded, size: 80, color: Colors.blueGrey),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFF1F5F9),
                            backgroundImage: driver?['avatar_url'] != null
                                ? NetworkImage(driver!['avatar_url'])
                                : null,
                            child: driver?['avatar_url'] == null
                                ? const Icon(Icons.person, size: 30, color: AppColors.primaryNavy)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver?['full_name'] ?? 'SmartPool Driver',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                                    Text(
                                      ' ${driver?['trust_score'] ?? '5.0'} ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.verified_rounded, color: AppColors.trustBlue, size: 16),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Verified',
                                      style: TextStyle(color: AppColors.trustBlue, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildActionIcon(Icons.message_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Route & Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    const SizedBox(height: 16),
                    _buildRouteTimeline(ride['origin_name'], ride['destination_name'], departureTime),
                    
                    const SizedBox(height: 24),
                    const Text('Vehicle Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    const SizedBox(height: 12),
                    _buildVehicleTile(
                      vehicle != null ? '${vehicle['make']} ${vehicle['model']}' : 'Standard Vehicle',
                      vehicle != null ? vehicle['plate_number'] : '--',
                      ride['is_ac'] == true,
                    ),

                    const SizedBox(height: 24),
                    const Text('Fare Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    const SizedBox(height: 12),
                    _buildFareCard(ride['base_fare'] as num, _selectedSeats),
                    
                    const SizedBox(height: 24),
                    // Wallet Status
                    _buildWalletStatus(),
                    
                    const SizedBox(height: 140), // Space for bottom sheet
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBookingBottomSheet(availableSeats),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primaryNavy, size: 20),
    );
  }

  Widget _buildRouteTimeline(String origin, String dest, DateTime time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildTimelineItem(origin, '${time.hour}:${time.minute.toString().padLeft(2, '0')}', isDeparture: true),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 1.5,
                height: 30,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),
          _buildTimelineItem(dest, 'ETA +1h', isDeparture: false),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String sub, {required bool isDeparture}) {
    return Row(
      children: [
        Icon(
          isDeparture ? Icons.radio_button_checked : Icons.location_on_rounded,
          size: 16,
          color: isDeparture ? AppColors.trustBlue : AppColors.accentCoral,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primaryNavy),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildVehicleTile(String name, String plate, bool hasAc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.primaryNavy),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryNavy)),
                Text(plate, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ],
            ),
          ),
          if (hasAc)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('AC', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildFareCard(num baseFare, int seats) {
    final total = baseFare * seats;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildFareItem('Price per seat', '₹$baseFare'),
          const SizedBox(height: 12),
          _buildFareItem('Seats', 'x$seats'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryNavy)),
              Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.accentCoral)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareItem(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primaryNavy)),
      ],
    );
  }

  Widget _buildWalletStatus() {
    return Consumer(
      builder: (context, ref, child) {
        final balanceAsync = ref.watch(walletBalanceProvider);
        return balanceAsync.when(
          data: (balance) {
            final totalFare = (widget.ride!['base_fare'] as num) * _selectedSeats;
            final hasEnough = balance >= totalFare;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasEnough ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (hasEnough ? Colors.green : Colors.red).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(hasEnough ? Icons.account_balance_wallet_rounded : Icons.warning_rounded, color: hasEnough ? Colors.green : Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasEnough ? 'Balance: ₹${balance.toStringAsFixed(2)}' : 'Refill needed',
                      style: TextStyle(color: hasEnough ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  if (!hasEnough)
                    InkWell(
                      onTap: () => context.push('/wallet'),
                      child: const Text('Top up', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                    ),
                ],
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildBookingBottomSheet(int available) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Seats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryNavy)),
                  Text('How many seats do you need?', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _selectedSeats = _selectedSeats > 1 ? _selectedSeats - 1 : 1),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text('$_selectedSeats', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (_selectedSeats < available) setState(() => _selectedSeats++);
                      },
                      icon: const Icon(Icons.add, size: 18, color: AppColors.accentCoral),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Confirm Booking',
              isLoading: _isBooking,
              onPressed: _bookRide,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _bookRide() async {
    setState(() => _isBooking = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw 'User not logged in';
      final totalFare = (widget.ride!['base_fare'] as num).toDouble() * _selectedSeats;
      
      final walletService = ref.read(walletServiceProvider);
      await walletService.processPayment(
        userId: user.id,
        amount: totalFare,
        rideId: widget.ride!['id'],
        description: 'Ride booking: ${widget.ride!['origin_name']} to ${widget.ride!['destination_name']}',
      );

      final rideService = ref.read(rideServiceProvider);
      await rideService.bookRide(
        rideId: widget.ride!['id'],
        passengerId: user.id,
        seats: _selectedSeats,
        fare: totalFare,
      );

      ref.invalidate(walletBalanceProvider);
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmed! 🚗✨')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}

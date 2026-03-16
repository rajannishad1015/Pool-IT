import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ride_providers.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/ride_card.dart';

class RidesListScreen extends ConsumerWidget {
  final String? destination;

  const RidesListScreen({
    super.key,
    this.destination,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('RidesListScreen: Building with destination: $destination');
    final ridesAsync = ref.watch(availableRidesProvider(destination));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Rides',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Nearby search results',
              style: TextStyle(
                color: AppColors.primaryNavy.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded, color: AppColors.primaryNavy, size: 20),
            ),
          ),
        ],
      ),
      body: ridesAsync.when(
        data: (rides) {
          debugPrint('RidesListScreen: Received ${rides.length} rides');
          if (rides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 64, color: AppColors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No rides found for your route', style: TextStyle(color: AppColors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(availableRidesProvider(null)),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              return RideCard(ride: rides[index]);
            },
          );
        },
        loading: () {
          debugPrint('RidesListScreen: Loading rides...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (e, s) {
          debugPrint('RidesListScreen ERROR: $e');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $e', style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(availableRidesProvider(destination)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

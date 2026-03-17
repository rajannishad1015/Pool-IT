import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ride_providers.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/ride_card.dart';

class RidesListScreen extends ConsumerWidget {
  final String? destination;
  final String? mode;

  const RidesListScreen({
    super.key,
    this.destination,
    this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('RidesListScreen: Building with destination: $destination');
    final isPoolMode = mode == 'pool';
    final ridesAsync = ref.watch(availableRidesProvider(destination));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F8FC),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPoolMode ? 'Available Pools' : 'Available Rides',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isPoolMode ? 'Shared pool matches nearby' : 'Nearby search results',
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
          final filteredRides = isPoolMode
              ? rides.where((ride) {
                  final seats = (ride['seats_available'] as num?)?.toInt() ?? 0;
                  return seats >= 2;
                }).toList()
              : rides;

          debugPrint(
            'RidesListScreen: Received ${rides.length} rides, showing ${filteredRides.length} for mode=$mode',
          );

          if (filteredRides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE6ECF5)),
                    ),
                    child: Icon(Icons.directions_car_outlined, size: 38, color: AppColors.grey.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPoolMode
                        ? 'No pool rides available right now'
                        : 'No rides found for your route',
                    style: const TextStyle(color: AppColors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(availableRidesProvider(null)),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6ECF5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPoolMode ? Icons.people_alt_rounded : Icons.route_rounded,
                      size: 16,
                      color: AppColors.trustBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${filteredRides.length} match${filteredRides.length == 1 ? '' : 'es'} found${destination == null || destination!.isEmpty ? '' : ' for $destination'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filteredRides.length,
                  itemBuilder: (context, index) {
                    return RideCard(ride: filteredRides[index]);
                  },
                ),
              ),
            ],
          );
        },
        loading: () {
          debugPrint('RidesListScreen: Loading rides...');
          return const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
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

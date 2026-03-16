import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/supabase_providers.dart';
import '../widgets/online_toggle.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        ref.read(onlineStatusProvider.notifier).syncFromDb(userId);
      }
    });
  }

  void _toggleOnline(bool value) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    ref.read(onlineStatusProvider.notifier).toggle(value);
    
    final locationService = ref.read(locationServiceProvider);
    final profileService = ref.read(profileServiceProvider);

    if (value) {
      final hasPermission = await locationService.checkPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        ref.read(onlineStatusProvider.notifier).toggle(false);
        return;
      }

      // Update online status in DB
      await profileService.updateOnlineStatus(userId, true);

      // Start tracking
      locationService.startTracking(
        onLocationUpdate: (position) {
          profileService.updateLocation(userId, position.latitude, position.longitude);
        },
      );
    } else {
      // Stop tracking
      locationService.stopTracking();
      // Update online status in DB
      await profileService.updateOnlineStatus(userId, false);
    }
  }

  @override
  void dispose() {
    // Ensure tracking stops when screen is disposed (if that's desired, usually tracking might continue in background)
    // For now, let's keep it simple.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(onlineStatusProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    final profileAsync = userId != null ? ref.watch(profileProvider(userId)) : null;
    final statsAsync = userId != null ? ref.watch(driverStatsProvider(userId)) : null;
    final ridesAsync = userId != null ? ref.watch(driverRidesProvider(userId)) : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(profileAsync),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (userId != null) {
                    ref.invalidate(profileProvider(userId));
                    ref.invalidate(driverStatsProvider(userId));
                    ref.invalidate(driverRidesProvider(userId));
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatsGrid(statsAsync),
                      const SizedBox(height: 24),
                      _buildActionCard(
                        'Post a Ride',
                        'Found out when you are leaving',
                        Icons.add_to_photos_rounded,
                        AppColors.primaryEmerald,
                        onTap: () => context.push('/post-ride'),
                      ),
                      const SizedBox(height: 16),
                      _buildActionCard(
                        'Search Passengers',
                        'Find people on your route',
                        Icons.search_rounded,
                        AppColors.accentCoral,
                        onTap: () {}, // Future feature
                      ),
                      const SizedBox(height: 32),
                      _buildRecentRidesHeader(),
                      const SizedBox(height: 12),
                      _buildRecentRidesList(ridesAsync),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: OnlineToggle(
        isOnline: isOnline,
        onChanged: _toggleOnline,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(AsyncValue<Map<String, dynamic>?>? profileAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          profileAsync?.when(
            data: (profile) => CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceDark,
              backgroundImage: profile?['avatar_url'] != null ? NetworkImage(profile!['avatar_url'] as String) : null,
              child: profile?['avatar_url'] == null ? const Icon(Icons.person_rounded, color: AppColors.textSecondary) : null,
            ),
            loading: () => const CircleAvatar(radius: 24, backgroundColor: AppColors.surfaceDark, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, _) => const CircleAvatar(radius: 24, backgroundColor: AppColors.surfaceDark, child: Icon(Icons.error_outline)),
          ) ?? const SizedBox.shrink(),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              profileAsync?.when(
                data: (profile) => Text(
                  (profile?['full_name'] as String?) ?? 'Driver',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const Text('Loading...', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                error: (_, _) => const Text('Error', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
              ) ?? const SizedBox.shrink(),
            ],
          ),
          const Spacer(),
          _buildStatusBadge(ref.watch(onlineStatusProvider)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline 
            ? AppColors.primaryEmerald.withValues(alpha: 0.1) 
            : AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? AppColors.primaryEmerald : AppColors.textSecondary,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.primaryEmerald : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: isOnline ? AppColors.primaryEmerald : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AsyncValue<Map<String, dynamic>>? statsAsync) {
    return statsAsync?.when(
      data: (stats) => Row(
        children: [
          Expanded(child: _buildStatItem('Today\'s Rides', '${stats['today_rides']}', Icons.directions_car_rounded)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatItem('Earnings', '₹${stats['total_earnings']}', Icons.account_balance_wallet_rounded)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatItem('Rating', stats['rating'] == null ? '--' : '${stats['rating']}', Icons.star_rounded)),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(child: _buildStatLoader()),
          const SizedBox(width: 16),
          Expanded(child: _buildStatLoader()),
          const SizedBox(width: 16),
          Expanded(child: _buildStatLoader()),
        ],
      ),
      error: (_, _) => Row(
        children: [
          Expanded(child: _buildStatItem('Today\'s Rides', '--', Icons.directions_car_rounded)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatItem('Earnings', '--', Icons.account_balance_wallet_rounded)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatItem('Rating', '--', Icons.star_rounded)),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildStatLoader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryEmerald),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRidesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Rides',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('View All', style: TextStyle(color: AppColors.primaryEmerald)),
        ),
      ],
    );
  }

  Widget _buildRecentRidesList(AsyncValue<List<Map<String, dynamic>>>? ridesAsync) {
    return ridesAsync?.when(
      data: (rides) {
        if (rides.isEmpty) return _buildEmptyRecentRides();
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rides.length > 5 ? 5 : rides.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ride = rides[index];
            return _buildRideCard(ride);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading rides', style: TextStyle(color: Colors.red)),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final date = DateTime.parse(ride['departure_time']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(ride['status']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ride['status'].toString().toUpperCase(),
                  style: TextStyle(color: _getStatusColor(ride['status']), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryEmerald),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${ride['origin_name']} → ${ride['destination_name']}',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSmallBadge(Icons.people_rounded, '${ride['seats_available']}/${ride['seats_total']}'),
              const SizedBox(width: 12),
              _buildSmallBadge(Icons.account_balance_wallet_rounded, '₹${ride['base_fare']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.primaryEmerald;
      case 'ongoing': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  Widget _buildEmptyRecentRides() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'No Recent Rides',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Your completed rides will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

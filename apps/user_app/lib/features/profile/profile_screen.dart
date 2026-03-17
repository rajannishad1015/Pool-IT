import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import '../../core/theme/app_colors.dart';
import '../../core/providers/supabase_providers.dart';
import '../../core/providers/profile_providers.dart';
import 'id_verification_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: profileAsync.when(
        data: (profile) => CustomScrollView(
          slivers: [
            _buildSliverHeader(context, ref, profile),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatsRow(profile, ref),
                    const SizedBox(height: 26),
                    _buildSectionTitle('Account'),
                    _buildSettingsCard([
                      _buildProfileTile(context, Icons.person_outline, 'Edit Profile'),
                      Consumer(builder: (context, ref, child) {
                        final verificationStatus = ref.watch(userVerificationProvider).maybeWhen(
                          data: (v) => v,
                          orElse: () => 'unverified',
                        );
                        final isVerified = verificationStatus == 'verified';
                        
                        return _buildProfileTile(
                          context, 
                          isVerified ? Icons.verified_user : Icons.verified_user_outlined, 
                          'ID Verification', 
                          trail: _buildStatusBadge(verificationStatus),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const IdVerificationScreen()),
                            );
                          },
                        );
                      }),
                      _buildProfileTile(context, Icons.directions_car_outlined, 'My Vehicle'),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Support & Legal'),
                    _buildSettingsCard([
                      _buildProfileTile(context, Icons.help_outline, 'Help Center'),
                      _buildProfileTile(context, Icons.info_outline, 'About SmartPool'),
                    ]),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton(
                        onPressed: () async {
                          final authService = ref.read(authServiceProvider);
                          await authService.signOut();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentCoral,
                          side: BorderSide(color: AppColors.accentCoral.withValues(alpha: 0.6)),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, WidgetRef ref, Map<String, dynamic>? profile) {
    final statsAsync = ref.watch(userStatsProvider);
    final rideCount = statsAsync.maybeWhen(
      data: (stats) => stats['rides'] as int,
      orElse: () => 0,
    );
    final rideLabel = rideCount == 0
        ? '(New User)'
        : '($rideCount ${rideCount == 1 ? 'ride' : 'rides'})';

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primaryNavy,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryNavy, AppColors.trustBlue],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => _uploadAvatar(context, ref),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white24,
                      backgroundImage: profile?['avatar_url'] != null
                          ? NetworkImage(profile!['avatar_url'])
                          : null,
                      child: profile?['avatar_url'] == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accentCoral,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile?['full_name'] ?? 'Add Full Name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.star, color: Colors.orange, size: 16),
                  Text(
                    ' ${profile?['trust_score'] ?? '5.0'} ',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    rideLabel,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadAvatar(BuildContext context, WidgetRef ref) async {
    final picker = image_picker.ImagePicker();
    final image = await picker.pickImage(source: image_picker.ImageSource.gallery);
    
    if (image != null) {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final storageService = ref.read(storageServiceProvider);
      final profileService = ref.read(profileServiceProvider);

      try {
        final url = await storageService.uploadAvatar(
          userId: user.id,
          imageFile: File(image.path),
        );
        
        await profileService.updateProfile(
          userId: user.id,
          updates: {'avatar_url': url},
        );
        
        ref.invalidate(userProfileProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Widget _buildStatsRow(Map<String, dynamic>? profile, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return statsAsync.when(
      data: (stats) {
        final rides = stats['rides'] as int;
        final co2Saved = stats['co2Saved'] as double;
        final moneySaved = stats['moneySaved'] as double;

        return Row(
          children: [
            Expanded(child: _buildStatCard('$rides', 'Rides', Icons.route_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('${co2Saved.toStringAsFixed(1)}kg', 'CO₂ Saved', Icons.eco_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('₹${moneySaved.toStringAsFixed(0)}', 'Saved', Icons.savings_rounded)),
          ],
        );
      },
      loading: () => Row(
          children: [
          Expanded(child: _buildStatCard('...', 'Rides', Icons.route_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard('...', 'CO₂ Saved', Icons.eco_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard('...', 'Saved', Icons.savings_rounded)),
        ],
      ),
      error: (_, _) => Row(
        children: [
          Expanded(child: _buildStatCard('0', 'Rides', Icons.route_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard('0kg', 'CO₂ Saved', Icons.eco_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard('₹0', 'Saved', Icons.savings_rounded)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EAF4)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.trustBlue),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primaryNavy.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF4)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy.withValues(alpha: 0.58),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, {Widget? trail, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.trustBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.trustBlue, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryNavy,
        ),
      ),
      trailing: trail ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon!')),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'verified') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F9EF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Verified', style: TextStyle(color: Color(0xFF17985F), fontSize: 11, fontWeight: FontWeight.bold)),
      );
    } else if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Pending', style: TextStyle(color: Color(0xFFF9A825), fontSize: 11, fontWeight: FontWeight.bold)),
      );
    } else if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFF1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Rejected', style: TextStyle(color: AppColors.accentCoral, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('Unverified', style: TextStyle(color: AppColors.accentCoral, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

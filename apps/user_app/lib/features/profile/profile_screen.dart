import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import '../../core/theme/app_colors.dart';
import '../../core/providers/supabase_providers.dart';
import '../../core/providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: profileAsync.when(
        data: (profile) => CustomScrollView(
          slivers: [
            _buildSliverHeader(context, ref, profile),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatsRow(profile),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Account'),
                    _buildProfileTile(Icons.person_outline, 'Edit Profile'),
                    _buildProfileTile(Icons.verified_user_outlined, 'ID Verification', trail: _buildPendingBadge(profile?['is_verified'] ?? false)),
                    _buildProfileTile(Icons.directions_car_outlined, 'My Vehicle'),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Support & Legal'),
                    _buildProfileTile(Icons.help_outline, 'Help Center'),
                    _buildProfileTile(Icons.info_outline, 'About SmartPool'),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton(
                        onPressed: () async {
                          final authService = ref.read(authServiceProvider);
                          await authService.signOut();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Logout'),
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
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryNavy, AppColors.trustBlue],
            ),
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
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                    '(New User)', 
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
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

  Widget _buildStatsRow(Map<String, dynamic>? profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('0', 'Rides'),
        _buildStatItem('0kg', 'CO₂ Saved'),
        _buildStatItem('₹0', 'Saved'),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey),
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, {Widget? trail}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryNavy),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trail ?? const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }

  Widget _buildPendingBadge(bool isVerified) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: const Text('Verified', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: const Text('Pending', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

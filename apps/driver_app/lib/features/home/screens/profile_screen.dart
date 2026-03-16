import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/supabase_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;

    if (userId == null) {
      return const Center(child: Text('Please login to see profile'));
    }

    final profileAsyncValue = ref.watch(profileProvider(userId));
    final driverDetailsAsyncValue = ref.watch(driverDetailsProvider(userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: profileAsyncValue.when(
        data: (profile) => driverDetailsAsyncValue.when(
          data: (driver) => SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildProfileHeader(profile),
                const SizedBox(height: 32),
                _buildStatusSection(driver?['verification_status'] ?? 'unverified'),
                const SizedBox(height: 32),
                _buildInfoSection('Personal Info', [
                  _buildInfoTile(Icons.email_outlined, 'Email', ref.watch(currentUserProvider)?.email ?? 'N/A'),
                  _buildInfoTile(Icons.phone_android_outlined, 'Phone', profile?['phone_number'] ?? 'N/A'),
                  _buildInfoTile(Icons.cake_outlined, 'Date of Birth', profile?['date_of_birth'] ?? 'N/A'),
                  _buildInfoTile(Icons.person_outline_rounded, 'Gender', profile?['gender'] ?? 'N/A'),
                ]),
                const SizedBox(height: 32),
                _buildInfoSection('Driver Info', [
                  _buildInfoTile(Icons.credit_card_rounded, 'Aadhaar Number', driver?['aadhaar_number'] ?? 'Not setup'),
                  _buildInfoTile(Icons.drive_eta_rounded, 'DL Number', driver?['dl_number'] ?? 'Not setup'),
                ]),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () {},
                  child: const Text('Edit Profile', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? profile) {
    final avatarUrl = profile?['avatar_url'];
    final name = profile?['full_name'] ?? 'Driver Name';

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.surfaceDark,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? const Icon(Icons.person_rounded, size: 50, color: AppColors.textSecondary) : null,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pooling Partner',
          style: TextStyle(color: AppColors.primaryEmerald, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatusSection(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'verified':
        statusColor = AppColors.primaryEmerald;
        statusText = 'Verified Driver';
        statusIcon = Icons.verified_rounded;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Verification Pending';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Verification Rejected';
        statusIcon = Icons.error_outline_rounded;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Unverified';
        statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                'Complete all steps to start taking rides.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

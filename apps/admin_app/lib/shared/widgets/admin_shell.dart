import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_colors.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  final String title;

  const AdminShell({
    super.key,
    required this.child,
    this.title = 'Admin Dashboard',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AdminColors.primary,
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _buildDrawer(context),
      body: child,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AdminColors.sidebar,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AdminColors.sidebar),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: AdminColors.primary, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'SmartPool Admin',
                    style: TextStyle(
                      color: AdminColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard_rounded,
            label: 'Command Center',
            onTap: () {},
            isActive: true,
          ),
          _DrawerItem(
            icon: Icons.people_alt_rounded,
            label: 'Rider Management',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.drive_eta_rounded,
            label: 'Driver Management',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.fact_check_rounded,
            label: 'Verification Queue',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.map_rounded,
            label: 'Live Ride Monitor',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.warning_amber_rounded,
            label: 'Safety & Incidents',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.payments_rounded,
            label: 'Financial Ops',
            onTap: () {},
          ),
          const Spacer(),
          const Divider(color: Colors.white24),
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            onTap: () {},
            color: AdminColors.danger,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AdminColors.primary : (color ?? Colors.white70),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? AdminColors.primary : (color ?? Colors.white70),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      onTap: onTap,
      dense: true,
    );
  }
}

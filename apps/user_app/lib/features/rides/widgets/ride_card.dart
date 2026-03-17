import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// Formats a date relative to today (Today, Tomorrow, or day name/date)
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDate = DateTime(date.year, date.month, date.day);
  final diff = targetDate.difference(today).inDays;

  if (diff == 0) {
    return 'Today';
  } else if (diff == 1) {
    return 'Tomorrow';
  } else if (diff < 7) {
    return DateFormat('EEEE').format(date); // Day name like "Monday"
  } else {
    return DateFormat('MMM d').format(date); // Like "Mar 15"
  }
}

class RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;

  const RideCard({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    final driver = ride['profiles'] as Map<String, dynamic>?;
    final vehicle = ride['vehicles'] as Map<String, dynamic>?;
    final departureTime = DateTime.parse(ride['departure_time']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/ride-detail', extra: ride),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Driver Info & Fare Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: driver?['avatar_url'] != null
                        ? NetworkImage(driver!['avatar_url'])
                        : null,
                    child: driver?['avatar_url'] == null
                        ? const Icon(Icons.person, color: AppColors.primaryNavy, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              driver?['full_name'] ?? 'Driver',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: AppColors.trustBlue, size: 14),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                            Text(
                              ' ${driver?['trust_score'] ?? '5.0'} ',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '• ${vehicle != null ? '${vehicle['make']}' : 'Vehicle'}',
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentCoral.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₹${ride['base_fare']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentCoral,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              // Route Visualization
              Row(
                children: [
                  Column(
                    children: [
                      const Icon(Icons.radio_button_checked, size: 14, color: AppColors.trustBlue),
                      Container(
                        width: 1.5,
                        height: 24,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.accentCoral),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['origin_name'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          ride['destination_name'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${departureTime.hour}:${departureTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        formatRelativeDate(departureTime),
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tags & Booking Action
              Row(
                children: [
                  _buildTag(Icons.ac_unit_rounded, ride['is_ac'] == true ? 'AC' : 'Non-AC'),
                  const SizedBox(width: 8),
                  _buildTag(Icons.event_seat_rounded, '${ride['seats_available']} seats left'),
                  const Spacer(),
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.trustBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.trustBlue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primaryNavy.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryNavy.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

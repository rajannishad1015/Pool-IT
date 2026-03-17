import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/map_providers.dart';
import '../../../shared/widgets/primary_button.dart';

class RideSearchCard extends ConsumerStatefulWidget {
  const RideSearchCard({super.key});

  @override
  ConsumerState<RideSearchCard> createState() => _RideSearchCardState();
}

class _RideSearchCardState extends ConsumerState<RideSearchCard> {
  String _destination = '';
  DateTime _selectedDate = DateTime.now();
  int _passengerCount = 1;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showPassengerPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Passengers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _passengerCount > 1
                            ? () {
                                setModalState(() => _passengerCount--);
                                setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_passengerCount',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: _passengerCount < 6
                            ? () {
                                setModalState(() => _passengerCount++);
                                setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Confirm',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDestinationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String tempDest = _destination;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Where to?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter destination...',
                  prefixIcon:
                      const Icon(Icons.location_on, color: Colors.redAccent),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => tempDest = value,
                onSubmitted: (value) {
                  setState(() => _destination = value);
                  ref.read(mapRouteProvider.notifier).setDestination(value);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Confirm',
                  onPressed: () {
                    setState(() => _destination = tempDest);
                    ref.read(mapRouteProvider.notifier).setDestination(tempDest);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selected.isAtSameMomentAs(today)) {
      return 'Today, Now';
    } else if (selected.difference(today).inDays == 1) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Origin is set automatically from device location
    // RouteNotifier doesn't track origin name, so we use a constant
    const currentLocationName = 'Current Location';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocationField(
            icon: Icons.my_location,
            label: 'From',
            value: currentLocationName,
            isSource: true,
            onTap: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(left: 44),
            child: Divider(height: 1),
          ),
          _buildLocationField(
            icon: Icons.location_on,
            label: 'To',
            value: _destination.isEmpty ? 'Where to?' : _destination,
            isSource: false,
            onTap: _showDestinationPicker,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSelector(
                  icon: Icons.calendar_today,
                  label: _formatDate(),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelector(
                  icon: Icons.person,
                  label:
                      '$_passengerCount ${_passengerCount == 1 ? 'Passenger' : 'Passengers'}',
                  onTap: _showPassengerPicker,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Find Rides',
            onPressed: () => context.push(
              Uri(
                path: '/rides',
                queryParameters: {
                  'destination': _destination,
                  'date': _selectedDate.toIso8601String(),
                  'passengers': _passengerCount.toString(),
                },
              ).toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required IconData icon,
    required String label,
    required String value,
    required bool isSource,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon,
                color: isSource ? AppColors.trustBlue : AppColors.accentCoral),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
            if (isSource) const Icon(Icons.swap_vert, color: AppColors.grey)
          ],
        ),
      ),
    );
  }

  Widget _buildSelector({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryNavy),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

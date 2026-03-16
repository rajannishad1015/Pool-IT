import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/map_providers.dart';
import '../../../shared/widgets/primary_button.dart';

class HomeBottomPanel extends ConsumerStatefulWidget {
  const HomeBottomPanel({super.key});

  @override
  ConsumerState<HomeBottomPanel> createState() => _HomeBottomPanelState();
}

class _HomeBottomPanelState extends ConsumerState<HomeBottomPanel> {
  String _destination = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentCoral,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentCoral,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
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
                  prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
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
                  // Trigger geocoding & show on map
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
                    // Trigger geocoding & show on map
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          const Text(
            'Where are you going?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 16),
          // Location Inputs
          _buildInput(
            onTap: () {}, // Trigger location picker
            icon: Icons.radio_button_checked,
            iconColor: Colors.orange,
            text: 'My Current Location',
            isPlaceholder: false,
          ),
          const SizedBox(height: 10),
          _buildInput(
            onTap: _showDestinationPicker,
            icon: Icons.location_on,
            iconColor: Colors.redAccent,
            text: _destination.isEmpty ? 'Enter destination' : _destination,
            isPlaceholder: _destination.isEmpty,
          ),
          const SizedBox(height: 10),
          // Time Selectors
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  onTap: () => _selectDate(context),
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.trustBlue,
                  text: DateFormat('MMM dd, EEE').format(_selectedDate),
                  isPlaceholder: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  onTap: () => _selectTime(context),
                  icon: Icons.access_time,
                  iconColor: AppColors.trustBlue,
                  text: _selectedTime.format(context),
                  isPlaceholder: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Find Rides',
              onPressed: () {
                debugPrint('HomeBottomPanel: Finding rides for destination: $_destination');
                context.push(
                  Uri(
                    path: '/rides',
                    queryParameters: {
                      'destination': _destination,
                      'date': _selectedDate.toIso8601String(),
                    },
                  ).toString(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInput({
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isPlaceholder,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Very light grey/blue
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPlaceholder ? Colors.blueGrey : AppColors.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

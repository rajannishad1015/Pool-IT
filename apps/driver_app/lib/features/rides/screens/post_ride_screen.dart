import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/supabase_providers.dart';

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key});

  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _seats = 3;
  double _price = 150.0;
  bool _isLoading = false;
  String? _selectedVehicleId;

  Future<void> _publishRide() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both origin and destination')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw 'User not authenticated';

      // 1. Check selected vehicle
      if (_selectedVehicleId == null) {
        throw 'Please select a vehicle';
      }
      final vehicleId = _selectedVehicleId!;

      // 2. Combine date and time
      final departureTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 3. Create ride in Supabase
      // Note: Coordinates are hardcoded for now as placeholders
      await ref.read(rideServiceProvider).createRide(
        driverId: userId,
        vehicleId: vehicleId,
        originName: _fromController.text,
        originLat: 12.9716, // Placeholder (Bangalore)
        originLng: 77.5946, // Placeholder
        destinationName: _toController.text,
        destinationLat: 13.0827, // Placeholder (Chennai)
        destinationLng: 80.2707, // Placeholder
        departureTime: departureTime,
        seatsTotal: _seats,
        baseFare: _price,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride Published Successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a New Ride'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationFields(),
            const SizedBox(height: 32),
            _buildVehicleSelector(),
            const SizedBox(height: 32),
            _buildDateTimeSelectors(),
            const SizedBox(height: 32),
            _buildSeatsSelector(),
            const SizedBox(height: 32),
            _buildPriceSelector(),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _publishRide,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publish This Ride'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        _buildInputField('From', _fromController, Icons.my_location_rounded, 'Enter starting point'),
        const SizedBox(height: 16),
        _buildInputField('To', _toController, Icons.location_on_rounded, 'Enter destination'),
      ],
    );
  }

  Widget _buildVehicleSelector() {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const SizedBox.shrink();

    final vehiclesAsync = ref.watch(driverVehiclesProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Vehicle',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        vehiclesAsync.when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Text(
                'No vehicles found. Add one in Profile.',
                style: TextStyle(color: Colors.red[400], fontSize: 13),
              );
            }

            // Set default if none selected
            if (_selectedVehicleId == null && vehicles.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) setState(() => _selectedVehicleId = vehicles.first['id']);
              });
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: vehicles.map((v) {
                  final isSelected = _selectedVehicleId == v['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedVehicleId = v['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryEmerald : AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryEmerald : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.directions_car_filled_rounded : Icons.directions_car_outlined,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${v['make']} ${v['model']} (${v['plate_number']})',
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Error loading vehicles', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.primaryEmerald, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelectors() {
    return Row(
      children: [
        Expanded(
          child: _buildPickerCard(
            'Date',
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            Icons.calendar_today_rounded,
            _selectDate,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPickerCard(
            'Time',
            _selectedTime.format(context),
            Icons.access_time_rounded,
            _selectTime,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCard(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryEmerald, size: 20),
                const SizedBox(width: 12),
                Text(value, style: const TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seats Available',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _seats = index + 1),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _seats == index + 1 ? AppColors.primaryEmerald : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: _seats == index + 1 ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Price per Seat',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            Text(
              '₹${_price.toInt()}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
            ),
          ],
        ),
        Slider(
          value: _price,
          min: 50,
          max: 500,
          divisions: 45,
          activeColor: AppColors.primaryEmerald,
          inactiveColor: AppColors.surfaceDark,
          onChanged: (val) => setState(() => _price = val),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹50', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('₹500', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }
}

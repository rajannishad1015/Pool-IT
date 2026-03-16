import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ride_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../core/providers/profile_providers.dart';
import '../../shared/widgets/primary_button.dart';

class OfferRideScreen extends ConsumerStatefulWidget {
  const OfferRideScreen({super.key});

  @override
  ConsumerState<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends ConsumerState<OfferRideScreen> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _fareController = TextEditingController();
  int _seats = 3;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(userVehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer a Ride'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Route Details'),
            _buildInputField(
              controller: _originController,
              label: 'Starting Point',
              icon: Icons.my_location,
              hint: 'e.g. Andheri West',
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _destController,
              label: 'Destination',
              icon: Icons.location_on,
              hint: 'e.g. BKC, Mumbai',
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Ride Schedule'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primaryNavy),
              title: const Text('Date & Time'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month} at ${TimeOfDay.fromDateTime(_selectedDate).format(context)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.trustBlue),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _selectDateTime,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Available Seats'),
            Row(
              children: [
                _buildSeatCounter(),
                const Spacer(),
                const Text('Fare per seat:', style: TextStyle(color: AppColors.grey)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _fareController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '₹',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildSectionTitle('Select Vehicle'),
            vehiclesAsync.when(
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return _buildAddVehicleCard();
                }
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  hint: const Text('Select your car'),
                  items: vehicles.map((v) {
                    return DropdownMenuItem(
                      value: v['id'] as String,
                      child: Text('${v['make']} ${v['model']} (${v['plate_number']})'),
                    );
                  }).toList(),
                  onChanged: (val) {},
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('Error loading vehicles: $e'),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Publish Ride',
              isLoading: _isLoading,
              onPressed: _publishRide,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryNavy),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }

  Widget _buildSeatCounter() {
    return Row(
      children: [
        _buildCounterBtn(Icons.remove, () {
          if (_seats > 1) setState(() => _seats--);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$_seats',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildCounterBtn(Icons.add, () {
          if (_seats < 6) setState(() => _seats++);
        }),
      ],
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryNavy),
      ),
    );
  }

  Widget _buildAddVehicleCard() {
    return InkWell(
      onTap: () => context.push('/profile'), 
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentCoral.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentCoral.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.accentCoral),
            SizedBox(width: 12),
            Text(
              'Add a vehicle to offer rides',
              style: TextStyle(color: AppColors.accentCoral, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishRide() async {
    if (_originController.text.isEmpty || _destController.text.isEmpty || _fareController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      final vehicles = await ref.read(userVehiclesProvider.future);
      
      if (vehicles.isEmpty) {
        throw 'You need to add a vehicle first';
      }

      final rideService = ref.read(rideServiceProvider);
      await rideService.createRide(
        driverId: user!.id,
        vehicleId: vehicles.first['id'], 
        originName: _originController.text,
        originLat: 19.0760, 
        originLng: 72.8777, 
        destinationName: _destController.text,
        destinationLat: 19.1136, 
        destinationLng: 72.8697, 
        departureTime: _selectedDate,
        seatsTotal: _seats,
        baseFare: double.parse(_fareController.text),
      );

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride published successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

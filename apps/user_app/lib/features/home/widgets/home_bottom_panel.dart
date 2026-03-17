import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/map_providers.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../shared/widgets/primary_button.dart';

class HomeBottomPanel extends ConsumerStatefulWidget {
  final String currentLocationLabel;
  final bool isRefreshingLocation;
  final VoidCallback onRefreshLocation;

  const HomeBottomPanel({
    super.key,
    required this.currentLocationLabel,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
  });

  @override
  ConsumerState<HomeBottomPanel> createState() => _HomeBottomPanelState();
}

class _HomeBottomPanelState extends ConsumerState<HomeBottomPanel> {
  final TextEditingController _destinationController = TextEditingController();
  Timer? _suggestionDebounce;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;
  bool _routePreviewReady = false;

  String _formatDistance(double meters) {
    if (meters <= 0) {
      return 'Distance unavailable';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) {
      return 'ETA unavailable';
    }
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

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

  Future<void> _showDestinationPicker() async {
    final currentFromRoute = ref.read(mapRouteProvider).destinationName ?? '';
    final initialDestination = _destinationController.text.trim().isNotEmpty
        ? _destinationController.text
        : currentFromRoute;
    final tempController = TextEditingController(text: initialDestination);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final suggestions = <PlaceSuggestion>[];
        bool isLoadingSuggestions = false;
        int searchToken = 0;

        Future<void> fetchSuggestions(
          String value,
          void Function(void Function()) setModalState,
        ) async {
          final query = value.trim();
          if (query.length < 2) {
            setModalState(() {
              suggestions.clear();
              isLoadingSuggestions = false;
            });
            return;
          }

          final currentToken = ++searchToken;
          setModalState(() => isLoadingSuggestions = true);

          final result = await GeocodingService.searchPlaceSuggestions(query);
          if (!mounted || currentToken != searchToken) {
            return;
          }

          setModalState(() {
            isLoadingSuggestions = false;
            suggestions
              ..clear()
              ..addAll(result);
          });
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    controller: tempController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Enter destination...',
                      prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                      suffixIcon: isLoadingSuggestions
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      _suggestionDebounce?.cancel();
                      _suggestionDebounce = Timer(
                        const Duration(milliseconds: 280),
                        () => fetchSuggestions(value, setModalState),
                      );
                    },
                    onSubmitted: (value) {
                      final destination = value.trim();
                      if (destination.isEmpty) {
                        return;
                      }

                      setState(() {
                        _destinationController.text = destination;
                        _routePreviewReady = false;
                      });

                      ref.read(mapRouteProvider).setDestination(destination);
                      Navigator.pop(context);
                    },
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      constraints: const BoxConstraints(maxHeight: 210),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.place_outlined,
                              color: AppColors.accentCoral,
                            ),
                            title: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              setState(() {
                                _destinationController.text = item.label;
                                _routePreviewReady = false;
                              });

                              ref.read(mapRouteProvider).setDestinationFromCoordinates(
                                    destinationName: item.label,
                                    destination: item.location,
                                  );
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  if (!isLoadingSuggestions &&
                      tempController.text.trim().length >= 2 &&
                      suggestions.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No suggestions found. Press Confirm to search this destination.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Confirm',
                      onPressed: () {
                        final destination = tempController.text.trim();
                        if (destination.isEmpty) {
                          return;
                        }

                        setState(() {
                          _destinationController.text = destination;
                          _routePreviewReady = false;
                        });

                        ref.read(mapRouteProvider).setDestination(destination);
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
      },
    );
  }

  Future<void> _findRides() async {
    final routeNotifier = ref.read(mapRouteProvider);
    final destination = _destinationController.text.trim().isNotEmpty
        ? _destinationController.text.trim()
        : (routeNotifier.destinationName ?? '').trim();

    if (destination.isNotEmpty && _destinationController.text.trim().isEmpty) {
      setState(() {
        _destinationController.text = destination;
      });
    }

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination.')),
      );
      return;
    }

    if (_isSubmitting) {
      return;
    }

    final alreadySelected = routeNotifier.destination != null &&
        routeNotifier.destinationName == destination;

    setState(() => _isSubmitting = true);
    if (!alreadySelected) {
      await routeNotifier.setDestination(destination);
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (routeNotifier.destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Mumbai destinations are supported. Please enter a Mumbai location.'),
        ),
      );
      return;
    }

    if (!_routePreviewReady) {
      setState(() => _routePreviewReady = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route ready. Tap Find Rides to continue.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _goToResults(destination, isPoolMode: false);
  }

  void _findPool() {
    final routeNotifier = ref.read(mapRouteProvider);
    final destination = _destinationController.text.trim().isNotEmpty
        ? _destinationController.text.trim()
        : (routeNotifier.destinationName ?? '').trim();

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination first.')),
      );
      return;
    }

    if (!_routePreviewReady || !routeNotifier.hasRoute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap Show Route first, then Find Pool.')),
      );
      return;
    }

    _goToResults(destination, isPoolMode: true);
  }

  void _goToResults(String destination, {required bool isPoolMode}) {

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    context.push(
      Uri(
        path: '/rides',
        queryParameters: {
          'destination': destination,
          'date': dateTime.toIso8601String(),
          'time': _selectedTime.format(context),
          'mode': isPoolMode ? 'pool' : 'ride',
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(mapRouteProvider);
    final destinationText = _destinationController.text.trim().isNotEmpty
        ? _destinationController.text
        : (routeState.destinationName ?? '');

    return Container(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFEFF),
            Color(0xFFF7FAFE),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFFE6ECF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -10),
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
              fontSize: 32 / 2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.primaryNavy,
            ),
          ),
          Text(
            _routePreviewReady
                ? 'Route ready. Choose how you want to travel.'
                : 'Set your destination and departure time.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryNavy.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Location Inputs
          _buildInput(
            onTap: widget.onRefreshLocation,
            icon: Icons.radio_button_checked,
            iconColor: Colors.orange,
            text: widget.currentLocationLabel,
            isPlaceholder: false,
            trailing: widget.isRefreshingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentCoral,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.trustBlue,
                    size: 18,
                  ),
          ),
          const SizedBox(height: 10),
          _buildInput(
            onTap: _showDestinationPicker,
            icon: Icons.location_on,
            iconColor: Colors.redAccent,
            text: destinationText.isEmpty
                ? 'Enter destination'
                : destinationText,
            isPlaceholder: destinationText.isEmpty,
            trailing: const Icon(
              Icons.keyboard_arrow_right_rounded,
              color: AppColors.grey,
            ),
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
          if (!_routePreviewReady)
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'Show Route',
                isLoading: _isSubmitting || routeState.isGeocoding,
                onPressed: _findRides,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Find Rides',
                    isLoading: _isSubmitting || routeState.isGeocoding,
                    onPressed: _findRides,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    text: 'Find Pool',
                    color: const Color(0xFF143A6D),
                    onPressed: _findPool,
                  ),
                ),
              ],
            ),
          if (_routePreviewReady && routeState.hasRoute)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.trustBlue.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.trustBlue.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: AppColors.trustBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_formatDistance(routeState.routeDistanceMeters)} • ${_formatDuration(routeState.routeDurationSeconds)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
    Widget? trailing,
  }) {
    final rowChildren = <Widget>[
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 14),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Text(
            text,
            key: ValueKey(text),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isPlaceholder ? Colors.blueGrey : AppColors.primaryNavy,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    if (trailing != null) {
      rowChildren.add(trailing);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6ECF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: rowChildren,
        ),
      ),
    );
  }
}

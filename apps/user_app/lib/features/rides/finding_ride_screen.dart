import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/map_providers.dart';
import '../../core/providers/ride_providers.dart';
import '../../core/providers/supabase_providers.dart';

class FindingRideScreen extends ConsumerStatefulWidget {
  final String destination;
  final String mode;
  final DateTime? scheduledAt;

  const FindingRideScreen({
    super.key,
    required this.destination,
    required this.mode,
    this.scheduledAt,
  });

  @override
  ConsumerState<FindingRideScreen> createState() => _FindingRideScreenState();
}

class _FindingRideScreenState extends ConsumerState<FindingRideScreen> {
  static const int _maxSeconds = 60;

  int _secondsLeft = _maxSeconds;
  String? _requestId;
  String _status = 'pending';
  bool _isInitializing = true;
  bool _backendConnected = true;

  Timer? _countdownTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startFindingFlow();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startFindingFlow() async {
    final user = ref.read(currentUserProvider);
    final route = ref.read(mapRouteProvider);
    final rideService = ref.read(rideServiceProvider);

    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    final requestId = await rideService.createRideRequest(
      passengerId: user.id,
      mode: widget.mode,
      destinationName: widget.destination,
      scheduledAt: widget.scheduledAt ?? DateTime.now(),
      originName: 'Current Location',
      originLat: route.origin?.latitude,
      originLng: route.origin?.longitude,
      destinationLat: route.destination?.latitude,
      destinationLng: route.destination?.longitude,
    );

    if (!mounted) return;

    setState(() {
      _requestId = requestId;
      _backendConnected = requestId != null;
      _isInitializing = false;
    });

    _startCountdown();

    if (requestId != null) {
      _startPollingStatus(requestId);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        _handleTimeout();
        return;
      }

      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  void _startPollingStatus(String requestId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;

      final rideService = ref.read(rideServiceProvider);
      final status = await rideService.getRideRequestStatus(requestId);
      if (status == null) return;

      if (!mounted) return;
      setState(() => _status = status);

      if (status == 'accepted') {
        await _onAccepted();
      } else if (status == 'rejected') {
        _onRejected();
      }
    });
  }

  Future<void> _onAccepted() async {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver accepted your request.')),
    );

    context.go(
      '/rides?destination=${Uri.encodeComponent(widget.destination)}&mode=${widget.mode}',
    );
  }

  void _onRejected() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request rejected by driver. Trying more rides...'),
      ),
    );

    context.go(
      '/rides?destination=${Uri.encodeComponent(widget.destination)}&mode=${widget.mode}',
    );
  }

  Future<void> _handleTimeout() async {
    _pollTimer?.cancel();

    if (_requestId != null) {
      await ref
          .read(rideServiceProvider)
          .updateRideRequestStatus(requestId: _requestId!, status: 'timed_out');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No driver accepted in 60 sec. Showing available rides.'),
      ),
    );
    context.go(
      '/rides?destination=${Uri.encodeComponent(widget.destination)}&mode=${widget.mode}',
    );
  }

  Future<void> _cancelRequest() async {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    if (_requestId != null) {
      await ref
          .read(rideServiceProvider)
          .updateRideRequestStatus(requestId: _requestId!, status: 'cancelled');
    }

    if (!mounted) return;
    context.go('/home');
  }

  Color _statusColor() {
    switch (_status) {
      case 'accepted':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_maxSeconds - _secondsLeft) / _maxSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _cancelRequest();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090909),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF040404), Color(0xFF101010)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _cancelRequest,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF343434)),
                        ),
                        child: Text(
                          widget.mode.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Finding your ride',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.destination,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFFB1B1B1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF2F2F2F)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 92,
                          height: 92,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 6,
                                backgroundColor: const Color(0xFF303030),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2196F3),
                                ),
                              ),
                              Text(
                                '$_secondsLeft',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isInitializing
                              ? 'Creating your request...'
                              : _backendConnected
                              ? 'Waiting for driver response...'
                              : 'Backend table missing. Running local finder only.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB8B8B8),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _statusColor().withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'STATUS: ${_status.toUpperCase()}',
                            style: TextStyle(
                              color: _statusColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cancelRequest,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4A4A4A)),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22 / 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

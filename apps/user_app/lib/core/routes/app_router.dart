import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/email_verification_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/rides/rides_list_screen.dart';
import '../../features/rides/ride_detail_screen.dart';
import '../../features/rides/offer_ride_screen.dart';
import '../../features/bookings/booking_confirmation_screen.dart';
import 'go_router_refresh_stream.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/rides/active_ride_screen.dart';

final appRouter = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(SupabaseService.client.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = SupabaseService.client.auth.currentSession;
      final matchedPath = state.matchedLocation;
      
      final isSplash = matchedPath == '/';
      final isLogin = matchedPath == '/login';
      final isEmailVerify = matchedPath == '/email-verification';

      if (session == null) {
        // Not logged in
        if (!isSplash && !isLogin && !isEmailVerify) {
          return '/login';
        }
      } else {
        // Logged in
        if (isLogin || isSplash) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => EmailVerificationScreen(email: state.extra as String?),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) => OtpVerificationScreen(phone: state.extra as String),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/rides',
        builder: (context, state) => RidesListScreen(
          destination: state.uri.queryParameters['destination'],
          mode: state.uri.queryParameters['mode'],
        ),
      ),
      GoRoute(
        path: '/ride-detail',
        builder: (context, state) => RideDetailScreen(ride: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/booking-confirmation',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return BookingConfirmationScreen(bookingData: extras);
        },
      ),
      GoRoute(
        path: '/offer-ride',
        builder: (context, state) => const OfferRideScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/active-ride',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return ActiveRideScreen(
            rideId: extras['rideId'] as String,
            driverId: extras['driverId'] as String,
          );
        },
      ),
    ],
  );
});

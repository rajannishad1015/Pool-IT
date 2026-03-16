import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/phone_auth_screen.dart';
import '../../features/onboarding/screens/profile_setup_screen.dart';
import '../../features/onboarding/screens/verification_screens.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/rides/screens/post_ride_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/phone-auth',
      builder: (context, state) => const PhoneAuthScreen(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpVerificationScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/aadhaar-verification',
      builder: (context, state) => const AadhaarVerificationScreen(),
    ),
    GoRoute(
      path: '/dl-verification',
      builder: (context, state) => const DrivingLicenceScreen(),
    ),
    GoRoute(
      path: '/rc-verification',
      builder: (context, state) => const RcVerificationScreen(),
    ),
    GoRoute(
      path: '/vehicle-images',
      builder: (context, state) => const VehicleImagesScreen(),
    ),
    GoRoute(
      path: '/insurance-puc',
      builder: (context, state) => const InsurancePucScreen(),
    ),
    GoRoute(
      path: '/bank-details',
      builder: (context, state) => const BankDetailsScreen(),
    ),
    GoRoute(
      path: '/verification-pending',
      builder: (context, state) => const VerificationPendingScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/post-ride',
      builder: (context, state) => const PostRideScreen(),
    ),
  ],
);

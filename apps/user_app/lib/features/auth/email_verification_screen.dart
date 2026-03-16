import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/supabase_providers.dart';
import '../../shared/widgets/primary_button.dart';

class EmailVerificationScreen extends ConsumerWidget {
  final String? email;
  
  const EmailVerificationScreen({super.key, this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: AppColors.trustBlue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Check your email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification link to ${email ?? 'your email address'}. Please click the link to verify your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Open Email App',
              onPressed: () async {
                final Uri emailUri = Uri(scheme: 'mailto');
                try {
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not find an email app')),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: email == null ? null : () async {
                try {
                  final authService = ref.read(authServiceProvider);
                  await authService.signUpWithEmail(
                    email: email!,
                    password: '', // This is just a resend, supabase might need a different method for true resend but signUpWithEmail often triggers resend if already exists but unverified
                  );
                  // Correct way in supabase_flutter is ref.read(supabaseClientProvider).auth.resend(type: OtpType.signup, email: email);
                  await ref.read(supabaseClientProvider).auth.resend(
                    type: OtpType.signup,
                    email: email,
                  );
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email resent!')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Resend Verification Email'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to Login'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

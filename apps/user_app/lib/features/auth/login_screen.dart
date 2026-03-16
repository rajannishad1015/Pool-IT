import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailMode = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Welcome Back';
    String subTitle = 'Your smart commute starts here';
    
    if (_isEmailMode) {
      title = _isSignUp ? 'Create Account' : 'Login';
      subTitle = _isSignUp 
          ? 'Verify your identity to start carpooling' 
          : 'Enter your credentials to continue';
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Center(
                child: Icon(
                  Icons.directions_car_filled,
                  size: 60,
                  color: AppColors.accentCoral,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subTitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 48),
              if (!_isEmailMode)
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: '+91 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                )
              else ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                text: _isEmailMode 
                    ? (_isSignUp ? 'Sign Up' : 'Login') 
                    : 'Continue with Phone',
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    final authService = ref.read(authServiceProvider);
                    if (_isEmailMode) {
                      if (_isSignUp) {
                        await authService.signUpWithEmail(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        if (!context.mounted) return;
                        context.push('/email-verification', extra: _emailController.text.trim());
                      } else {
                        await authService.signInWithEmail(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        // Redirect will be handled by AppRouter automatically due to authStateProvider
                      }
                    } else {
                      await authService.signInWithPhone(
                        _phoneController.text.trim(),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP sent successfully!')),
                      );
                      context.push('/otp-verification', extra: _phoneController.text.trim());
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                   const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(_isEmailMode ? 'or login with' : 'or continue with'),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEmailMode = !_isEmailMode;
                    if (!_isEmailMode) _isSignUp = false;
                  });
                },
                icon: Icon(_isEmailMode ? Icons.phone : Icons.email_outlined),
                label: Text(_isEmailMode ? 'Continue with Phone' : 'Continue with Email'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isEmailMode
                        ? (_isSignUp 
                            ? 'Already have an account? Login' 
                            : 'New to SmartPool? Join Now')
                        : 'New to SmartPool? Join Now',
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

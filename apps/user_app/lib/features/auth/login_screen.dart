import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
                  final authService = ref.read(authServiceProvider);
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  final phone = _phoneController.text.trim();

                  if (_isEmailMode) {
                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter both email and password')),
                      );
                      return;
                    }
                    if (!email.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid email address')),
                      );
                      return;
                    }
                  } else {
                    if (phone.isEmpty || phone.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
                      );
                      return;
                    }
                  }

                  setState(() => _isLoading = true);
                  try {
                    if (_isEmailMode) {
                      debugPrint('Auth: Attempting email ${_isSignUp ? "Sign Up" : "Login"} for: $email');
                      debugPrint('Auth: Password length: ${password.length}');
                      
                      if (_isSignUp) {
                        await authService.signUpWithEmail(
                          email: email,
                          password: password,
                        );
                        if (!context.mounted) return;
                        context.push('/email-verification', extra: email);
                      } else {
                        await authService.signInWithEmail(
                          email: email,
                          password: password,
                        );
                        debugPrint('Auth: Login successful for $email');
                        if (!context.mounted) return;
                        context.go('/home');
                      }
                    } else {
                      debugPrint('Auth: Attempting phone login for: $phone');
                      await authService.signInWithPhone(phone);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP sent successfully!')),
                      );
                      context.push('/otp-verification', extra: phone);
                    }
                  } on AuthException catch (e) {
                    debugPrint('Auth: Supabase AuthException (${e.statusCode}): ${e.message}');
                    if (!context.mounted) return;
                    
                    String message = e.message;
                    if (e.message.contains('Invalid login credentials')) {
                      message = 'Invalid email or password. Please check your credentials.';
                    } else if (e.message.contains('Email not confirmed')) {
                      message = 'Please confirm your email before logging in.';
                    } else if (e.message.contains('Too many requests')) {
                      message = 'Too many attempts. Please try again later.';
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } catch (e) {
                    debugPrint('Auth: Unexpected error: ${e.toString()}');
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

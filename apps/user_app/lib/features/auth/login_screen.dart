import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/supabase_providers.dart';
import '../../core/theme/app_colors.dart';

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
      backgroundColor: const Color(0xFF0A0A0A),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0xFF111111)],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                const Center(
                  child: Icon(
                    Icons.directions_car_filled,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFA0A0A0),
                  ),
                ),
                const SizedBox(height: 42),
                if (!_isEmailMode)
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: Color(0xFFBFBFBF)),
                      prefixIcon: const Icon(
                        Icons.phone,
                        color: Color(0xFFBFBFBF),
                      ),
                      prefixStyle: const TextStyle(
                        color: Color(0xFFBFBFBF),
                        fontSize: 17,
                      ),
                      prefixText: '+91 ',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF161616),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Color(0xFFBFBFBF)),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFFBFBFBF),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF161616),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Color(0xFFBFBFBF)),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFBFBFBF),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF161616),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final authService = ref.read(authServiceProvider);
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();
                            final phone = _phoneController.text.trim();

                            if (_isEmailMode) {
                              if (email.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter both email and password',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (!email.contains('@')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid email address',
                                    ),
                                  ),
                                );
                                return;
                              }
                            } else {
                              if (phone.isEmpty || phone.length < 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid 10-digit phone number',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            setState(() => _isLoading = true);
                            try {
                              if (_isEmailMode) {
                                debugPrint(
                                  'Auth: Attempting email ${_isSignUp ? "Sign Up" : "Login"} for: $email',
                                );
                                debugPrint(
                                  'Auth: Password length: ${password.length}',
                                );

                                if (_isSignUp) {
                                  await authService.signUpWithEmail(
                                    email: email,
                                    password: password,
                                  );
                                  if (!context.mounted) return;
                                  context.push(
                                    '/email-verification',
                                    extra: email,
                                  );
                                } else {
                                  await authService.signInWithEmail(
                                    email: email,
                                    password: password,
                                  );
                                  debugPrint(
                                    'Auth: Login successful for $email',
                                  );
                                  if (!context.mounted) return;
                                  context.go('/home');
                                }
                              } else {
                                debugPrint(
                                  'Auth: Attempting phone login for: $phone',
                                );
                                await authService.signInWithPhone(phone);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('OTP sent successfully!'),
                                  ),
                                );
                                context.push('/otp-verification', extra: phone);
                              }
                            } on AuthException catch (e) {
                              debugPrint(
                                'Auth: Supabase AuthException (${e.statusCode}): ${e.message}',
                              );
                              if (!context.mounted) return;

                              String message = e.message;
                              if (e.message.contains(
                                'Invalid login credentials',
                              )) {
                                message =
                                    'Invalid email or password. Please check your credentials.';
                              } else if (e.message.contains(
                                'Email not confirmed',
                              )) {
                                message =
                                    'Please confirm your email before logging in.';
                              } else if (e.message.contains(
                                'Too many requests',
                              )) {
                                message =
                                    'Too many attempts. Please try again later.';
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            } catch (e) {
                              debugPrint(
                                'Auth: Unexpected error: ${e.toString()}',
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            _isEmailMode
                                ? (_isSignUp ? 'Sign Up' : 'Login')
                                : 'Continue with Phone',
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFF3C3C3C))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _isEmailMode ? 'or login with' : 'or continue with',
                        style: const TextStyle(color: Color(0xFFB0B0B0)),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFF3C3C3C))),
                  ],
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEmailMode = !_isEmailMode;
                      if (!_isEmailMode) _isSignUp = false;
                    });
                  },
                  icon: Icon(
                    _isEmailMode ? Icons.phone : Icons.email_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isEmailMode
                        ? 'Continue with Phone'
                        : 'Continue with Email',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Color(0xFF4A4A4A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 56),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

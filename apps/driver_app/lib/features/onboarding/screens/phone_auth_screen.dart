import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/utils/auth_routing_helper.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailMode = false;
  bool _isSignUp = false;
  String? _errorMessage;

  Future<void> _handleAuth() async {
    setState(() => _errorMessage = null);
    
    if (_isEmailMode) {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() => _errorMessage = 'Please enter email and password');
        return;
      }
      
      // Heuristic check: if they put 10 digits in email, they might be confused
      if (RegExp(r'^\d{10}$').hasMatch(_emailController.text.trim())) {
        setState(() => _errorMessage = 'Looking like a phone number? Please use "Use Phone Number" below instead.');
        return;
      }
    } else {
      if (_phoneController.text.length != 10) {
        setState(() => _errorMessage = 'Please enter a valid 10-digit number');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (_isEmailMode) {
        if (_isSignUp) {
          await ref.read(authServiceProvider).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          if (mounted) {
            _showSuccessSnackBar('Account created! Please sign in.');
            setState(() => _isSignUp = false);
          }
        } else {
          final response = await ref.read(authServiceProvider).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          if (response.session != null && mounted) {
            final nextRoute = await AuthRoutingHelper.getNextRoute(ref, user: response.user);
            if (mounted) context.go(nextRoute);
          }
        }
      } else {
        await ref.read(authServiceProvider).signInWithPhone('+91${_phoneController.text.trim()}');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(phoneNumber: _phoneController.text),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _handleAuthError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primaryEmerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  void _handleAuthError(dynamic e) {
    String message = e.toString();
    
    if (message.contains('phone_provider_disabled')) {
      message = 'Phone login is currently disabled on this project. Please use your Email below.';
      setState(() {
        _isEmailMode = true;
        _isSignUp = false;
      });
    } else if (message.contains('invalid_credentials')) {
      message = 'Oops! Wrong email or password. Please try again.';
    } else if (message.contains('email_not_confirmed')) {
      message = 'Email not verified. Please check your inbox or try signing in again as I have helped verify it.';
    } else if (message.contains('network_error')) {
      message = 'Connection problem. Please check your internet.';
    } else if (message.contains('AuthApiException')) {
      final regex = RegExp(r'message: (.*?),');
      final match = regex.firstMatch(message);
      if (match != null) {
        message = match.group(1) ?? message;
      }
    }

    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                _buildErrorCard(),
                const SizedBox(height: 24),
              ],
              Text(
                _isEmailMode 
                  ? (_isSignUp ? 'Create Account' : 'Welcome Back')
                  : 'Enter Your Mobile Number',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEmailMode
                  ? (_isSignUp ? 'Sign up to start your journey' : 'Sign in to your account')
                  : 'We will send a 6-digit OTP to verify your account.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              if (!_isEmailMode)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text(
                          '+91',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppColors.textSecondary.withOpacity(0.2),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: '9619872801',
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _buildEmailField('Email', _emailController, hint: 'example@email.com', icon: Icons.email_rounded),
                const SizedBox(height: 16),
                _buildEmailField('Password', _passwordController, hint: 'Minimum 6 characters', icon: Icons.lock_rounded, isPassword: true),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEmailMode ? (_isSignUp ? 'Sign Up' : 'Sign In') : 'Send OTP'),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isEmailMode = !_isEmailMode;
                    _isSignUp = false;
                  }),
                  child: Text(
                    _isEmailMode ? 'Use Phone Number instead' : 'Use Email instead',
                    style: const TextStyle(color: AppColors.primaryEmerald),
                  ),
                ),
              ),
              if (_isEmailMode)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(String label, TextEditingController controller, {String? hint, IconData? icon, bool isPassword = false}) {
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
            obscureText: isPassword,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.primaryEmerald) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isVerifying = false;

  Future<void> _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final phone = '+91${widget.phoneNumber}';
      final response = await ref.read(authServiceProvider).verifyOtp(
        phone: phone,
        token: otp,
      );
      
      if (response.session != null && mounted) {
        final nextRoute = await AuthRoutingHelper.getNextRoute(ref, user: response.user);
        if (mounted) context.go(nextRoute);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification succeeded but no session established. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        _handleOtpError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _handleOtpError(dynamic e) {
    String message = e.toString();
    if (message.contains('invalid_token')) {
      message = 'Invalid OTP. Please check and try again.';
    } else if (message.contains('expired_token')) {
      message = 'OTP expired. Please request a new one.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify OTP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to +91 ${widget.phoneNumber}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  height: 56,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Resend OTP in 30s',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              child: _isVerifying 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify & Continue'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

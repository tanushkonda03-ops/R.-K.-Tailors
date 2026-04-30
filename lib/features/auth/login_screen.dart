import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_text_field.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/services/auth_service.dart';
import 'auth_wrapper.dart';
import 'complete_profile_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _onGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted || result == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      
      final isNew = result['isNew'] as bool;
      final user = result['user'].user!;

      if (isNew) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              uid: user.uid,
              email: user.email ?? '',
            ),
          ),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Error: ${e.toString()}')),
      );
      setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your details to login',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              NeumorphicTextField(
                hintText: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
              ),
              const SizedBox(height: 24),
              NeumorphicTextField(
                hintText: 'Password',
                controller: _passwordController,
                isPassword: true,
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onLogin(),
              ),
              
              const SizedBox(height: 40),
              
              Center(
                child: NeumorphicButton(
                  label: 'Login',
                  onTap: _onLogin,
                  isLoading: _isLoading,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.textSecondary)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.textSecondary)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Center(
                child: NeumorphicButton(
                  label: 'Continue with Google',
                  isPrimary: false,
                  onTap: _onGoogleSignIn,
                  isLoading: _isGoogleLoading,
                ),
              ),
              
              const SizedBox(height: 40),
              
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: Text(
                    'Not have an account? Create Account',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

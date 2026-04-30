import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_text_field.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/services/auth_service.dart';
import 'auth_wrapper.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty) return;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
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
                'Create Account',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the tailoring community',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              NeumorphicTextField(
                hintText: 'Username',
                controller: _usernameController,
                focusNode: _usernameFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
              ),
              const SizedBox(height: 24),
              NeumorphicTextField(
                hintText: 'Email Format',
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
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocus),
              ),
              const SizedBox(height: 24),
              NeumorphicTextField(
                hintText: 'Confirm Password',
                controller: _confirmPasswordController,
                isPassword: true,
                focusNode: _confirmPasswordFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSignUp(),
              ),
              
              const SizedBox(height: 40),
              
              Center(
                child: NeumorphicButton(
                  label: 'Sign Up',
                  onTap: _onSignUp,
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
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Already have an account? Login',
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

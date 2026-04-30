import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../../core/widgets/neumorphic_text_field.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/services/auth_service.dart';
import 'auth_wrapper.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String uid;
  final String email;

  const CompleteProfileScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _usernameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _onComplete() async {
    if (_usernameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _authService.completeGoogleProfile(
        uid: widget.uid,
        email: widget.email,
        username: _usernameController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeumorphicContainer(
                borderRadius: 24,
                padding: EdgeInsets.zero,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Complete Your Profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please pick a username to continue.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              NeumorphicTextField(
                hintText: 'Username',
                controller: _usernameController,
              ),
              const SizedBox(height: 32),
              NeumorphicButton(
                label: 'Start Tailoring',
                onTap: _onComplete,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

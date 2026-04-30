import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_container.dart';

class NeumorphicButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isLoading;

  const NeumorphicButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: NeumorphicContainer(
        borderRadius: 22,
        padding: EdgeInsets.zero,
        color: isPrimary ? null : AppColors.surface,
        isPressed: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 48),
          decoration: isPrimary
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: isPrimary
                        ? AppColors.textOnPrimary
                        : AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ] else ...[
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPrimary
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

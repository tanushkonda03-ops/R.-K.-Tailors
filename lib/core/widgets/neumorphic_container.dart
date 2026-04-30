import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable neumorphic container with light-themed raised / pressed appearance.
class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.isPressed = false,
    this.color,
    this.blurRadius = 12,
    this.offset = 6,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isPressed;
  final Color? color;
  final double blurRadius;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.background;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                // Inset-style: inverted shadows for pressed look
                BoxShadow(
                  color: AppColors.neumorphicDark.withValues(alpha: 0.45),
                  offset: Offset(offset / 2, offset / 2),
                  blurRadius: blurRadius / 2,
                ),
                BoxShadow(
                  color: AppColors.neumorphicLight.withValues(alpha: 0.8),
                  offset: Offset(-offset / 2, -offset / 2),
                  blurRadius: blurRadius / 2,
                ),
              ]
            : [
                // Raised / convex
                BoxShadow(
                  color: AppColors.neumorphicDark.withValues(alpha: 0.35),
                  offset: Offset(offset, offset),
                  blurRadius: blurRadius,
                ),
                BoxShadow(
                  color: AppColors.neumorphicLight.withValues(alpha: 0.9),
                  offset: Offset(-offset, -offset),
                  blurRadius: blurRadius,
                ),
              ],
      ),
      child: child,
    );
  }
}

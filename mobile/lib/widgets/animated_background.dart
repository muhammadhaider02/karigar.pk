import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Light-mode ambient background with subtle gradient overlay
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: child,
    );
  }
}

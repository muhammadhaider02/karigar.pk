import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Karigar AI brand logo widget — wrench + K monogram in green circle
class KarigarLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool darkBg;

  const KarigarLogo({
    super.key,
    this.size = 72,
    this.showText = false,
    this.darkBg = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.5;
    final textColor = darkBg ? Colors.white : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: size * 0.4,
                spreadRadius: size * 0.05,
              ),
            ],
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.build_rounded, color: Colors.white.withValues(alpha: 0.2), size: iconSize * 1.1),
                Icon(Icons.build_rounded, color: Colors.white, size: iconSize * 0.85),
                Positioned(
                  bottom: size * 0.1,
                  right: size * 0.1,
                  child: Container(
                    width: size * 0.28,
                    height: size * 0.28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryContainer,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'K',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: size * 0.14,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          Text(
            'Karigar AI',
            style: TextStyle(
              color: textColor,
              fontSize: size * 0.25,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: size * 0.04),
          Text(
            "Pakistan's Smart Service Marketplace",
            style: TextStyle(
              color: darkBg ? Colors.white70 : AppColors.onSurfaceVariant,
              fontSize: size * 0.12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

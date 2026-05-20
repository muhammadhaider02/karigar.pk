import 'dart:async';
import 'package:flutter/material.dart';

class AgentLoaderOverlay extends StatefulWidget {
  const AgentLoaderOverlay({super.key});

  @override
  State<AgentLoaderOverlay> createState() => _AgentLoaderOverlayState();
}

class _AgentLoaderOverlayState extends State<AgentLoaderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotation;

  static const _tips = [
    '73 registered workers near you',
    'Matching your location to nearby workers...',
    'Checking ratings and availability...',
    'Almost done — finding the best match!',
  ];

  int _tipIndex = 0;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _rotation = Tween<double>(begin: 0, end: 1).animate(_rotationController);

    _tipTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() {
          _tipIndex = (_tipIndex + 1) % _tips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _rotation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF075E54),
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF075E54)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'AI Dhundh Raha Hai...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Text(
                  _tips[_tipIndex],
                  key: ValueKey(_tipIndex),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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

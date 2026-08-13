import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class TimeWidget extends StatefulWidget {
  const TimeWidget({super.key});

  @override
  State<TimeWidget> createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late DateTime _currentTime;

  // Zero-lag hardware scale controller
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 25),      // Ultra-fast press down
    reverseDuration: const Duration(milliseconds: 200), // Instant spring pop back
  );

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 1.0,
    end: 0.94,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
      reverseCurve: Curves.easeOutBack, // iOS spring overshoot
    ),
  );

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _getFormattedDate(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}';
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapRelease() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _getFormattedDate(_currentTime);

    int hour = _currentTime.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    hour = hour == 0 ? 12 : hour;
    final minute = _currentTime.minute.toString().padLeft(2, '0');

    const hourRed = Color(0xFFFF3B30);
    const textWhite = Color(0xFFFFFFFF);
    const textSubtle = Color(0xFF9E9EA5);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: (_) => _handleTapRelease(),
      onTapCancel: _handleTapRelease,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        // Cached child prevents GPU blur re-render lag during scaling
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF111318).withOpacity(0.65),
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(
                          color: textSubtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$hour',
                          style: const TextStyle(
                            color: hourRed,
                          ),
                        ),
                        TextSpan(
                          text: ':$minute $ampm',
                          style: const TextStyle(
                            color: textWhite,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';

class DotSystem extends StatelessWidget {
  final int currentIndex;
  final int itemCount;
  final Function(int)? onTabSelected;

  const DotSystem({
    super.key,
    required this.currentIndex,
    required this.itemCount,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) {
        final bool isActive = currentIndex == index;

        return GestureDetector(
          onTap: () => onTabSelected?.call(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            // 👈 Reduced horizontal margin to bring them closer together
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            height: 8.0,
            width: isActive ? 28.0 : 8.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive
                          ? [
                        Colors.redAccent.withOpacity(0.85),
                        Colors.red.shade900.withOpacity(0.75),
                      ]
                          : [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: isActive
                          ? Colors.redAccent.shade100.withOpacity(0.6)
                          : Colors.white.withOpacity(0.2),
                      width: 0.8,
                    ),
                    boxShadow: isActive
                        ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 10.0,
                        spreadRadius: 1.0,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 2.0,
                        spreadRadius: 0.0,
                        offset: const Offset(0, -1),
                      ),
                    ]
                        : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
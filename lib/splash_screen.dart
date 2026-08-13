import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Step 1 Controller
  late final AnimationController _progressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  // Step 2 Controller (Handles Bar fade, Color change, and Scale simultaneously)
  late final AnimationController _transitionController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  // Step 3 Controller
  late final AnimationController _screenFadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _runAnimationSequence();
  }

  // Cleanly sequenced animation flow using async/await
  Future<void> _runAnimationSequence() async {
    // Step 1: Smoothly fill the loading bar
    await _progressController.forward();

    if (!mounted) return;

    // Step 2: Fade out loading bar, make full text RED, and expand to full screen
    await _transitionController.forward();

    if (!mounted) return;

    // Step 3: Hold full screen red text, then fade out screen over 1 second
    await _screenFadeController.forward();

    if (!mounted) return;

    // Step 4: Open Home Screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // A quick cross-fade to ensure smooth hand-off to the HomeScreen
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _transitionController.dispose();
    _screenFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color accentRed = Color(0xFFFF002F);

    // Step 1: Progress filling
    final Animation<double> progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.fastOutSlowIn,
    );

    // Step 2 parallel animations mapped using Intervals based on the 800ms duration
    final Animation<double> barFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.5), // Finishes in 400ms (0.5 * 800ms)
      ),
    );

    final Animation<Color?> colorProgress = ColorTween(
      begin: Colors.white,
      end: accentRed,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.75), // Finishes in 600ms (0.75 * 800ms)
      ),
    );

    final Animation<double> textScaleAnimation = Tween<double>(begin: 1.0, end: 4.5).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.fastOutSlowIn, // Takes the full 800ms
      ),
    );

    // Step 3 fade out entire screen
    final Animation<double> screenAlpha = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _screenFadeController,
        curve: Curves.linear,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _progressController,
          _transitionController,
          _screenFadeController,
        ]),
        builder: (context, child) {
          return Opacity(
            // Fade out the entire layout (Step 3)
            opacity: screenAlpha.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "Arc" Text scaling up
                  Transform.scale(
                    scale: textScaleAnimation.value,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'A',
                            style: TextStyle(color: accentRed),
                          ),
                          TextSpan(
                            text: 'rc',
                            style: TextStyle(color: colorProgress.value), // Interpolates White -> Red
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 52),

                  // Minimalist macOS-style loading bar
                  Opacity(
                    opacity: barFadeAnimation.value,
                    child: Container(
                      width: 180,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(2.0), // Equivalent to CircleShape for 4dp height
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:window_manager/window_manager.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768),
      minimumSize: Size(600, 700),
      center: true,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ArcistApp());
}

class ArcistApp extends StatelessWidget {
  const ArcistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      builder: (context, child) {
        // Pre-cache background images so they load instantly without UI hiccups
        precacheImage(const AssetImage('assets/images/MBG.png'), context);
        precacheImage(const AssetImage('assets/images/LBG.png'), context);

        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 600;

        return Stack(
          children: [
            // RepaintBoundary prevents background from re-rendering when UI animates
            Positioned.fill(
              child: RepaintBoundary(
                child: Image.asset(
                  isMobile ? 'assets/images/MBG.png' : 'assets/images/LBG.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low, // Reduces memory footprint on low-end GPUs
                ),
              ),
            ),
            if (child != null) child,
          ],
        );
      },
      home: const SplashScreen(),
    );
  }
}
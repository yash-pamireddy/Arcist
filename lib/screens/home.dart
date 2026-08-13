import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/registry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _dragOffset = 0.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get top system padding (accounts for phone notch/punch-hole camera)
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            setState(() {
              _dragOffset = _scrollController.offset;
            });
          }
          return true;
        },
        child: Stack(
          children: [
            // Vibrant liquid mesh gradient background filling the entire screen edge-to-edge
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F172A), // Deep Slate
                      Color(0xFF2E1065), // Rich Purple
                      Color(0xFF831843), // Deep Rose / Pink
                      Color(0xFF0E7490), // Cyan / Teal
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Multiple Floating Ambient Glowing Bulbs reacting to drag parallax
            Positioned(
              top: -50 - (_dragOffset * 0.35),
              left: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pinkAccent.withOpacity(0.28),
                ),
              ),
            ),
            Positioned(
              top: 200 + (_dragOffset * 0.15),
              right: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent.withOpacity(0.2),
                ),
              ),
            ),
            Positioned(
              bottom: 120 - (_dragOffset * 0.25),
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amberAccent.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -80 + (_dragOffset * 0.3),
              right: -40,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withOpacity(0.22),
                ),
              ),
            ),

            // Full screen layout with elastic scrolling and automatic front-camera clearance
            ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(20.0, topPadding + 16.0, 20.0, 20.0),
              itemCount: widgetRegistryList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: widgetRegistryList[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
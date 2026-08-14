// lib/screens/home.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/registry.dart';
import '../Plugin/DotSystem.dart';
import 'Menu.dart';
import 'Profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              const MenuScreen(),
              ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(20.0, topPadding + 16.0, 20.0, bottomPadding + 100.0),
                children: [
                  ...widgetRegistryList.map(
                        (widget) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: widget,
                    ),
                  ),
                ],
              ),
              const ProfileScreen(),
            ],
          ),
          Positioned(
            bottom: bottomPadding + 20.0,
            left: 0,
            right: 0,
            child: Center(
              child: DotSystem(
                currentIndex: _currentPage,
                itemCount: 3,
                onTabSelected: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PulseWidget extends StatefulWidget {
  const PulseWidget({super.key});

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> with TickerProviderStateMixin {
  // Configured to your repository: yash-pamireddy/Arcist
  final String _repoOwner = 'yash-pamireddy';
  final String _repoName = 'Arcist';
  final String _currentVersion = 'v1.00'; // Current installed version

  bool _isExpanded = false;
  bool _isLoading = true;
  bool _isUpToDate = false;
  bool _hasError = false;

  // Download & Install Workflow States
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isReadyToInstall = false;

  String _latestVersion = '';
  String _releaseNotes = '';

  late final AnimationController _popController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 25),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 1.0,
    end: 0.94,
  ).animate(
    CurvedAnimation(
      parent: _popController,
      curve: Curves.linear,
      reverseCurve: Curves.easeOutBack,
    ),
  );

  late final AnimationController _expandController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _expandAnimation = CurvedAnimation(
    parent: _expandController,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _fetchArcistRelease();
  }

  @override
  void dispose() {
    _popController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  // --- Fetch Latest Release from GitHub ---
  Future<void> _fetchArcistRelease() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest');
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github+json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tag = data['tag_name'] ?? 'v1.06';
        final body = (data['body'] as String?)?.trim();

        setState(() {
          _latestVersion = tag;
          _releaseNotes = (body != null && body.isNotEmpty) ? body : 'Arcist latest update details and bug fixes.';
          _isLoading = false;
          _isUpToDate = (_currentVersion.toLowerCase() == tag.toLowerCase());
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _toggleExpand() {
    if (_isUpToDate || _isDownloading) return;

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  // --- Simulate Download Progress ---
  void _startDownloadSimulation() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    const totalSteps = 40;
    int currentStep = 0;

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      currentStep++;
      setState(() {
        _downloadProgress = currentStep / totalSteps;
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        setState(() {
          _isDownloading = false;
          _isReadyToInstall = true;
        });
      }
    });
  }

  // --- Install Action ---
  void _installUpdate() {
    setState(() {
      _isReadyToInstall = false;
      _isUpToDate = true;
      _isExpanded = false;
      _expandController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _popController.forward(),
      onTapUp: (_) => _popController.reverse(),
      onTapCancel: () => _popController.reverse(),
      onTap: _toggleExpand,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _popController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF111318).withOpacity(0.65),
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Header Row ---
                  Row(
                    children: [
                      // Download Icon
                      AnimatedBuilder(
                        animation: _expandAnimation,
                        builder: (context, child) {
                          final Color iconColor = Color.lerp(
                            Colors.white70,
                            const Color(0xFFFF3B30),
                            _expandAnimation.value,
                          )!;

                          return Icon(
                            Icons.download_rounded,
                            color: iconColor,
                            size: 22,
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      // Center Title & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Pulse',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isLoading
                                  ? 'Checking GitHub...'
                                  : _isUpToDate
                                  ? 'Up-to-date'
                                  : 'Arc system',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isUpToDate ? const Color(0xFFFF3B30) : Colors.white54,
                                fontSize: 12,
                                fontWeight: _isUpToDate ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Arrow Indicator or Loader
                      if (!_isUpToDate && !_isLoading)
                        RotationTransition(
                          turns: Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                        )
                      else if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                        )
                      else
                        const SizedBox(width: 24),
                    ],
                  ),

                  // --- Expandable Content ---
                  if (!_isUpToDate && !_isLoading)
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      child: FadeTransition(
                        opacity: _expandAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Divider(color: Colors.white12, height: 28),
                            Text(
                              _hasError
                                  ? 'Unable to fetch GitHub release'
                                  : 'Arcist $_latestVersion Available',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _hasError
                                  ? 'Check connection or repository permissions.'
                                  : _releaseNotes.length > 120
                                  ? '${_releaseNotes.substring(0, 120)}...'
                                  : _releaseNotes,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // --- Dynamic Action Area (Download -> Progress -> Install) ---
                            if (!_hasError) ...[
                              if (_isDownloading) ...[
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: _downloadProgress,
                                        backgroundColor: Colors.white12,
                                        color: const Color(0xFF34D399),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Downloading... ${(_downloadProgress * 100).toInt()}%',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ] else if (_isReadyToInstall) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _installUpdate,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF3B30), // Red install button highlight
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Install Update',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _startDownloadSimulation,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF34D399),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Download',
                                            style: TextStyle(
                                              color: Color(0xFF111318),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
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
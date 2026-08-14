import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_version.dart';

class PulseWidget extends StatefulWidget {
  const PulseWidget({super.key});

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> with TickerProviderStateMixin {
  final String _repoOwner = 'yash-pamireddy';
  final String _repoName = 'Arcist';
  final String _currentVersion = AppVersionConfig.currentVersion;

  bool _isExpanded = false;
  bool _isLoading = true;
  bool _isUpToDate = false;
  bool _hasError = false;

  bool _isConfirmingUpdate = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _downloadedBytes = 0;
  int _assetSizeBytes = 20971520;
  bool _isReadyToInstall = false;

  String _latestVersion = '';
  String _releaseNotes = '';
  String _assetDownloadUrl = '';
  String? _localFilePath;

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
    _fetchReleaseAsset();
  }

  @override
  void dispose() {
    _popController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get _formattedTotalSize => _formatBytes(_assetSizeBytes);
  String get _formattedDownloadedSize => _formatBytes(_downloadedBytes);
  String get _formattedRemainingSize {
    final remaining = _assetSizeBytes - _downloadedBytes;
    return _formatBytes(remaining > 0 ? remaining : 0);
  }

  /// Platform-aware target extension lookup
  List<String> _getPlatformExtensions() {
    if (kIsWeb) return ['.zip', '.html'];
    if (Platform.isAndroid) return ['.apk', '.aab'];
    if (Platform.isWindows) return ['.exe', '.msi', '.zip'];
    if (Platform.isMacOS) return ['.dmg', '.pkg', '.zip'];
    if (Platform.isLinux) return ['.appimage', '.deb', '.rpm', '.tar.gz', '.zip'];
    if (Platform.isIOS) return ['.ipa'];
    return [];
  }

  Future<void> _fetchReleaseAsset() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest');
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github+json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tag = data['tag_name'] ?? 'v1.0';
        final body = (data['body'] as String?)?.trim();

        dynamic matchedAsset;
        final assets = data['assets'] as List?;

        if (assets != null && assets.isNotEmpty) {
          final targetExtensions = _getPlatformExtensions();

          // Search strictly for assets matching current device platform
          for (final ext in targetExtensions) {
            for (var asset in assets) {
              final name = asset['name'].toString().toLowerCase();
              if (name.endsWith(ext)) {
                matchedAsset = asset;
                break;
              }
            }
            if (matchedAsset != null) break;
          }
        }

        String cleanVersion(String v) {
          return v.toLowerCase()
              .replaceAll('v', '')
              .split('+')
              .first
              .split('-')
              .first
              .trim();
        }

        final currentClean = cleanVersion(_currentVersion);
        final latestClean = cleanVersion(tag);

        final bool hasNewVersion = (currentClean != latestClean);
        final bool hasCompatibleFile = (matchedAsset != null);

        // ONLY mark update available if both version is newer AND platform file exists
        final bool updateAvailable = hasNewVersion && hasCompatibleFile;

        setState(() {
          _latestVersion = tag;
          _releaseNotes = (body != null && body.isNotEmpty)
              ? body
              : 'Arcist latest update details and bug fixes.';

          if (matchedAsset != null) {
            _assetDownloadUrl = matchedAsset['browser_download_url'] ?? '';
            _assetSizeBytes = matchedAsset['size'] ?? 20971520;
          } else {
            _assetDownloadUrl = '';
          }

          _isLoading = false;
          _isUpToDate = !updateAvailable;
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
        _isConfirmingUpdate = false;
        _expandController.reverse();
      }
    });
  }

  Future<void> _startRealDownload() async {
    if (_assetDownloadUrl.isEmpty) return;

    setState(() {
      _isConfirmingUpdate = false;
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadedBytes = 0;
    });

    try {
      final request = http.Request('GET', Uri.parse(_assetDownloadUrl));
      final streamedResponse = await http.Client().send(request);

      final contentLength = streamedResponse.contentLength ?? _assetSizeBytes;
      if (contentLength > 0) {
        _assetSizeBytes = contentLength;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = _assetDownloadUrl.split('/').last.split('?').first;
      final filePath = '${tempDir.path}/${fileName.isNotEmpty ? fileName : 'update_file'}';
      final file = File(filePath);

      List<int> bytes = [];

      streamedResponse.stream.listen(
            (chunk) {
          bytes.addAll(chunk);
          _downloadedBytes += chunk.length;
          if (_assetSizeBytes > 0) {
            setState(() {
              _downloadProgress = _downloadedBytes / _assetSizeBytes;
            });
          }
        },
        onDone: () async {
          await file.writeAsBytes(bytes);
          setState(() {
            _isDownloading = false;
            _isReadyToInstall = true;
            _localFilePath = filePath;
          });
        },
        onError: (_) {
          setState(() {
            _isDownloading = false;
            _hasError = true;
          });
        },
        cancelOnError: true,
      );
    } catch (_) {
      setState(() {
        _isDownloading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _installUpdate() async {
    if (_localFilePath != null) {
      final file = File(_localFilePath!);
      if (await file.exists()) {
        final result = await OpenFilex.open(_localFilePath!);
        if (result.type != ResultType.done) {
          final uri = Uri.parse(_assetDownloadUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } else if (_assetDownloadUrl.isNotEmpty) {
      final uri = Uri.parse(_assetDownloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    // Terminate app process immediately so the installer can update files seamlessly
    exit(0);
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
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
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
                  Row(
                    children: [
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
                                  ? 'Checking Arc Studio...'
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
                  if (!_isUpToDate && !_isLoading)
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      child: FadeTransition(
                        opacity: _expandAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Divider(color: Colors.white12, height: 28),
                            if (_isDownloading)
                              _buildDownloadingView()
                            else if (_isConfirmingUpdate)
                              _buildConfirmationView()
                            else ...[
                                Text(
                                  _hasError
                                      ? 'Unable to fetch Arc Studio release'
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
                                      ? 'Check network connection or settings.'
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
                                if (!_hasError) _buildActionSection(),
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
      ),
    );
  }

  Widget _buildConfirmationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 18),
            SizedBox(width: 6),
            Text(
              'Update Warning',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            children: [
              const TextSpan(text: 'Update size is '),
              TextSpan(
                text: _formattedTotalSize,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const TextSpan(text: '. Make sure you are connected to a stable network before downloading.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _isConfirmingUpdate = false),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startRealDownload,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Update',
                        style: TextStyle(color: Color(0xFF111318), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadingView() {
    final percent = (_downloadProgress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
              backgroundColor: Colors.white12,
              color: Colors.white,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Downloading update... $percent%',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                  text: _formattedDownloadedSize,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' / '),
                TextSpan(
                  text: _formattedTotalSize,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' (Left: '),
                TextSpan(
                  text: _formattedRemainingSize,
                  style: const TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ')'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (_isReadyToInstall) {
      return SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _installUpdate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Install Update',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isConfirmingUpdate = true),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Download',
                  style: TextStyle(color: Color(0xFF111318), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
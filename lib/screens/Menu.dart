// lib/screens/Menu.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/registry.dart';
import '../widgets/extension_item.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _isRefreshing = false;

  Future<void> _fetchExtensionsFromGitHub() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // 1. Fetch file list from your GitHub repository
      final client = HttpClient();
      final uri = Uri.parse('https://api.github.com/repos/yash-pamireddy/Arcist-Extensions/contents');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Arcist-App');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch extensions from GitHub (status ${response.statusCode})');
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final List<dynamic> filesJson = jsonDecode(responseBody);

      // Ensure local widgets directory exists
      final directory = Directory('lib/widgets');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // 2. Download each .dart file from the repository
      for (var fileNode in filesJson) {
        if (fileNode['type'] == 'file' && fileNode['name'].toString().endsWith('.dart')) {
          final fileName = fileNode['name'].toString();
          final downloadUrl = fileNode['download_url'].toString();

          if (fileName == 'registry.dart' || fileName == 'extension_item.dart') {
            continue;
          }

          final fileRequest = await client.getUrl(Uri.parse(downloadUrl));
          final fileResponse = await fileRequest.close();
          if (fileResponse.statusCode == 200) {
            final fileContent = await fileResponse.transform(utf8.decoder).join();
            File('lib/widgets/$fileName').writeAsStringSync(fileContent);
          }
        }
      }
      client.close();

      // 3. Automatically regenerate registry.dart based on downloaded files
      _generateLocalRegistry(directory);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle network or parsing errors quietly
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _generateLocalRegistry(Directory directory) {
    final files = directory.listSync().whereType<File>().toList();
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'extension_item.dart';");

    List<String> widgetNames = [];

    for (var file in files) {
      final fileName = file.path.split(Platform.pathSeparator).last;

      if (fileName == 'registry.dart' ||
          fileName == 'widgets.dart' ||
          fileName == 'extension_item.dart' ||
          !fileName.endsWith('.dart')) {
        continue;
      }

      buffer.writeln("import '$fileName';");

      final content = file.readAsStringSync();
      final match = RegExp(r'class\s+([A-Za-z0-9_]+)\s+extends\s+(StatefulWidget|StatelessWidget)').firstMatch(content);

      if (match != null && match.group(1) != null) {
        widgetNames.add(match.group(1)!);
      }
    }

    buffer.writeln('\nList<ExtensionItem> extensionRegistry = [');
    for (var widgetName in widgetNames) {
      buffer.writeln("  ExtensionItem(name: '$widgetName', widget: const $widgetName()),");
    }
    buffer.writeln('];');

    buffer.writeln('\nList<Widget> get widgetRegistryList {');
    buffer.writeln('  return extensionRegistry');
    buffer.writeln('      .where((item) => item.isEnabled)');
    buffer.writeln('      .map((item) => item.widget)');
    buffer.writeln('      .toList();');
    buffer.writeln('}');

    File('lib/widgets/registry.dart').writeAsStringSync(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    final installedWidgets = extensionRegistry.where((item) => item.isEnabled).toList();
    final uninstalledWidgets = extensionRegistry.where((item) => !item.isEnabled).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(20.0, topPadding + 115.0, 20.0, bottomPadding + 80.0),
              children: [
                const Text(
                  'Installed Widgets',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (installedWidgets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'No widgets installed.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                else
                  ...installedWidgets.map((item) => _buildExtensionToggleCard(item)),

                const SizedBox(height: 16),

                const Text(
                  'Uninstalled Widgets',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (uninstalledWidgets.isEmpty)
                  const Text(
                    'No uninstalled widgets.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  )
                else
                  ...uninstalledWidgets.map((item) => _buildExtensionToggleCard(item)),
              ],
            ),
          ),
          Positioned(
            top: topPadding + 16.0,
            left: 20.0,
            right: 20.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111318).withOpacity(0.65),
                    borderRadius: BorderRadius.circular(24),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.extension_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Extensions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _isRefreshing
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Icon(Icons.refresh_rounded, color: Colors.white),
                        onPressed: _isRefreshing ? null : _fetchExtensionsFromGitHub,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionToggleCard(ExtensionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF111318).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.widgets_rounded, color: Colors.white70, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: item.isEnabled,
                  activeColor: Colors.blueAccent,
                  onChanged: (bool value) {
                    setState(() {
                      item.isEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
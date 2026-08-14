// tool/generate_registry.dart
import 'dart:io';

void main() {
  final directory = Directory('lib/widgets');
  if (!directory.existsSync()) return;

  final files = directory.listSync().whereType<File>().toList();
  final buffer = StringBuffer();

  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln("import 'package:flutter/material.dart';\n");

  List<String> widgetNames = [];

  for (var file in files) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    
    // Skip registry and barrel files
    if (fileName == 'registry.dart' || fileName == 'widgets.dart' || !fileName.endsWith('.dart')) {
      continue;
    }

    buffer.writeln("import '$fileName';");

    // Read file contents to find the class name automatically
    final content = file.readAsStringSync();
    final match = RegExp(r'class\s+([A-Za-z0-9_]+)\s+extends\s+(StatefulWidget|StatelessWidget)').firstMatch(content);
    
    if (match != null && match.group(1) != null) {
      widgetNames.add(match.group(1)!);
    }
  }

  buffer.writeln('\nfinal List<Widget> widgetRegistryList = [');
  for (var widgetName in widgetNames) {
    buffer.writeln('  const $widgetName(),');
    buffer.writeln('  const SizedBox(height: 14),');
  }
  buffer.writeln('];');

  File('lib/widgets/registry.dart').writeAsStringSync(buffer.toString());
  print('✨ Registry auto-updated successfully with ${widgetNames.length} widgets!');
}
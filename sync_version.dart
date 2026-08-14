import 'dart:io';

void main() async {
  final versionFile = File('lib/app_version.dart');
  final pubspecFile = File('pubspec.yaml');

  if (!versionFile.existsSync() || !pubspecFile.existsSync()) {
    print('❌ Error: Files missing. Make sure lib/app_version.dart exists.');
    return;
  }

  // 1. Read version from your app_version.dart file
  final versionContent = await versionFile.readAsString();
  final versionMatch = RegExp(r"currentVersion = '([^']+)';").firstMatch(versionContent);

  if (versionMatch == null) {
    print('❌ Could not find currentVersion in lib/app_version.dart');
    return;
  }

  // 2. Clean the version string (Strip 'v' and handle 2-part vs 3-part formatting)
  String rawVersion = versionMatch.group(1)!.trim().toLowerCase();
  if (rawVersion.startsWith('v')) {
    rawVersion = rawVersion.substring(1); // Removes 'v' (e.g., v1.0 -> 1.0)
  }

  // Ensure 3 parts (e.g., '1.0' automatically becomes '1.0.0')
  List<String> parts = rawVersion.split('.');
  while (parts.length < 3) {
    parts.add('0');
  }
  String cleanVersion = parts.take(3).join('.');

  // 3. Keep the existing build number from pubspec.yaml
  int build = 1;
  final pubspecLines = await pubspecFile.readAsLines();
  for (var line in pubspecLines) {
    if (line.trim().startsWith('version:')) {
      final pubspecParts = line.split('+');
      if (pubspecParts.length > 1) {
        build = int.tryParse(pubspecParts[1].trim()) ?? 1;
      }
    }
  }

  String targetVersionLine = 'version: $cleanVersion+$build';

  // 4. Modify pubspec.yaml automatically
  bool updated = false;
  final newLines = pubspecLines.map((line) {
    if (line.trim().startsWith('version:')) {
      updated = true;
      return targetVersionLine;
    }
    return line;
  }).toList();

  if (!updated) {
    print('❌ Could not find version line in pubspec.yaml');
    return;
  }

  await pubspecFile.writeAsString(newLines.join('\n') + '\n');
  print('✨ Successfully synced version to: $targetVersionLine');
}
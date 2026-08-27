import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  static Directory? _support;

  static Future<Directory> supportDir() async {
    if (_support != null) return _support!;
    final base = await getApplicationSupportDirectory();
    _support = base;
    return base;
  }

  static Future<Directory> projectsDir() async {
    final s = await supportDir();
    final d = Directory(p.join(s.path, 'projects'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<File> projectsJson() async {
    final s = await supportDir();
    return File(p.join(s.path, 'projects.json'));
  }

  static String artifactsPathFor(String projectPath) =>
      p.join(projectPath, '_artifacts');
}

Map<String, String> buildEnv(String workspace, {Map<String, String>? extra}) {
  final env = Map<String, String>.from(Platform.environment);
  const extraPaths = [
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin',
  ];

  final flutterBin = _flutterBin();
  final existing = env['PATH'] ?? '';
  final parts = <String>[
    ...extraPaths,
    if (flutterBin != null) flutterBin,
    if (existing.isNotEmpty) existing,
  ];
  final seen = <String>{};
  final merged = parts.where((s) => s.isNotEmpty && seen.add(s)).join(':');
  env['PATH'] = merged;
  env['GITHUB_WORKSPACE'] = workspace;
  env['CI'] = 'true';
  if (extra != null) env.addAll(extra);
  return env;
}

String? _flutterBin() {
  final candidates = <String>[
    '/Applications/flutter/bin',
    p.join(Platform.environment['HOME'] ?? '', 'flutter', 'bin'),
    p.join(Platform.environment['HOME'] ?? '', 'development', 'flutter', 'bin'),
    '/opt/flutter/bin',
  ];
  for (final c in candidates) {
    if (c.isEmpty) continue;
    if (Directory(c).existsSync()) return c;
  }
  return null;
}

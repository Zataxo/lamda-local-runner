import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class RepoPubspec {
  final String? name;
  final String? description;
  final String? version;
  RepoPubspec({this.name, this.description, this.version});
  bool get isEmpty => name == null && description == null && version == null;
}

Future<RepoPubspec?> readRepoPubspec(String repoPath) async {
  final f = File(p.join(repoPath, 'pubspec.yaml'));
  if (!await f.exists()) return null;
  try {
    final raw = await f.readAsString();
    final doc = loadYaml(raw);
    if (doc is! YamlMap) return null;
    return RepoPubspec(
      name: doc['name']?.toString(),
      description: doc['description']?.toString(),
      version: doc['version']?.toString(),
    );
  } catch (_) {
    return null;
  }
}

String timeAgo(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m minute${m == 1 ? "" : "s"} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hour${h == 1 ? "" : "s"} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d day${d == 1 ? "" : "s"} ago';
  }
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    return '$w week${w == 1 ? "" : "s"} ago';
  }
  if (diff.inDays < 365) {
    final mo = (diff.inDays / 30).floor();
    return '$mo month${mo == 1 ? "" : "s"} ago';
  }
  final y = (diff.inDays / 365).floor();
  return '$y year${y == 1 ? "" : "s"} ago';
}

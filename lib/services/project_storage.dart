import 'dart:convert';
import 'dart:io';

import '../models/project.dart';
import 'path_utils.dart';

class ProjectStorage {
  Future<List<Project>> load() async {
    final f = await AppPaths.projectsJson();
    if (!await f.exists()) return [];
    try {
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return [];
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    } on FileSystemException {
      return [];
    }
  }

  Future<void> save(List<Project> projects) async {
    final f = await AppPaths.projectsJson();
    final data = projects.map((p) => p.toJson()).toList();
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}

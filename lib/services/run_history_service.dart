import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/run_record.dart';
import 'path_utils.dart';

class RunHistoryService {
  static const int maxPerProject = 50;

  Future<Directory> _dirFor(String projectId) async {
    final s = await AppPaths.supportDir();
    final d = Directory(p.join(s.path, 'runs', projectId));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<void> save(RunRecord rec) async {
    final d = await _dirFor(rec.projectId);
    final f = File(p.join(d.path, '${rec.id}.json'));
    await f.writeAsString(
        const JsonEncoder.withIndent('  ').convert(rec.toJson()));
    await prune(rec.projectId);
  }

  Future<List<RunRecord>> list(String projectId) async {
    final d = await _dirFor(projectId);
    final files = <File>[];
    await for (final e in d.list(followLinks: false)) {
      if (e is File && e.path.endsWith('.json')) files.add(e);
    }
    final records = <RunRecord>[];
    for (final f in files) {
      try {
        final raw = await f.readAsString();
        final j = jsonDecode(raw) as Map<String, dynamic>;
        records.add(RunRecord.fromJson(j));
      } catch (_) {}
    }
    records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return records;
  }

  Future<RunRecord?> load(String projectId, String id) async {
    final d = await _dirFor(projectId);
    final f = File(p.join(d.path, '$id.json'));
    if (!await f.exists()) return null;
    try {
      final raw = await f.readAsString();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return RunRecord.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String projectId, String id) async {
    final d = await _dirFor(projectId);
    final f = File(p.join(d.path, '$id.json'));
    if (await f.exists()) await f.delete();
  }

  Future<void> prune(String projectId, {int max = maxPerProject}) async {
    final records = await list(projectId);
    if (records.length <= max) return;
    for (final r in records.sublist(max)) {
      await delete(projectId, r.id);
    }
  }

  Future<void> deleteAll(String projectId) async {
    final d = await _dirFor(projectId);
    if (await d.exists()) {
      await for (final e in d.list()) {
        if (e is File) await e.delete();
      }
    }
  }
}

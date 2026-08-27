import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../services/git_service.dart';
import '../services/path_utils.dart';
import '../services/project_storage.dart';

class ProjectsProvider extends ChangeNotifier {
  final GitService _git = GitService();
  final ProjectStorage _storage = ProjectStorage();

  final List<Project> _projects = [];
  Project? _selected;
  bool _loaded = false;

  List<Project> get projects => List.unmodifiable(_projects);
  Project? get selected => _selected;
  bool get loaded => _loaded;

  Future<void> loadIfNeeded() async {
    if (_loaded) return;
    final list = await _storage.load();
    _projects
      ..clear()
      ..addAll(list);
    _loaded = true;
    notifyListeners();
  }

  void select(Project? p) {
    _selected = p;
    notifyListeners();
  }

  Future<Project> cloneRepo({
    required String url,
    required void Function(String line, bool isErr) onLine,
  }) async {
    final projectsDir = await AppPaths.projectsDir();
    final name = _git.repoNameFromUrl(url);
    var target = p.join(projectsDir.path, name);
    var suffix = 1;
    while (await Directory(target).exists()) {
      suffix++;
      target = p.join(projectsDir.path, '$name-$suffix');
    }

    onLine('Cloning $url into $target …', false);
    final res = await _git.clone(url: url, targetDir: target, onLine: onLine);
    if (!res.ok) {
      throw StateError('git clone failed (exit ${res.exitCode})');
    }

    final branch = await _git.currentBranch(target);
    final proj = Project(
      id: const Uuid().v4(),
      name: p.basename(target),
      localPath: target,
      repoUrl: url,
      lastBranch: branch,
    );
    _projects.add(proj);
    await _storage.save(_projects);
    _selected = proj;
    notifyListeners();
    return proj;
  }

  Future<Project> importLocal(String localPath) async {
    final dir = Directory(localPath);
    if (!await dir.exists()) {
      throw StateError('Path does not exist: $localPath');
    }
    final dotGit = Directory(p.join(localPath, '.git'));
    if (!await dotGit.exists()) {
      throw StateError('Not a git repo (no .git dir): $localPath');
    }
    final branch = await _git.currentBranch(localPath);
    final proj = Project(
      id: const Uuid().v4(),
      name: p.basename(localPath),
      localPath: localPath,
      repoUrl: null,
      lastBranch: branch,
    );
    _projects.add(proj);
    await _storage.save(_projects);
    _selected = proj;
    notifyListeners();
    return proj;
  }

  Future<void> removeProject(Project proj, {bool deleteFiles = false}) async {
    _projects.removeWhere((p) => p.id == proj.id);
    if (_selected?.id == proj.id) _selected = null;
    if (deleteFiles && proj.repoUrl != null) {
      try {
        final d = Directory(proj.localPath);
        if (await d.exists()) await d.delete(recursive: true);
      } catch (_) {}
    }
    await _storage.save(_projects);
    notifyListeners();
  }

  Future<List<String>> listBranches(Project proj) async {
    final remote = await _git.remoteBranches(proj.localPath);
    final local = await _git.localBranches(proj.localPath);
    final all = <String>{...local, ...remote}.toList()..sort();
    return all;
  }

  Future<String?> currentBranch(Project proj) =>
      _git.currentBranch(proj.localPath);

  Future<void> setArtifactsPath(Project proj, String? path) async {
    proj.artifactsPath = (path == null || path.trim().isEmpty) ? null : path;
    await _storage.save(_projects);
    notifyListeners();
  }

  Future<void> checkoutAndPull({
    required Project proj,
    required String branch,
    required void Function(String line, bool isErr) onLine,
  }) async {
    final co = await _git.checkout(
      repoPath: proj.localPath,
      branch: branch,
      onLine: onLine,
    );
    if (!co.ok) throw StateError('git checkout failed');
    final pl = await _git.pull(repoPath: proj.localPath, onLine: onLine);
    if (!pl.ok) {
      onLine('git pull failed (exit ${pl.exitCode}) — continuing.', true);
    }
    proj.lastBranch = branch;
    await _storage.save(_projects);
    notifyListeners();
  }

  Future<List<File>> listWorkflows(Project proj) async {
    final dir = Directory(p.join(proj.localPath, '.github', 'workflows'));
    if (!await dir.exists()) return [];
    final out = <File>[];
    await for (final e in dir.list(followLinks: false)) {
      if (e is File) {
        final ext = p.extension(e.path).toLowerCase();
        if (ext == '.yml' || ext == '.yaml') out.add(e);
      }
    }
    out.sort((a, b) => a.path.compareTo(b.path));
    return out;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'path_utils.dart';

class GitProcResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  GitProcResult(this.exitCode, this.stdout, this.stderr);
  bool get ok => exitCode == 0;
}

class GitService {
  Future<GitProcResult> _run(
    List<String> args, {
    String? cwd,
    void Function(String line, bool isErr)? onLine,
  }) async {
    final env = buildEnv(cwd ?? Directory.current.path);
    final proc = await Process.start(
      'git',
      args,
      workingDirectory: cwd,
      environment: env,
      runInShell: false,
      includeParentEnvironment: false,
    );
    final outBuf = StringBuffer();
    final errBuf = StringBuffer();

    final outSub = proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((l) {
      outBuf.writeln(l);
      onLine?.call(l, false);
    });
    final errSub = proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((l) {
      errBuf.writeln(l);
      onLine?.call(l, true);
    });

    final code = await proc.exitCode;
    await outSub.cancel();
    await errSub.cancel();
    return GitProcResult(code, outBuf.toString(), errBuf.toString());
  }

  Future<GitProcResult> clone({
    required String url,
    required String targetDir,
    void Function(String line, bool isErr)? onLine,
  }) async {
    final parent = Directory(targetDir).parent;
    if (!await parent.exists()) await parent.create(recursive: true);
    return _run(
      ['clone', '--progress', url, targetDir],
      cwd: parent.path,
      onLine: onLine,
    );
  }

  Future<String?> currentBranch(String repoPath) async {
    final r = await _run(['rev-parse', '--abbrev-ref', 'HEAD'], cwd: repoPath);
    if (!r.ok) return null;
    return r.stdout.trim();
  }

  Future<List<String>> remoteBranches(String repoPath) async {
    final r = await _run(['branch', '-r'], cwd: repoPath);
    if (!r.ok) return [];
    final lines = r.stdout.split('\n');
    final out = <String>[];
    for (final raw in lines) {
      final l = raw.trim();
      if (l.isEmpty) continue;
      if (l.contains('->')) continue;
      final stripped = l.startsWith('origin/') ? l.substring('origin/'.length) : l;
      if (stripped.isEmpty) continue;
      out.add(stripped);
    }
    return out.toSet().toList()..sort();
  }

  Future<List<String>> localBranches(String repoPath) async {
    final r = await _run(['branch', '--format=%(refname:short)'], cwd: repoPath);
    if (!r.ok) return [];
    return r.stdout
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<GitProcResult> checkout({
    required String repoPath,
    required String branch,
    void Function(String line, bool isErr)? onLine,
  }) async {
    // If the branch is a remote-only ref, create a local tracking branch.
    final locals = await localBranches(repoPath);
    if (locals.contains(branch)) {
      return _run(['checkout', branch], cwd: repoPath, onLine: onLine);
    }
    return _run(
      ['checkout', '-B', branch, 'origin/$branch'],
      cwd: repoPath,
      onLine: onLine,
    );
  }

  Future<GitProcResult> pull({
    required String repoPath,
    void Function(String line, bool isErr)? onLine,
  }) {
    return _run(['pull', '--ff-only'], cwd: repoPath, onLine: onLine);
  }

  String repoNameFromUrl(String url) {
    var s = url.trim();
    if (s.endsWith('.git')) s = s.substring(0, s.length - 4);
    final slash = s.lastIndexOf('/');
    final colon = s.lastIndexOf(':');
    final cut = slash > colon ? slash : colon;
    if (cut >= 0 && cut < s.length - 1) s = s.substring(cut + 1);
    return s.isEmpty ? 'repo' : s;
  }
}

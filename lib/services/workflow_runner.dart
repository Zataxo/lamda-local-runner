import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

import '../models/run_state.dart';
import 'path_utils.dart';

typedef RunListener = void Function(RunState state);

class WorkflowRunner {
  final String repoPath;
  final String branch;
  final String artifactsPath;
  final RunState state;
  final RunListener onUpdate;

  Process? _current;
  bool _cancelled = false;

  WorkflowRunner({
    required this.repoPath,
    required this.branch,
    required String workflowName,
    required this.onUpdate,
    String? artifactsPath,
  })  : artifactsPath =
            artifactsPath ?? AppPaths.artifactsPathFor(repoPath),
        state = RunState(workflowName: workflowName);

  void cancel() {
    _cancelled = true;
    _current?.kill(ProcessSignal.sigterm);
  }

  Future<void> run(String yamlSource) async {
    state.status = StepStatus.running;
    state.startedAt = DateTime.now();
    _notify();

    dynamic parsed;
    try {
      parsed = loadYaml(yamlSource);
    } catch (e) {
      _globalLog('YAML parse error: $e', isError: true);
      state.status = StepStatus.failed;
      state.finishedAt = DateTime.now();
      _notify();
      return;
    }

    if (parsed is! YamlMap) {
      _globalLog('Workflow root must be a mapping.', isError: true);
      state.status = StepStatus.failed;
      state.finishedAt = DateTime.now();
      _notify();
      return;
    }

    // Ensure artifacts dir.
    final artifacts = Directory(artifactsPath);
    if (!await artifacts.exists()) await artifacts.create(recursive: true);
    _globalLog('Artifacts dir: $artifactsPath');

    final jobs = parsed['jobs'];
    if (jobs is! YamlMap) {
      _globalLog('No `jobs` section found.', isError: true);
      state.status = StepStatus.failed;
      state.finishedAt = DateTime.now();
      _notify();
      return;
    }

    var anyFailure = false;

    for (final entry in jobs.entries) {
      if (_cancelled) break;
      final jobKey = entry.key.toString();
      final jobDef = entry.value;
      final jobName = (jobDef is YamlMap && jobDef['name'] != null)
          ? jobDef['name'].toString()
          : jobKey;

      final job = JobState(name: jobName);
      state.jobs.add(job);
      job.status = StepStatus.running;
      _notify();

      if (jobDef is! YamlMap) {
        _jobLog(job, 'Job `$jobKey` is not a mapping — skipped.',
            isError: true);
        job.status = StepStatus.failed;
        anyFailure = true;
        _notify();
        continue;
      }

      if (jobDef['needs'] != null) {
        _jobLog(job, 'Note: `needs` is not supported in this MVP — ignored.');
      }
      if (jobDef['strategy'] != null &&
          (jobDef['strategy'] as YamlMap)['matrix'] != null) {
        _jobLog(job,
            'Note: `strategy.matrix` is not supported in this MVP — running once.');
      }

      final jobEnv = _readEnv(jobDef['env']);
      final steps = jobDef['steps'];
      if (steps is! YamlList) {
        _jobLog(job, 'Job has no `steps` list — skipped.', isError: true);
        job.status = StepStatus.failed;
        anyFailure = true;
        _notify();
        continue;
      }

      var jobFailed = false;
      for (var i = 0; i < steps.length; i++) {
        if (_cancelled) break;
        final rawStep = steps[i];
        if (rawStep is! YamlMap) {
          continue;
        }
        final stepName = (rawStep['name'] ?? rawStep['uses'] ?? rawStep['run'] ?? 'step ${i + 1}')
            .toString()
            .split('\n')
            .first;
        final step = StepState(name: stepName);
        job.steps.add(step);
        step.status = StepStatus.running;
        _notify();

        final continueOnError =
            (rawStep['continue-on-error'] == true || rawStep['continue-on-error'] == 'true');
        final stepEnv = {...jobEnv, ..._readEnv(rawStep['env'])};

        try {
          final ok = await _runStep(rawStep, step, stepEnv);
          if (!ok) {
            step.status = StepStatus.failed;
            _notify();
            if (!continueOnError) {
              jobFailed = true;
              break;
            }
          } else {
            if (step.status == StepStatus.running) {
              step.status = StepStatus.success;
              _notify();
            }
          }
        } catch (e) {
          _stepLog(step, 'Error: $e', isError: true);
          step.status = StepStatus.failed;
          if (!continueOnError) {
            jobFailed = true;
            _notify();
            break;
          }
          _notify();
        }
      }

      job.status = jobFailed ? StepStatus.failed : StepStatus.success;
      if (jobFailed) anyFailure = true;
      _notify();
    }

    state.status = _cancelled
        ? StepStatus.failed
        : (anyFailure ? StepStatus.failed : StepStatus.success);
    state.finishedAt = DateTime.now();
    _notify();
  }

  Future<bool> _runStep(
      YamlMap raw, StepState step, Map<String, String> env) async {
    final uses = raw['uses']?.toString();
    final run = raw['run']?.toString();
    final workingDirectory = raw['working-directory']?.toString();
    final withMap = raw['with'];

    final workspace = repoPath;
    final substitutions = <String, String>{
      'github.ref_name': branch,
      'github.workspace': workspace,
      'github.repository': p.basename(workspace),
    };

    String subst(String s) => _expand(s, substitutions,
        onUnknown: (expr) => _stepLog(step,
            'Warning: unsupported expression \${{ $expr }} — left as-is.'));

    if (uses != null && uses.trim().isNotEmpty) {
      return _handleUses(subst(uses.trim()), withMap, step, workspace);
    }

    if (run == null || run.trim().isEmpty) {
      _stepLog(step, 'Step has no `run` or `uses` — skipped.');
      step.status = StepStatus.skipped;
      return true;
    }

    final script = subst(run);
    final cwd = workingDirectory == null
        ? workspace
        : p.isAbsolute(workingDirectory)
            ? workingDirectory
            : p.normalize(p.join(workspace, subst(workingDirectory)));

    final fullEnv = buildEnv(workspace, extra: env);
    return _executeShell(script, cwd: cwd, env: fullEnv, step: step);
  }

  Future<bool> _handleUses(
      String uses, dynamic withMap, StepState step, String workspace) async {
    final lower = uses.toLowerCase();

    if (lower.startsWith('actions/checkout')) {
      _stepLog(step,
          'actions/checkout — no-op (repo already cloned at $workspace).');
      step.status = StepStatus.success;
      return true;
    }

    if (lower.contains('flutter-action') || lower.contains('setup-flutter')) {
      _stepLog(step, 'Detected flutter setup action — verifying local Flutter.');
      final ok = await _executeShell('flutter --version',
          cwd: workspace, env: buildEnv(workspace), step: step);
      return ok;
    }

    if (lower.startsWith('actions/upload-artifact')) {
      final pathVal = (withMap is YamlMap) ? withMap['path']?.toString() : null;
      if (pathVal == null || pathVal.trim().isEmpty) {
        _stepLog(step, 'upload-artifact: no `path` given — nothing to copy.',
            isError: true);
        step.status = StepStatus.failed;
        return false;
      }
      final artifactsDir = Directory(artifactsPath);
      if (!await artifactsDir.exists()) {
        await artifactsDir.create(recursive: true);
      }
      final patterns = pathVal
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      var copied = 0;
      for (final pat in patterns) {
        final full = p.isAbsolute(pat) ? pat : p.join(workspace, pat);
        try {
          if (await FileSystemEntity.isFile(full)) {
            await _copyInto(File(full), workspace, artifactsDir);
            copied++;
            continue;
          }
          if (await FileSystemEntity.isDirectory(full)) {
            await for (final e
                in Directory(full).list(recursive: true, followLinks: false)) {
              if (e is File) {
                await _copyInto(e, workspace, artifactsDir);
                copied++;
              }
            }
            continue;
          }
          final g = Glob(pat, recursive: true);
          await for (final e in g.list(root: workspace, followLinks: false)) {
            if (e is File) {
              await _copyInto(e as File, workspace, artifactsDir);
              copied++;
            }
          }
        } catch (e) {
          _stepLog(step, 'upload-artifact: error on `$pat`: $e', isError: true);
        }
      }
      _stepLog(step, 'upload-artifact: copied $copied file(s) into _artifacts/.');
      step.status = StepStatus.success;
      return true;
    }

    _stepLog(step, 'Unsupported action, skipped: $uses');
    step.status = StepStatus.skipped;
    return true;
  }

  Future<void> _copyInto(File src, String workspace, Directory dest) async {
    final rel = p.relative(src.path, from: workspace);
    final target = File(p.join(dest.path, rel));
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }
    await src.copy(target.path);
  }

  Future<bool> _executeShell(
    String script, {
    required String cwd,
    required Map<String, String> env,
    required StepState step,
  }) async {
    _stepLog(step, '\$ ${script.trim()}');
    final proc = await Process.start(
      'zsh',
      ['-lc', script],
      workingDirectory: cwd,
      environment: env,
      runInShell: false,
      includeParentEnvironment: false,
    );
    _current = proc;

    final outSub = proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((l) => _stepLog(step, l));
    final errSub = proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((l) => _stepLog(step, l, isError: true));

    final code = await proc.exitCode;
    await outSub.cancel();
    await errSub.cancel();
    _current = null;

    if (code != 0) {
      _stepLog(step, 'Exit code: $code', isError: true);
      return false;
    }
    return true;
  }

  Map<String, String> _readEnv(dynamic node) {
    if (node is! YamlMap) return {};
    final out = <String, String>{};
    node.forEach((k, v) {
      out[k.toString()] = v?.toString() ?? '';
    });
    return out;
  }

  static final RegExp _exprRe = RegExp(r'\$\{\{\s*([^}]+?)\s*\}\}');
  String _expand(String s, Map<String, String> vars,
      {void Function(String)? onUnknown}) {
    return s.replaceAllMapped(_exprRe, (m) {
      final expr = m.group(1)!.trim();
      if (vars.containsKey(expr)) return vars[expr]!;
      onUnknown?.call(expr);
      return m.group(0)!;
    });
  }

  void _notify() => onUpdate(state);

  void _globalLog(String text, {bool isError = false}) {
    state.globalLogs.add(LogLine(text, isError: isError));
    _notify();
  }

  void _jobLog(JobState job, String text, {bool isError = false}) {
    // Attach job-level notes to a pseudo step for visibility.
    if (job.steps.isEmpty || job.steps.first.name != '(job)') {
      job.steps.insert(0, StepState(name: '(job)', status: StepStatus.running));
    }
    job.steps.first.logs.add(LogLine(text, isError: isError));
    _notify();
  }

  void _stepLog(StepState step, String text, {bool isError = false}) {
    step.logs.add(LogLine(text, isError: isError));
    _notify();
  }
}

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../models/run_state.dart';
import 'run_provider.dart';

class RunSession {
  final String id;
  final Project project;
  final String branch;
  final String workflowName;
  final String yamlSource;
  final String artifactsPath;
  final Map<String, String> secrets;
  final RunProvider provider;

  RunSession({
    required this.id,
    required this.project,
    required this.branch,
    required this.workflowName,
    required this.yamlSource,
    required this.artifactsPath,
    required this.secrets,
    required this.provider,
  });

  bool get isRunning => provider.isRunning;
  StepStatus get status =>
      provider.state?.status ?? StepStatus.pending;
}

class ActiveRunsController extends ChangeNotifier {
  final Map<String, RunSession> _sessions = {};

  List<RunSession> get sessions => _sessions.values.toList();
  RunSession? get(String id) => _sessions[id];
  List<RunSession> forProject(String projectId) =>
      _sessions.values.where((s) => s.project.id == projectId).toList();
  int get runningCount => _sessions.values
      .where((s) => s.provider.isRunning)
      .length;

  Future<RunSession> start({
    required Project project,
    required String branch,
    required String workflowName,
    required String yamlSource,
    required String artifactsPath,
    Map<String, String> secrets = const {},
  }) async {
    final id = const Uuid().v4();
    final provider = RunProvider();
    final session = RunSession(
      id: id,
      project: project,
      branch: branch,
      workflowName: workflowName,
      yamlSource: yamlSource,
      artifactsPath: artifactsPath,
      secrets: secrets,
      provider: provider,
    );
    _sessions[id] = session;
    provider.addListener(_onChange);
    notifyListeners();
    // Fire-and-forget: the provider streams updates via listeners.
    // We do NOT await — the dialog is not required to observe completion.
    // ignore: unawaited_futures
    provider.start(
      projectId: project.id,
      repoPath: project.localPath,
      branch: branch,
      workflowName: workflowName,
      yamlSource: yamlSource,
      artifactsPath: artifactsPath,
      secrets: secrets,
    );
    return session;
  }

  Future<void> stop(String id) async {
    await _sessions[id]?.provider.cancel();
  }

  void remove(String id) {
    final s = _sessions.remove(id);
    if (s == null) return;
    s.provider.removeListener(_onChange);
    s.provider.dispose();
    notifyListeners();
  }

  void _onChange() => notifyListeners();

  @override
  void dispose() {
    for (final s in _sessions.values) {
      s.provider.removeListener(_onChange);
      s.provider.dispose();
    }
    _sessions.clear();
    super.dispose();
  }
}

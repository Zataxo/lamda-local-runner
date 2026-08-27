import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/run_record.dart';
import '../models/run_state.dart';
import '../services/git_service.dart';
import '../services/run_history_service.dart';
import '../services/workflow_runner.dart';

class RunProvider extends ChangeNotifier {
  final _history = RunHistoryService();
  final _git = GitService();

  RunState? _state;
  WorkflowRunner? _runner;
  RunRecord? _record;

  RunState? get state => _state;
  RunRecord? get record => _record;
  bool get isRunning => _state?.status == StepStatus.running;

  Future<void> start({
    required String projectId,
    required String repoPath,
    required String branch,
    required String workflowName,
    required String yamlSource,
    String? artifactsPath,
    Map<String, String> secrets = const {},
  }) async {
    final id = const Uuid().v4();
    final sha = (await _git.lastCommit(repoPath, ref: branch))?.shortHash;

    _runner = WorkflowRunner(
      repoPath: repoPath,
      branch: branch,
      workflowName: workflowName,
      artifactsPath: artifactsPath,
      secrets: secrets,
      onUpdate: (s) {
        _state = s;
        notifyListeners();
      },
    );
    _state = _runner!.state;
    notifyListeners();

    await _runner!.run(yamlSource);

    final runState = _runner!.state;
    _record = RunRecord(
      id: id,
      projectId: projectId,
      workflowName: workflowName,
      yamlSource: yamlSource,
      branch: branch,
      sha: sha,
      startedAt: runState.startedAt ?? DateTime.now(),
      finishedAt: runState.finishedAt,
      status: runState.status,
      run: runState,
    );
    try {
      await _history.save(_record!);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> cancel() async {
    await _runner?.cancel();
  }

  void clear() {
    _state = null;
    _runner = null;
    _record = null;
    notifyListeners();
  }
}

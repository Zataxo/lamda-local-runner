import 'package:flutter/foundation.dart';

import '../models/run_state.dart';
import '../services/workflow_runner.dart';

class RunProvider extends ChangeNotifier {
  RunState? _state;
  WorkflowRunner? _runner;

  RunState? get state => _state;
  bool get isRunning => _state?.status == StepStatus.running;

  Future<void> start({
    required String repoPath,
    required String branch,
    required String workflowName,
    required String yamlSource,
    String? artifactsPath,
  }) async {
    _runner = WorkflowRunner(
      repoPath: repoPath,
      branch: branch,
      workflowName: workflowName,
      artifactsPath: artifactsPath,
      onUpdate: (s) {
        _state = s;
        notifyListeners();
      },
    );
    _state = _runner!.state;
    notifyListeners();
    await _runner!.run(yamlSource);
  }

  void cancel() {
    _runner?.cancel();
  }

  void clear() {
    _state = null;
    _runner = null;
    notifyListeners();
  }
}

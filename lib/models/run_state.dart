enum StepStatus { pending, running, success, failed, skipped }

class LogLine {
  final String text;
  final bool isError;
  final DateTime at;
  LogLine(this.text, {this.isError = false}) : at = DateTime.now();
}

class StepState {
  final String name;
  StepStatus status;
  final List<LogLine> logs;

  StepState({required this.name, this.status = StepStatus.pending})
      : logs = [];
}

class JobState {
  final String name;
  StepStatus status;
  final List<StepState> steps;

  JobState({required this.name, this.status = StepStatus.pending})
      : steps = [];
}

class RunState {
  final String workflowName;
  StepStatus status;
  final List<JobState> jobs;
  final List<LogLine> globalLogs;
  DateTime? startedAt;
  DateTime? finishedAt;

  RunState({required this.workflowName, this.status = StepStatus.pending})
      : jobs = [],
        globalLogs = [];
}

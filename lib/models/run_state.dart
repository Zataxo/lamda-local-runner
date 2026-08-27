enum StepStatus { pending, running, success, failed, skipped, cancelled }

String stepStatusName(StepStatus s) => s.name;
StepStatus stepStatusFromName(String? s) {
  for (final v in StepStatus.values) {
    if (v.name == s) return v;
  }
  return StepStatus.pending;
}

class LogLine {
  final String text;
  final bool isError;
  final DateTime at;
  LogLine(this.text, {this.isError = false}) : at = DateTime.now();
  LogLine.raw(this.text, this.isError, this.at);

  Map<String, dynamic> toJson() => {
        't': text,
        'e': isError,
        'at': at.toIso8601String(),
      };

  factory LogLine.fromJson(Map<String, dynamic> j) => LogLine.raw(
        (j['t'] ?? '').toString(),
        j['e'] == true,
        DateTime.tryParse((j['at'] ?? '').toString()) ?? DateTime.now(),
      );
}

class StepState {
  final String name;
  StepStatus status;
  final List<LogLine> logs;

  StepState({required this.name, this.status = StepStatus.pending})
      : logs = [];

  StepState._withLogs(this.name, this.status, this.logs);

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': stepStatusName(status),
        'logs': logs.map((l) => l.toJson()).toList(),
      };

  factory StepState.fromJson(Map<String, dynamic> j) => StepState._withLogs(
        (j['name'] ?? '').toString(),
        stepStatusFromName(j['status']?.toString()),
        ((j['logs'] as List?) ?? [])
            .map((e) => LogLine.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class JobState {
  final String name;
  StepStatus status;
  final List<StepState> steps;

  JobState({required this.name, this.status = StepStatus.pending})
      : steps = [];

  JobState._withSteps(this.name, this.status, this.steps);

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': stepStatusName(status),
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory JobState.fromJson(Map<String, dynamic> j) => JobState._withSteps(
        (j['name'] ?? '').toString(),
        stepStatusFromName(j['status']?.toString()),
        ((j['steps'] as List?) ?? [])
            .map((e) => StepState.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
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

  RunState._raw(this.workflowName, this.status, this.jobs, this.globalLogs,
      this.startedAt, this.finishedAt);

  Map<String, dynamic> toJson() => {
        'workflowName': workflowName,
        'status': stepStatusName(status),
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'jobs': jobs.map((j) => j.toJson()).toList(),
        'globalLogs': globalLogs.map((l) => l.toJson()).toList(),
      };

  factory RunState.fromJson(Map<String, dynamic> j) => RunState._raw(
        (j['workflowName'] ?? '').toString(),
        stepStatusFromName(j['status']?.toString()),
        ((j['jobs'] as List?) ?? [])
            .map((e) => JobState.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        ((j['globalLogs'] as List?) ?? [])
            .map((e) => LogLine.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        j['startedAt'] == null
            ? null
            : DateTime.tryParse(j['startedAt'].toString()),
        j['finishedAt'] == null
            ? null
            : DateTime.tryParse(j['finishedAt'].toString()),
      );
}

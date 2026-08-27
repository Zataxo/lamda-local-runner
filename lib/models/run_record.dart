import 'run_state.dart';

class RunRecord {
  final String id;
  final String projectId;
  final String workflowName;
  final String yamlSource;
  final String branch;
  final String? sha;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final StepStatus status;
  final RunState run;

  RunRecord({
    required this.id,
    required this.projectId,
    required this.workflowName,
    required this.yamlSource,
    required this.branch,
    required this.sha,
    required this.startedAt,
    required this.finishedAt,
    required this.status,
    required this.run,
  });

  Duration? get duration =>
      finishedAt != null ? finishedAt!.difference(startedAt) : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'workflowName': workflowName,
        'yamlSource': yamlSource,
        'branch': branch,
        'sha': sha,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'status': stepStatusName(status),
        'run': run.toJson(),
      };

  factory RunRecord.fromJson(Map<String, dynamic> j) => RunRecord(
        id: j['id'].toString(),
        projectId: j['projectId'].toString(),
        workflowName: j['workflowName'].toString(),
        yamlSource: j['yamlSource'].toString(),
        branch: j['branch'].toString(),
        sha: j['sha']?.toString(),
        startedAt: DateTime.parse(j['startedAt'].toString()),
        finishedAt: j['finishedAt'] == null
            ? null
            : DateTime.tryParse(j['finishedAt'].toString()),
        status: stepStatusFromName(j['status']?.toString()),
        run: RunState.fromJson((j['run'] as Map).cast<String, dynamic>()),
      );
}

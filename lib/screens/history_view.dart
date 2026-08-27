import 'package:flutter/material.dart' hide StepState;

import '../models/run_record.dart';
import '../models/run_state.dart';
import '../services/repo_meta.dart';
import '../services/run_history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/log_panel.dart';
import '../widgets/status_badge.dart';

class HistoryView extends StatefulWidget {
  final String projectId;
  final void Function(RunRecord) onRerun;
  const HistoryView({
    super.key,
    required this.projectId,
    required this.onRerun,
  });

  @override
  State<HistoryView> createState() => HistoryViewState();
}

class HistoryViewState extends State<HistoryView> {
  final _svc = RunHistoryService();
  List<RunRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didUpdateWidget(covariant HistoryView old) {
    super.didUpdateWidget(old);
    if (old.projectId != widget.projectId) refresh();
  }

  Future<void> refresh() async {
    setState(() => _loading = true);
    final list = await _svc.list(widget.projectId);
    if (!mounted) return;
    setState(() {
      _records = list;
      _loading = false;
    });
  }

  void _open(RunRecord r) {
    showDialog(
      context: context,
      builder: (_) => HistoryRunDialog(
          record: r, onRerun: () => widget.onRerun(r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: _loading
          ? Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(t.accent)),
              ),
            )
          : _records.isEmpty
              ? const EmptyState(
                  icon: Icons.history,
                  title: 'No runs yet',
                  body:
                      'Every run you start here will show up in this list.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _records.length,
                  itemBuilder: (_, i) => _HistoryRow(
                    record: _records[i],
                    onOpen: () => _open(_records[i]),
                    onRerun: () => widget.onRerun(_records[i]),
                  ),
                ),
    );
  }
}

class _HistoryRow extends StatefulWidget {
  final RunRecord record;
  final VoidCallback onOpen;
  final VoidCallback onRerun;
  const _HistoryRow(
      {required this.record,
      required this.onOpen,
      required this.onRerun});
  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final r = widget.record;
    final dur = r.duration;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: _hover ? t.surfaceMuted : Colors.transparent,
            border: Border(bottom: BorderSide(color: t.divider)),
          ),
          child: Row(
            children: [
              StatusDot(r.status, size: 8),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.workflowName,
                        overflow: TextOverflow.ellipsis,
                        style: type.body.copyWith(
                            fontWeight: FontWeight.w500, fontSize: 12.5)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.alt_route,
                            size: 10, color: t.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(r.branch,
                              overflow: TextOverflow.ellipsis,
                              style: type.caption.copyWith(
                                  color: t.textMuted, fontSize: 11)),
                        ),
                        if (r.sha != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.commit, size: 10, color: t.textMuted),
                          const SizedBox(width: 3),
                          Text(r.sha!,
                              style: type.monoSm.copyWith(
                                  color: t.textMuted, fontSize: 11)),
                        ],
                        const SizedBox(width: 8),
                        Icon(Icons.schedule, size: 10, color: t.textMuted),
                        const SizedBox(width: 3),
                        Text(timeAgo(r.startedAt),
                            style: type.caption.copyWith(
                                color: t.textMuted, fontSize: 11)),
                        if (dur != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.timer_outlined,
                              size: 10, color: t.textMuted),
                          const SizedBox(width: 3),
                          Text(_fmtDur(dur),
                              style: type.caption.copyWith(
                                  color: t.textMuted, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(r.status, compact: true),
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: 'Re-run this workflow',
                child: AppButton.secondary(
                  icon: Icons.replay,
                  label: 'Re-run',
                  size: AppButtonSize.sm,
                  onPressed: widget.onRerun,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDur(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

class HistoryRunDialog extends StatefulWidget {
  final RunRecord record;
  final VoidCallback onRerun;
  const HistoryRunDialog(
      {super.key, required this.record, required this.onRerun});

  @override
  State<HistoryRunDialog> createState() => _HistoryRunDialogState();
}

class _HistoryRunDialogState extends State<HistoryRunDialog> {
  StepState? _selected;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final r = widget.record;
    final selected = _pickSelected(r.run);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rLg,
        side: BorderSide(color: t.border),
      ),
      child: SizedBox(
        width: 1180,
        height: 760,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColors(context, r.status).bg,
                      borderRadius: AppRadius.rMd,
                    ),
                    child: StatusDot(r.status, size: 8),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.workflowName, style: type.section),
                        const SizedBox(height: 2),
                        Text(
                          '${r.branch} · ${timeAgo(r.startedAt)}${r.sha != null ? " · ${r.sha}" : ""}',
                          style: type.caption.copyWith(color: t.textMuted),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(r.status),
                  const SizedBox(width: AppSpacing.md),
                  AppButton.primary(
                    icon: Icons.replay,
                    label: 'Re-run',
                    size: AppButtonSize.sm,
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onRerun();
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.ghost(
                    icon: Icons.close,
                    label: 'Close',
                    size: AppButtonSize.sm,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: t.divider, height: 1),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                      width: 360, child: _stepList(context, r.run)),
                  VerticalDivider(color: t.divider, width: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: LogPanel(
                        lines:
                            selected?.logs ?? r.run.globalLogs,
                        title:
                            (selected?.name ?? 'RUN LOG').toUpperCase(),
                        icon: Icons.terminal,
                        subtitle: selected != null
                            ? statusLabel(selected.status)
                                .toLowerCase()
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  StepState? _pickSelected(RunState s) {
    if (_selected != null) {
      for (final j in s.jobs) {
        if (j.steps.contains(_selected)) return _selected;
      }
    }
    if (s.jobs.isNotEmpty && s.jobs.last.steps.isNotEmpty) {
      return s.jobs.last.steps.last;
    }
    return null;
  }

  Widget _stepList(BuildContext context, RunState s) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      color: t.background,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          for (final job in s.jobs) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
              child: Row(
                children: [
                  StatusDot(job.status, size: 7),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(job.name,
                          overflow: TextOverflow.ellipsis,
                          style: type.overline)),
                  StatusBadge(job.status, compact: true),
                ],
              ),
            ),
            for (final step in job.steps)
              InkWell(
                onTap: () => setState(() => _selected = step),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 1),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 7),
                  decoration: BoxDecoration(
                    color: _selected == step
                        ? t.accentSubtle
                        : Colors.transparent,
                    borderRadius: AppRadius.rSm,
                  ),
                  child: Row(
                    children: [
                      StatusDot(step.status, size: 7),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(step.name,
                            overflow: TextOverflow.ellipsis,
                            style: type.body.copyWith(fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

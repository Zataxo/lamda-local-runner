import 'dart:io';

import 'package:flutter/material.dart' hide StepState;
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/run_state.dart';
import '../state/run_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/log_panel.dart';
import '../widgets/status_badge.dart';

class RunScreen extends StatefulWidget {
  final Project project;
  final String branch;
  final String workflowName;
  final String yamlSource;
  final String artifactsPath;
  const RunScreen({
    super.key,
    required this.project,
    required this.branch,
    required this.workflowName,
    required this.yamlSource,
    required this.artifactsPath,
  });

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  RunProvider? _run;
  StepState? _selectedStep;

  @override
  void initState() {
    super.initState();
    _run = RunProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _run!.start(
        repoPath: widget.project.localPath,
        branch: widget.branch,
        workflowName: widget.workflowName,
        yamlSource: widget.yamlSource,
        artifactsPath: widget.artifactsPath,
      );
    });
  }

  @override
  void dispose() {
    _run?.cancel();
    _run?.dispose();
    super.dispose();
  }

  Future<void> _revealArtifacts() async {
    final path = widget.artifactsPath;
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
    await Process.start('open', [path], runInShell: false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rLg,
        side: BorderSide(color: t.border),
      ),
      backgroundColor: t.surface,
      child: ChangeNotifierProvider.value(
        value: _run!,
        child: Consumer<RunProvider>(
          builder: (_, run, __) {
            final state = run.state;
            final selected = _pickSelectedStep(state);
            return SizedBox(
              width: 1180,
              height: 760,
              child: Column(
                children: [
                  _header(state, run.isRunning),
                  Divider(color: t.divider, height: 1),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 360,
                          child: _stepList(state),
                        ),
                        VerticalDivider(color: t.divider, width: 1),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: LogPanel(
                              lines: selected?.logs ??
                                  state?.globalLogs ??
                                  const [],
                              title: (selected?.name ?? 'RUN LOG').toUpperCase(),
                              icon: Icons.terminal,
                              subtitle: selected != null
                                  ? statusLabel(selected.status).toLowerCase()
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  StepState? _pickSelectedStep(RunState? s) {
    if (s == null) return null;
    if (_selectedStep != null) {
      for (final j in s.jobs) {
        if (j.steps.contains(_selectedStep)) return _selectedStep;
      }
    }
    for (final j in s.jobs) {
      for (final st in j.steps) {
        if (st.status == StepStatus.running) return st;
      }
    }
    if (s.jobs.isNotEmpty && s.jobs.last.steps.isNotEmpty) {
      return s.jobs.last.steps.last;
    }
    return null;
  }

  Widget _header(RunState? state, bool running) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final status = state?.status ?? StepStatus.pending;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColors(context, status).bg,
              borderRadius: AppRadius.rMd,
            ),
            child: StatusDot(status, size: 8),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.workflowName, style: type.section),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 11, color: t.textMuted),
                    const SizedBox(width: 3),
                    Text(widget.project.name,
                        style: type.caption
                            .copyWith(color: t.textMuted, fontSize: 11.5)),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.alt_route, size: 11, color: t.textMuted),
                    const SizedBox(width: 3),
                    Text(widget.branch,
                        style: type.caption
                            .copyWith(color: t.textMuted, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          StatusBadge(status),
          const SizedBox(width: AppSpacing.md),
          AppButton.secondary(
            icon: Icons.folder_open_outlined,
            label: 'Artifacts',
            size: AppButtonSize.sm,
            onPressed: _revealArtifacts,
          ),
          const SizedBox(width: AppSpacing.sm),
          if (running)
            AppButton.secondary(
              icon: Icons.stop_circle_outlined,
              label: 'Cancel',
              size: AppButtonSize.sm,
              onPressed: () => _run?.cancel(),
            ),
          const SizedBox(width: AppSpacing.sm),
          AppButton.ghost(
            icon: Icons.close,
            label: 'Close',
            size: AppButtonSize.sm,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _stepList(RunState? state) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    if (state == null || state.jobs.isEmpty) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(t.accent)),
        ),
      );
    }
    return Container(
      color: t.background,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          for (final job in state.jobs) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                  AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
              child: Row(
                children: [
                  StatusDot(job.status, size: 7),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(job.name,
                        overflow: TextOverflow.ellipsis,
                        style: type.overline),
                  ),
                  StatusBadge(job.status, compact: true),
                ],
              ),
            ),
            for (final step in job.steps)
              _StepRow(
                step: step,
                selected: _selectedStep == step,
                onTap: () => setState(() => _selectedStep = step),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatefulWidget {
  final StepState step;
  final bool selected;
  final VoidCallback onTap;
  const _StepRow(
      {required this.step, required this.selected, required this.onTap});

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    Color bg;
    if (widget.selected) {
      bg = t.accentSubtle;
    } else if (_hover) {
      bg = t.surfaceMuted;
    } else {
      bg = Colors.transparent;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 1),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.rSm,
          ),
          child: Row(
            children: [
              StatusDot(widget.step.status, size: 7),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.step.name,
                  overflow: TextOverflow.ellipsis,
                  style: type.body.copyWith(
                    fontSize: 12.5,
                    color: widget.selected ? t.textPrimary : t.textSecondary,
                    fontWeight: widget.selected
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

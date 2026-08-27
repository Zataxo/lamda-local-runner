import 'dart:io';

import 'package:flutter/material.dart' hide StepState;
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/run_record.dart';
import '../models/run_state.dart';
import '../services/repo_meta.dart';
import '../services/run_history_service.dart';
import '../state/projects_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onCreate;
  final VoidCallback onOpenSecrets;
  final void Function(Project) onOpenProject;
  final void Function(Project) onQuickRun;

  const DashboardScreen({
    super.key,
    required this.onCreate,
    required this.onOpenSecrets,
    required this.onOpenProject,
    required this.onQuickRun,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _history = RunHistoryService();
  Map<String, RunRecord?> _last = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final projects = context.read<ProjectsProvider>().projects;
    final out = <String, RunRecord?>{};
    for (final p in projects) {
      final list = await _history.list(p.id);
      out[p.id] = list.isEmpty ? null : list.first;
    }
    if (!mounted) return;
    setState(() {
      _last = out;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final projects = context.watch<ProjectsProvider>().projects;

    final total = projects.length;
    var running = 0;
    var failed = 0;
    var success = 0;
    var neverRun = 0;
    for (final p in projects) {
      final r = _last[p.id];
      if (r == null) {
        neverRun++;
        continue;
      }
      switch (r.status) {
        case StepStatus.running:
          running++;
          break;
        case StepStatus.failed:
        case StepStatus.cancelled:
          failed++;
          break;
        case StepStatus.success:
          success++;
          break;
        case StepStatus.pending:
        case StepStatus.skipped:
          break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: type.display),
                    const SizedBox(height: 2),
                    Text(
                      'Overview of your projects and their last runs.',
                      style: type.caption.copyWith(color: t.textSecondary),
                    ),
                  ],
                ),
              ),
              AppButton.secondary(
                icon: Icons.lock_outline,
                label: 'Manage secrets',
                size: AppButtonSize.sm,
                onPressed: widget.onOpenSecrets,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                icon: Icons.add,
                label: 'New Project',
                size: AppButtonSize.sm,
                onPressed: widget.onCreate,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _StatsRow(
            total: total,
            running: running,
            failed: failed,
            success: success,
            neverRun: neverRun,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const SectionLabel('PROJECTS'),
              const Spacer(),
              if (_loading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(t.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (projects.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadius.rLg,
                border: Border.all(color: t.border),
              ),
              child: EmptyState(
                icon: Icons.folder_outlined,
                title: 'No projects yet',
                body:
                    'Clone a Git repository or import a local folder to get started.',
                action: AppButton.primary(
                  icon: Icons.add,
                  label: 'Create project',
                  onPressed: widget.onCreate,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                const minCard = 320.0;
                const gap = AppSpacing.md;
                final cols = (c.maxWidth / (minCard + gap)).floor().clamp(1, 4);
                final cardWidth = (c.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final p in projects)
                      SizedBox(
                        width: cardWidth,
                        child: _ProjectCard(
                          project: p,
                          lastRun: _last[p.id],
                          onOpen: () => widget.onOpenProject(p),
                          onQuickRun: () => widget.onQuickRun(p),
                          onReveal: () => _revealInFinder(p.localPath),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _revealInFinder(String path) async {
    try {
      await Process.start('open', [path], runInShell: false);
    } catch (_) {}
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int running;
  final int failed;
  final int success;
  final int neverRun;
  const _StatsRow({
    required this.total,
    required this.running,
    required this.failed,
    required this.success,
    required this.neverRun,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'PROJECTS',
            value: '$total',
            icon: Icons.folder_outlined,
            accent: t.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'RUNNING',
            value: '$running',
            icon: Icons.play_circle_outline,
            accent: t.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'SUCCESS',
            value: '$success',
            icon: Icons.check_circle_outline,
            accent: t.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'FAILED',
            value: '$failed',
            icon: Icons.error_outline,
            accent: t.danger,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'NEVER RUN',
            value: '$neverRun',
            icon: Icons.hourglass_empty,
            accent: t.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.surfaceMuted,
              borderRadius: AppRadius.rSm,
              border: Border.all(color: t.border),
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: type.overline),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: type.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project project;
  final RunRecord? lastRun;
  final VoidCallback onOpen;
  final VoidCallback onQuickRun;
  final VoidCallback onReveal;
  const _ProjectCard({
    required this.project,
    required this.lastRun,
    required this.onOpen,
    required this.onQuickRun,
    required this.onReveal,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final r = widget.lastRun;
    final status = r?.status;
    final urlOrPath = widget.project.repoUrl ?? widget.project.localPath;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppRadius.rLg,
            border: Border.all(color: _hover ? t.borderStrong : t.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surfaceMuted,
                      borderRadius: AppRadius.rSm,
                      border: Border.all(color: t.border),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      size: 15,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.project.name,
                          overflow: TextOverflow.ellipsis,
                          style: type.section,
                        ),
                        const SizedBox(height: 2),
                        Tooltip(
                          message: urlOrPath,
                          child: Text(
                            urlOrPath,
                            overflow: TextOverflow.ellipsis,
                            style: type.caption.copyWith(
                              color: t.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _hover ? 1 : 0,
                    duration: AppDurations.fast,
                    child: Row(
                      children: [
                        Tooltip(
                          message: 'Reveal in Finder',
                          child: IconButton(
                            icon: Icon(
                              Icons.folder_open_outlined,
                              size: 15,
                              color: t.textSecondary,
                            ),
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            onPressed: widget.onReveal,
                          ),
                        ),
                        Tooltip(
                          message: 'Open project',
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_forward,
                              size: 15,
                              color: t.textSecondary,
                            ),
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            onPressed: widget.onOpen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(color: t.divider, height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: t.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.alt_route, size: 11, color: t.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          widget.project.lastBranch ?? '—',
                          style: type.caption.copyWith(
                            color: t.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (status == null) _NeverRunBadge() else StatusBadge(status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (r != null)
                Text(
                  _lastRunLine(r),
                  style: type.caption.copyWith(
                    color: t.textMuted,
                    fontSize: 11.5,
                  ),
                )
              else
                Text(
                  'Never run yet.',
                  style: type.caption.copyWith(
                    color: t.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      icon: Icons.arrow_forward,
                      label: 'Open',
                      size: AppButtonSize.sm,
                      onPressed: widget.onOpen,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.primary(
                      icon: Icons.play_arrow_rounded,
                      label: 'Quick run',
                      size: AppButtonSize.sm,
                      onPressed: widget.onQuickRun,
                      expand: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _lastRunLine(RunRecord r) {
    final rel = timeAgo(r.startedAt);
    final d = r.duration;
    if (d == null) return 'Last run $rel';
    final dur = _fmtDur(d);
    return 'Last run $rel · $dur';
  }

  String _fmtDur(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

class _NeverRunBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: t.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Never run',
            style: type.overline.copyWith(
              color: t.textMuted,
              fontSize: 10.5,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

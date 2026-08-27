import 'dart:io';

import 'package:code_text_field/code_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/run_state.dart';
import '../presets/workflow_presets.dart';
import '../services/git_service.dart';
import '../services/path_utils.dart';
import '../services/repo_meta.dart';
import '../state/projects_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/log_panel.dart';
import '../widgets/section_header.dart';
import 'run_screen.dart';

class ProjectScreen extends StatefulWidget {
  final Project project;
  const ProjectScreen({super.key, required this.project});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  CodeController? _code;
  List<String> _branches = [];
  String? _selectedBranch;
  List<File> _workflows = [];
  File? _selectedWorkflow;
  bool _loadingBranches = false;
  bool _switching = false;
  final _switchLogs = <LogLine>[];
  CommitInfo? _branchCommit;
  final _git = GitService();

  @override
  void initState() {
    super.initState();
    _code = CodeController(text: '', language: yaml);
    _code!.addListener(_onCodeChanged);
    _load();
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ProjectScreen old) {
    super.didUpdateWidget(old);
    if (old.project.id != widget.project.id) {
      _switchLogs.clear();
      _load();
    }
  }

  @override
  void dispose() {
    _code?.removeListener(_onCodeChanged);
    _code?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadingBranches = true);
    final proj = widget.project;
    final projects = context.read<ProjectsProvider>();
    final branches = await projects.listBranches(proj);
    final current = await projects.currentBranch(proj) ?? proj.lastBranch;
    final workflows = await projects.listWorkflows(proj);
    File? first = workflows.isNotEmpty ? workflows.first : null;
    String? content = '';
    if (first != null) {
      try {
        content = await first.readAsString();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _branches = branches;
      _selectedBranch = current != null && branches.contains(current)
          ? current
          : (branches.isNotEmpty ? branches.first : null);
      _workflows = workflows;
      _selectedWorkflow = first;
      _code!.text = content ?? '';
      _loadingBranches = false;
    });
    _refreshBranchCommit();
  }

  Future<void> _refreshBranchCommit() async {
    final b = _selectedBranch;
    if (b == null) {
      if (mounted) setState(() => _branchCommit = null);
      return;
    }
    final ci = await _git.lastCommit(widget.project.localPath, ref: b);
    if (!mounted) return;
    setState(() => _branchCommit = ci);
  }

  Future<void> _onBranchChanged(String? b) async {
    if (b == null || b == _selectedBranch) return;
    setState(() {
      _switching = true;
      _switchLogs.clear();
      _selectedBranch = b;
    });
    try {
      await context.read<ProjectsProvider>().checkoutAndPull(
            proj: widget.project,
            branch: b,
            onLine: (l, err) =>
                setState(() => _switchLogs.add(LogLine(l, isError: err))),
          );
      final projects = context.read<ProjectsProvider>();
      final workflows = await projects.listWorkflows(widget.project);
      File? first = workflows.isNotEmpty ? workflows.first : null;
      String? content = '';
      if (first != null) {
        try {
          content = await first.readAsString();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _workflows = workflows;
        _selectedWorkflow = first;
        _code!.text = content ?? '';
      });
      _refreshBranchCommit();
    } catch (e) {
      setState(() => _switchLogs.add(LogLine('Error: $e', isError: true)));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  void _startCustomWorkflow() {
    setState(() {
      _selectedWorkflow = null;
      _code!.text = _blankWorkflowTemplate;
    });
  }

  Future<void> _showRepoInfo() async {
    final pubspec = await readRepoPubspec(widget.project.localPath);
    final commit = await _git.lastCommit(widget.project.localPath);
    final remoteUrl = await _git.remoteUrl(widget.project.localPath);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => _RepoInfoDialog(
        project: widget.project,
        pubspec: pubspec,
        commit: commit,
        remoteUrl: remoteUrl,
      ),
    );
  }

  void _onPresetChanged(WorkflowPreset? preset) {
    if (preset == null) return;
    setState(() {
      _selectedWorkflow = null;
      _code!.text = preset.yaml.trim();
    });
  }

  Future<void> _pickArtifactsDir() async {
    final picked = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose an output folder for artifacts');
    if (picked == null) return;
    await context
        .read<ProjectsProvider>()
        .setArtifactsPath(widget.project, picked);
    if (mounted) setState(() {});
  }

  Future<void> _resetArtifactsDir() async {
    await context
        .read<ProjectsProvider>()
        .setArtifactsPath(widget.project, null);
    if (mounted) setState(() {});
  }

  String get _effectiveArtifactsPath =>
      widget.project.artifactsPath ??
      AppPaths.artifactsPathFor(widget.project.localPath);

  Future<void> _onWorkflowChanged(File? f) async {
    if (f == null) return;
    try {
      final content = await f.readAsString();
      if (!mounted) return;
      setState(() {
        _selectedWorkflow = f;
        _code!.text = content;
      });
    } catch (_) {}
  }

  Future<void> _confirmRemove(BuildContext context, Project pr) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove "${pr.name}"?'),
        content: Text(
          'Remove clears it from the sidebar; files stay on disk.'
          '${pr.repoUrl != null ? "\nDelete files also removes the cloned folder." : ""}',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        actions: [
          AppButton.ghost(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context, 'cancel')),
          AppButton.secondary(
              label: 'Remove',
              onPressed: () => Navigator.pop(context, 'remove')),
          if (pr.repoUrl != null)
            AppButton.danger(
                label: 'Delete files',
                onPressed: () => Navigator.pop(context, 'delete')),
        ],
      ),
    );
    if (res == null || res == 'cancel') return;
    // ignore: use_build_context_synchronously
    await context.read<ProjectsProvider>().removeProject(
          pr,
          deleteFiles: res == 'delete',
        );
  }

  void _run() {
    final workflowName = _selectedWorkflow != null
        ? p.basename(_selectedWorkflow!.path)
        : 'inline.yaml';
    final branch = _selectedBranch ?? 'HEAD';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RunScreen(
        project: widget.project,
        branch: branch,
        workflowName: workflowName,
        yamlSource: _code!.text,
        artifactsPath: _effectiveArtifactsPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final proj = widget.project;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            project: proj,
            onRemove: () => _confirmRemove(context, proj),
            onInfo: _showRepoInfo,
            onRun: (_code == null || _code!.text.trim().isEmpty) ? null : _run,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Field(
                      label: 'Branch',
                      icon: Icons.alt_route,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 240,
                            child: _StyledDropdown<String>(
                              value: _selectedBranch,
                              hint: _loadingBranches
                                  ? 'Loading…'
                                  : 'Pick a branch',
                              items: _branches,
                              itemLabel: (b) => b,
                              onChanged:
                                  _switching ? null : _onBranchChanged,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _CommitChip(
                              commit: _branchCommit,
                              loading:
                                  _branchCommit == null && !_loadingBranches),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _Field(
                      label: 'Workflow file',
                      icon: Icons.description_outlined,
                      child: SizedBox(
                        width: 280,
                        child: _StyledDropdown<File>(
                          value: _selectedWorkflow,
                          hint: _workflows.isEmpty
                              ? 'No workflow files found'
                              : 'Pick a workflow',
                          items: _workflows,
                          itemLabel: (f) => p.basename(f.path),
                          onChanged: _onWorkflowChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _Field(
                      label: 'Preset',
                      icon: Icons.auto_awesome_outlined,
                      child: SizedBox(
                        width: 300,
                        child: _StyledDropdown<WorkflowPreset>(
                          value: null,
                          hint: 'Load a preset…',
                          items: kWorkflowPresets,
                          itemLabel: (pr) => pr.label,
                          onChanged: _onPresetChanged,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: t.divider, height: 1),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.folder_special_outlined,
                        size: 15, color: t.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Artifacts output',
                        style: type.caption.copyWith(
                            color: t.textSecondary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Tooltip(
                        message: _effectiveArtifactsPath,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.surfaceMuted,
                            borderRadius: AppRadius.rSm,
                            border: Border.all(color: t.border),
                          ),
                          child: Text(
                            _effectiveArtifactsPath,
                            overflow: TextOverflow.ellipsis,
                            style: type.monoSm.copyWith(
                                color: t.textSecondary, fontSize: 11.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.secondary(
                      icon: Icons.folder_open_outlined,
                      label: 'Change…',
                      size: AppButtonSize.sm,
                      onPressed: _pickArtifactsDir,
                    ),
                    if (widget.project.artifactsPath != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Tooltip(
                        message: 'Reset to default',
                        child: AppButton.ghost(
                          icon: Icons.restart_alt,
                          label: '',
                          size: AppButtonSize.sm,
                          onPressed: _resetArtifactsDir,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _EditorPanel(
                    controller: _code!,
                    onStartCustom: _startCustomWorkflow,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: LogPanel(
                    lines: _switchLogs,
                    title: 'GIT OUTPUT',
                    icon: Icons.polyline_outlined,
                    subtitle:
                        _switching ? 'switching branch…' : null,
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

class _Header extends StatelessWidget {
  final Project project;
  final VoidCallback onRemove;
  final VoidCallback onInfo;
  final VoidCallback? onRun;
  const _Header({
    required this.project,
    required this.onRemove,
    required this.onInfo,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: t.border),
          ),
          child: Icon(Icons.folder_outlined,
              size: 18, color: t.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.name,
                  overflow: TextOverflow.ellipsis, style: type.title),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.link, size: 12, color: t.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(project.repoUrl ?? project.localPath,
                        overflow: TextOverflow.ellipsis,
                        style: type.caption
                            .copyWith(color: t.textMuted, fontSize: 11.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppButton.ghost(
          icon: Icons.info_outline,
          label: 'Repo info',
          size: AppButtonSize.sm,
          onPressed: onInfo,
        ),
        const SizedBox(width: AppSpacing.xs),
        AppButton.ghost(
          icon: Icons.delete_outline,
          label: 'Remove',
          size: AppButtonSize.sm,
          onPressed: onRemove,
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton.primary(
          icon: Icons.play_arrow_rounded,
          label: 'Run workflow',
          onPressed: onRun,
        ),
      ],
    );
  }
}

class _CommitChip extends StatelessWidget {
  final CommitInfo? commit;
  final bool loading;
  const _CommitChip({required this.commit, required this.loading});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    if (commit == null && loading) {
      return SizedBox(
        height: 20,
        child: Row(
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                valueColor: AlwaysStoppedAnimation(t.textMuted),
              ),
            ),
            const SizedBox(width: 6),
            Text('loading commit…',
                style: type.caption.copyWith(
                    color: t.textMuted, fontSize: 11)),
          ],
        ),
      );
    }
    if (commit == null) return const SizedBox(height: 20);
    return Tooltip(
      message:
          '${commit!.subject}\n${commit!.author} · ${commit!.date?.toLocal() ?? ""}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.commit, size: 11, color: t.textMuted),
            const SizedBox(width: 5),
            Text(commit!.shortHash,
                style: type.monoSm
                    .copyWith(color: t.textSecondary, fontSize: 11)),
            const SizedBox(width: 6),
            Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                    color: t.textMuted, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                timeAgo(commit!.date),
                overflow: TextOverflow.ellipsis,
                style: type.caption
                    .copyWith(color: t.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _Field(
      {required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: t.textMuted),
            const SizedBox(width: 5),
            Text(label,
                style: type.overline.copyWith(fontSize: 10.5)),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: t.textMuted),
          style: type.body,
          dropdownColor: t.surfaceElevated,
          borderRadius: AppRadius.rMd,
          hint: Text(hint,
              style: type.body
                  .copyWith(color: t.textMuted, fontSize: 12.5)),
          items: items
              .map((v) => DropdownMenuItem<T>(
                    value: v,
                    child: Text(
                      itemLabel(v),
                      overflow: TextOverflow.ellipsis,
                      style: type.body.copyWith(fontSize: 12.5),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  final CodeController controller;
  final VoidCallback onStartCustom;
  const _EditorPanel({required this.controller, required this.onStartCustom});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final isDark = t.brightness == Brightness.dark;

    if (controller.text.trim().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: t.border),
        ),
        child: EmptyState(
          icon: Icons.description_outlined,
          title: 'No workflow loaded',
          body:
              'Pick a workflow file, load a preset, or start with a blank custom workflow.',
          action: AppButton.primary(
            icon: Icons.edit_note,
            label: 'Start custom workflow',
            onPressed: onStartCustom,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: t.surfaceMuted,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 13, color: t.textSecondary),
                const SizedBox(width: 6),
                Text('WORKFLOW · YAML',
                    style: type.overline),
                const Spacer(),
                Text('${controller.text.split('\n').length} lines',
                    style: type.overline.copyWith(color: t.textMuted)),
              ],
            ),
          ),
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(
                  styles: isDark ? atomOneDarkTheme : atomOneLightTheme),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1400,
                  child: CodeField(
                    controller: controller,
                    expands: true,
                    background: t.surface,
                    textStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        color: t.textPrimary,
                        height: 1.55),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const String _blankWorkflowTemplate = '''
name: Custom workflow
on: [workflow_dispatch]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - name: Hello
        run: |
          echo "Hello from Zataxo!"
          pwd
''';

class _RepoInfoDialog extends StatelessWidget {
  final Project project;
  final RepoPubspec? pubspec;
  final CommitInfo? commit;
  final String? remoteUrl;
  const _RepoInfoDialog({
    required this.project,
    required this.pubspec,
    required this.commit,
    required this.remoteUrl,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return AlertDialog(
      contentPadding: const EdgeInsets.all(AppSpacing.xl),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surfaceMuted,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: t.border),
                  ),
                  child: Icon(Icons.folder_outlined,
                      size: 20, color: t.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pubspec?.name ?? project.name, style: type.title),
                      if (pubspec?.description != null)
                        Text(pubspec!.description!,
                            style: type.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('APP'),
            const SizedBox(height: AppSpacing.sm),
            _kv(context, 'Name', pubspec?.name ?? project.name),
            if (pubspec?.version != null)
              _kv(context, 'Version', pubspec!.version!),
            _kv(context, 'Local path', project.localPath),
            if (remoteUrl != null) _kv(context, 'Remote', remoteUrl!),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('LATEST COMMIT'),
            const SizedBox(height: AppSpacing.sm),
            if (commit != null) ...[
              _kv(context, 'Hash', commit!.shortHash, mono: true),
              _kv(context, 'Author',
                  '${commit!.author}${commit!.email.isNotEmpty ? " <${commit!.email}>" : ""}'),
              _kv(context, 'Date',
                  '${commit!.date?.toLocal().toString().substring(0, 19) ?? "-"} · ${timeAgo(commit!.date)}'),
              _kv(context, 'Subject', commit!.subject),
            ] else
              Text('No commit history found.',
                  style: type.caption.copyWith(color: t.textMuted)),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      actions: [
        AppButton.secondary(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v, {bool mono = false}) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 84,
              child: Text(k,
                  style: type.caption
                      .copyWith(color: t.textMuted, fontSize: 11.5))),
          Expanded(
            child: SelectableText(
              v,
              style: (mono ? type.monoSm : type.body).copyWith(
                  color: t.textPrimary, fontSize: mono ? 12 : 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

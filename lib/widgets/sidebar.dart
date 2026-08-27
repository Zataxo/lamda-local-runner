import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../state/projects_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'app_button.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onCreate;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  const Sidebar({
    super.key,
    required this.onCreate,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  static const double expandedWidth = 256;
  static const double collapsedWidth = 64;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      width: collapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: t.brightness == Brightness.dark
            ? const Color(0xFF0A0C0F)
            : const Color(0xFFF3F4F7),
        border: Border(right: BorderSide(color: t.border)),
      ),
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          child: collapsed
              ? _CollapsedSidebar(
                  key: const ValueKey('collapsed'),
                  onCreate: onCreate,
                  onToggleCollapse: onToggleCollapse,
                )
              : _ExpandedSidebar(
                  key: const ValueKey('expanded'),
                  onCreate: onCreate,
                  onToggleCollapse: onToggleCollapse,
                  onConfirmRemove: (p) => _confirmRemove(context, p),
                ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, Project p) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => _RemoveDialog(project: p),
    );
    if (res == null || res == 'cancel') return;
    // ignore: use_build_context_synchronously
    await context.read<ProjectsProvider>().removeProject(
      p,
      deleteFiles: res == 'delete',
    );
  }
}

class _RemoveDialog extends StatelessWidget {
  final Project project;
  const _RemoveDialog({required this.project});

  @override
  Widget build(BuildContext context) {
    final type = AppTheme.of(context).type;
    final t = AppTheme.of(context).tokens;
    return AlertDialog(
      title: Text('Remove "${project.name}"?'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Remove clears it from the sidebar; files stay on disk.',
            style: type.caption,
          ),
          if (project.repoUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Delete files also removes the cloned folder:',
              style: type.caption,
            ),
            const SizedBox(height: 4),
            Text(
              project.localPath,
              style: type.monoSm.copyWith(color: t.textSecondary),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, 'cancel'),
        ),
        AppButton.secondary(
          label: 'Remove',
          onPressed: () => Navigator.pop(context, 'remove'),
        ),
        if (project.repoUrl != null)
          AppButton.danger(
            label: 'Delete files',
            onPressed: () => Navigator.pop(context, 'delete'),
          ),
      ],
    );
  }
}

class _ProjectTile extends StatefulWidget {
  final Project project;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _ProjectTile({
    required this.project,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<_ProjectTile> {
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
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.rSm),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 15,
                color: widget.selected ? t.accent : t.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.name,
                      overflow: TextOverflow.ellipsis,
                      style: type.body.copyWith(
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                    if (widget.project.lastBranch != null)
                      Text(
                        widget.project.lastBranch!,
                        overflow: TextOverflow.ellipsis,
                        style: type.caption.copyWith(
                          fontSize: 11,
                          color: t.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (_hover)
                Tooltip(
                  message: 'Remove project',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: widget.onRemove,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 13,
                        color: t.textSecondary,
                      ),
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

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = controller.mode == ThemeMode.dark;
    final t = AppTheme.of(context).tokens;
    return Tooltip(
      message: isDark ? 'Switch to light' : 'Switch to dark',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: controller.toggle,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 15,
            color: t.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatefulWidget {
  const _SidebarFooter();
  @override
  State<_SidebarFooter> createState() => _SidebarFooterState();
}

class _SidebarFooterState extends State<_SidebarFooter> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() {
        _version = 'v${info.version}+${info.buildNumber}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            _version ?? '',
            style: type.caption.copyWith(color: t.textMuted, fontSize: 11),
          ),
          const Spacer(),
          Tooltip(
            message: 'About',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _showAbout(context),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.info_outline, size: 13, color: t.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => _AboutDialog(info: info),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  final PackageInfo info;
  const _AboutDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return AlertDialog(
      contentPadding: const EdgeInsets.all(AppSpacing.xl),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.bolt_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(info.appName, style: type.title),
            const SizedBox(height: 2),
            Text(
              'Local CI runner for GitHub Actions-style workflows.',
              style: type.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            _kv(context, 'Version', info.version),
            _kv(context, 'Build', info.buildNumber),
            _kv(context, 'Package', info.packageName),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        AppButton.secondary(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              k,
              style: type.caption.copyWith(color: t.textMuted, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: SelectableText(
              v,
              style: type.monoSm.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedSidebar extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onToggleCollapse;
  final Future<void> Function(Project) onConfirmRemove;
  const _ExpandedSidebar({
    super.key,
    required this.onCreate,
    required this.onToggleCollapse,
    required this.onConfirmRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final projects = context.watch<ProjectsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 44),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.bolt_outlined,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: [
                    Text('LLR',
                        style: type.bodyStrong
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(' (Lamda Local Runner)',
                        style: type.caption.copyWith(
                            fontWeight: FontWeight.w400,
                            color: t.textMuted,
                            fontSize: 10)),
                  ],
                ),
              ),
              _ThemeToggle(),
              const SizedBox(width: 2),
              _CollapseButton(
                collapsed: false,
                onPressed: onToggleCollapse,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: AppButton.primary(
            icon: Icons.add,
            label: 'New Project',
            onPressed: onCreate,
            expand: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text('PROJECTS', style: type.overline),
              const Spacer(),
              Text('${projects.projects.length}',
                  style: type.overline.copyWith(color: t.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: projects.projects.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No projects yet.\nCreate one to get started.',
                    style: type.caption.copyWith(color: t.textMuted),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  itemCount: projects.projects.length,
                  itemBuilder: (_, i) {
                    final pr = projects.projects[i];
                    final selected = projects.selected?.id == pr.id;
                    return _ProjectTile(
                      project: pr,
                      selected: selected,
                      onTap: () => projects.select(pr),
                      onRemove: () => onConfirmRemove(pr),
                    );
                  },
                ),
        ),
        Divider(color: t.divider, height: 1),
        const _SidebarFooter(),
      ],
    );
  }
}

class _CollapsedSidebar extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onToggleCollapse;
  const _CollapsedSidebar({
    super.key,
    required this.onCreate,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final projects = context.watch<ProjectsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 44),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.bolt_outlined,
              size: 16, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.md),
        _CollapseButton(collapsed: true, onPressed: onToggleCollapse),
        const SizedBox(height: AppSpacing.md),
        Tooltip(
          message: 'New project',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onCreate,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(color: t.divider, indent: 12, endIndent: 12, height: 1),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 2),
            itemCount: projects.projects.length,
            itemBuilder: (_, i) {
              final pr = projects.projects[i];
              final selected = projects.selected?.id == pr.id;
              return _CollapsedProjectTile(
                project: pr,
                selected: selected,
                onTap: () => projects.select(pr),
              );
            },
          ),
        ),
        Divider(color: t.divider, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: _ThemeToggle(),
        ),
      ],
    );
  }
}

class _CollapseButton extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onPressed;
  const _CollapseButton(
      {required this.collapsed, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    return Tooltip(
      message: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            collapsed
                ? Icons.keyboard_double_arrow_right
                : Icons.keyboard_double_arrow_left,
            size: 15,
            color: t.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CollapsedProjectTile extends StatefulWidget {
  final Project project;
  final bool selected;
  final VoidCallback onTap;
  const _CollapsedProjectTile({
    required this.project,
    required this.selected,
    required this.onTap,
  });
  @override
  State<_CollapsedProjectTile> createState() =>
      _CollapsedProjectTileState();
}

class _CollapsedProjectTileState extends State<_CollapsedProjectTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    Color bg;
    if (widget.selected) {
      bg = t.accentSubtle;
    } else if (_hover) {
      bg = t.surfaceMuted;
    } else {
      bg = Colors.transparent;
    }
    return Tooltip(
      message: widget.project.name +
          (widget.project.lastBranch != null
              ? '\n${widget.project.lastBranch}'
              : ''),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            margin: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 2),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 17,
              color:
                  widget.selected ? t.accent : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../services/secrets_service.dart';
import '../state/projects_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';

class SecretsManagerScreen extends StatefulWidget {
  final String? initialProjectId;
  final VoidCallback onBack;
  const SecretsManagerScreen({
    super.key,
    required this.onBack,
    this.initialProjectId,
  });

  @override
  State<SecretsManagerScreen> createState() => _SecretsManagerScreenState();
}

class _SecretsManagerScreenState extends State<SecretsManagerScreen> {
  final _svc = SecretsService();
  Project? _selected;
  Map<String, String> _entries = {};
  final Set<String> _revealed = {};
  bool _loading = false;

  bool _adding = false;
  bool _bulkMode = false;
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _bulkCtrl = TextEditingController();
  String? _error;
  String? _bulkStatus;

  static final _nameRe = RegExp(r'^[A-Z][A-Z0-9_]*$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projects = context.read<ProjectsProvider>().projects;
      if (projects.isEmpty) return;
      Project pick = projects.first;
      if (widget.initialProjectId != null) {
        for (final p in projects) {
          if (p.id == widget.initialProjectId) {
            pick = p;
            break;
          }
        }
      }
      _select(pick);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _bulkCtrl.dispose();
    super.dispose();
  }

  Future<void> _select(Project p) async {
    setState(() {
      _selected = p;
      _loading = true;
      _revealed.clear();
      _adding = false;
      _bulkMode = false;
      _error = null;
      _bulkStatus = null;
    });
    final all = await _svc.readAll(p.id);
    if (!mounted) return;
    setState(() {
      _entries = all;
      _loading = false;
    });
  }

  Future<void> _reload() async {
    if (_selected == null) return;
    final all = await _svc.readAll(_selected!.id);
    if (!mounted) return;
    setState(() => _entries = all);
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (!_nameRe.hasMatch(name)) {
      setState(() => _error =
          'Name must be uppercase letters, digits and underscores only (start with a letter).');
      return;
    }
    await _svc.write(
        projectId: _selected!.id, name: name, value: _valueCtrl.text);
    _nameCtrl.clear();
    _valueCtrl.clear();
    if (mounted) {
      setState(() {
        _adding = false;
        _error = null;
      });
    }
    await _reload();
  }

  Future<void> _delete(String name) async {
    if (_selected == null) return;
    await _svc.delete(projectId: _selected!.id, name: name);
    _revealed.remove(name);
    await _reload();
  }

  void _edit(String name) {
    _nameCtrl.text = name;
    _valueCtrl.text = _entries[name] ?? '';
    setState(() {
      _adding = true;
      _bulkMode = false;
      _error = null;
    });
  }

  Future<void> _bulkInject() async {
    if (_selected == null) return;
    final lines = _bulkCtrl.text.split('\n');
    var added = 0;
    var skipped = 0;
    final invalid = <String>[];
    for (final raw in lines) {
      var line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;
      if (line.startsWith('export ')) line = line.substring(7).trim();
      final eq = line.indexOf('=');
      if (eq <= 0) {
        skipped++;
        continue;
      }
      final name = line.substring(0, eq).trim();
      var value = line.substring(eq + 1);
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }
      if (!_nameRe.hasMatch(name)) {
        invalid.add(name);
        skipped++;
        continue;
      }
      await _svc.write(
          projectId: _selected!.id, name: name, value: value);
      added++;
    }
    _bulkCtrl.clear();
    if (!mounted) return;
    final parts = <String>['added $added'];
    if (skipped > 0) parts.add('skipped $skipped');
    if (invalid.isNotEmpty) {
      parts.add('invalid: ${invalid.take(3).join(", ")}${invalid.length > 3 ? "…" : ""}');
    }
    setState(() {
      _bulkStatus = parts.join(' · ');
      _bulkMode = false;
    });
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectsProvider>().projects;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const SizedBox(height: AppSpacing.lg),
          _warningBanner(context),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: projects.isEmpty
                ? _emptyProjects(context)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 240,
                        child: _projectList(context, projects),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _secretsPanel(context)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final type = AppTheme.of(context).type;
    final t = AppTheme.of(context).tokens;
    return Row(
      children: [
        AppButton.ghost(
          icon: Icons.arrow_back,
          label: 'Dashboard',
          size: AppButtonSize.sm,
          onPressed: widget.onBack,
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(Icons.lock_outline, size: 18, color: t.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text('Secrets & Environment', style: type.title),
        const Spacer(),
        Text(
          'Stored in the macOS Keychain',
          style: type.caption.copyWith(color: t.textMuted),
        ),
      ],
    );
  }

  Widget _warningBanner(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: t.warning.withOpacity(0.10),
        borderRadius: AppRadius.rMd,
        border: Border.all(color: t.warning.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 15, color: t.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'These values are injected into every workflow run as environment variables and resolved as \${{ secrets.NAME }}. Their values are redacted from all logs.',
              style: type.caption.copyWith(
                  color: t.textPrimary, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyProjects(BuildContext context) {
    return EmptyState(
      icon: Icons.folder_outlined,
      title: 'No projects yet',
      body: 'Create a project first before managing its secrets.',
    );
  }

  Widget _projectList(BuildContext context, List<Project> projects) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 4),
            child: Text('PROJECTS', style: type.overline),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: 4),
              itemCount: projects.length,
              itemBuilder: (_, i) {
                final p = projects[i];
                final selected = _selected?.id == p.id;
                return InkWell(
                  onTap: () => _select(p),
                  borderRadius: AppRadius.rSm,
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 7),
                    decoration: BoxDecoration(
                      color:
                          selected ? t.accentSubtle : Colors.transparent,
                      borderRadius: AppRadius.rSm,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined,
                            size: 14,
                            color: selected ? t.accent : t.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(p.name,
                              overflow: TextOverflow.ellipsis,
                              style: type.body.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _secretsPanel(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    if (_selected == null) {
      return Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: t.border),
        ),
        child: const EmptyState(
          icon: Icons.arrow_back,
          title: 'Pick a project',
          body: 'Select a project on the left to manage its secrets.',
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selected!.name, style: type.section),
                      Text(
                        '${_entries.length} secret${_entries.length == 1 ? "" : "s"}',
                        style: type.caption
                            .copyWith(color: t.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                AppButton.secondary(
                  icon: Icons.file_upload_outlined,
                  label: 'Bulk paste',
                  size: AppButtonSize.sm,
                  onPressed: () => setState(() {
                    _bulkMode = !_bulkMode;
                    _adding = false;
                    _error = null;
                  }),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton.primary(
                  icon: Icons.add,
                  label: 'Add secret',
                  size: AppButtonSize.sm,
                  onPressed: () => setState(() {
                    _adding = !_adding;
                    _bulkMode = false;
                    _error = null;
                    _nameCtrl.clear();
                    _valueCtrl.clear();
                  }),
                ),
              ],
            ),
          ),
          Divider(color: t.divider, height: 1),
          if (_bulkStatus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 6),
              color: t.surfaceMuted,
              child: Text(_bulkStatus!,
                  style: type.caption.copyWith(color: t.textSecondary)),
            ),
          if (_adding) _addForm(context),
          if (_bulkMode) _bulkForm(context),
          Expanded(child: _table(context)),
        ],
      ),
    );
  }

  Widget _addForm(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      color: t.surfaceMuted,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Name'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _nameCtrl,
                      decoration:
                          const InputDecoration(hintText: 'GITHUB_TOKEN'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Value'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _valueCtrl,
                      obscureText: true,
                      decoration:
                          const InputDecoration(hintText: '••••••••'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!,
                style: type.caption.copyWith(color: t.danger)),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppButton.primary(
                icon: Icons.check,
                label: 'Save',
                size: AppButtonSize.sm,
                onPressed: _save,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.ghost(
                label: 'Cancel',
                size: AppButtonSize.sm,
                onPressed: () {
                  _nameCtrl.clear();
                  _valueCtrl.clear();
                  setState(() {
                    _adding = false;
                    _error = null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bulkForm(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      color: t.surfaceMuted,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Paste KEY=VALUE lines'),
          const SizedBox(height: 4),
          Text(
            'One per line. Comments (# …) and empty lines are ignored. `export FOO=bar` is accepted.',
            style: type.caption
                .copyWith(color: t.textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadius.rMd,
              border: Border.all(color: t.border),
            ),
            child: TextField(
              controller: _bulkCtrl,
              maxLines: 8,
              minLines: 5,
              style: type.monoSm,
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                hintText:
                    'GITHUB_TOKEN=ghp_xxxx\nAPI_KEY="secret value"\n# comment lines are ignored\nexport BUILD_ENV=prod',
                hintStyle: type.monoSm
                    .copyWith(color: t.textMuted, fontSize: 11.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppButton.primary(
                icon: Icons.publish,
                label: 'Inject secrets',
                size: AppButtonSize.sm,
                onPressed: _bulkInject,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.ghost(
                label: 'Cancel',
                size: AppButtonSize.sm,
                onPressed: () => setState(() {
                  _bulkCtrl.clear();
                  _bulkMode = false;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _table(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(t.accent)),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const EmptyState(
        icon: Icons.key_outlined,
        title: 'No secrets yet',
        body:
            'Add tokens, API keys, or environment values used by your workflows.',
      );
    }
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.divider)),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 200,
                  child: Text('NAME', style: type.overline)),
              Expanded(child: Text('VALUE', style: type.overline)),
              const SizedBox(width: 100),
            ],
          ),
        ),
        for (final e in _entries.entries)
          _row(context, e.key, e.value),
      ],
    );
  }

  Widget _row(BuildContext context, String name, String value) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final revealed = _revealed.contains(name);
    final masked = value.isEmpty ? '(empty)' : '••••••••••••';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Row(
              children: [
                Icon(Icons.vpn_key_outlined,
                    size: 13, color: t.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: type.monoSm.copyWith(
                          color: t.textPrimary, fontSize: 12.5)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SelectableText(
              revealed ? value : masked,
              maxLines: 1,
              style: type.monoSm.copyWith(
                  color: revealed ? t.textPrimary : t.textMuted,
                  fontSize: 12.5),
            ),
          ),
          Tooltip(
            message: revealed ? 'Hide value' : 'Reveal value',
            child: IconButton(
              splashRadius: 16,
              constraints:
                  const BoxConstraints(minWidth: 26, minHeight: 26),
              padding: EdgeInsets.zero,
              icon: Icon(
                revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 14,
                color: t.textSecondary,
              ),
              onPressed: () => setState(() {
                if (!_revealed.remove(name)) _revealed.add(name);
              }),
            ),
          ),
          Tooltip(
            message: 'Edit',
            child: IconButton(
              splashRadius: 16,
              constraints:
                  const BoxConstraints(minWidth: 26, minHeight: 26),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.edit_outlined,
                  size: 14, color: t.textSecondary),
              onPressed: () => _edit(name),
            ),
          ),
          Tooltip(
            message: 'Delete',
            child: IconButton(
              splashRadius: 16,
              constraints:
                  const BoxConstraints(minWidth: 26, minHeight: 26),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.delete_outline, size: 14, color: t.danger),
              onPressed: () => _delete(name),
            ),
          ),
        ],
      ),
    );
  }
}

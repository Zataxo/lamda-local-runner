import 'package:flutter/material.dart';

import '../models/project.dart';
import '../services/secrets_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';

class SecretsDialog extends StatefulWidget {
  final Project project;
  const SecretsDialog({super.key, required this.project});

  @override
  State<SecretsDialog> createState() => _SecretsDialogState();
}

class _SecretsDialogState extends State<SecretsDialog> {
  final _svc = SecretsService();
  Map<String, String> _entries = {};
  final Set<String> _revealed = {};
  bool _loading = true;
  bool _adding = false;
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _svc.readAll(widget.project.id);
    if (!mounted) return;
    setState(() {
      _entries = all;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final value = _valueCtrl.text;
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) {
      setState(() => _error =
          'Name must be a valid env-var identifier (letters, digits, underscore).');
      return;
    }
    await _svc.write(
        projectId: widget.project.id, name: name, value: value);
    _nameCtrl.clear();
    _valueCtrl.clear();
    if (mounted) {
      setState(() {
        _adding = false;
        _error = null;
      });
    }
    await _load();
  }

  Future<void> _delete(String name) async {
    await _svc.delete(projectId: widget.project.id, name: name);
    _revealed.remove(name);
    await _load();
  }

  Future<void> _edit(String name) async {
    _nameCtrl.text = name;
    _valueCtrl.text = _entries[name] ?? '';
    setState(() => _adding = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Dialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rLg,
        side: BorderSide(color: t.border),
      ),
      child: SizedBox(
        width: 620,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: t.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Secrets & environment', style: type.section),
                        Text(
                          'Stored in the macOS Keychain, injected into every step and redacted from logs.',
                          style: type.caption,
                        ),
                      ],
                    ),
                  ),
                  AppButton.ghost(
                    icon: Icons.close,
                    label: '',
                    size: AppButtonSize.sm,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: t.divider, height: 1),
            Expanded(
              child: _loading
                  ? Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(t.accent),
                        ),
                      ),
                    )
                  : _entries.isEmpty && !_adding
                      ? EmptyState(
                          icon: Icons.key_outlined,
                          title: 'No secrets yet',
                          body:
                              'Add tokens, API keys, or environment values used by your workflows.',
                          action: AppButton.primary(
                            icon: Icons.add,
                            label: 'Add secret',
                            onPressed: () => setState(() => _adding = true),
                          ),
                        )
                      : ListView(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          children: [
                            for (final e in _entries.entries)
                              _SecretRow(
                                name: e.key,
                                value: e.value,
                                revealed: _revealed.contains(e.key),
                                onToggleReveal: () => setState(() {
                                  if (!_revealed.remove(e.key)) {
                                    _revealed.add(e.key);
                                  }
                                }),
                                onEdit: () => _edit(e.key),
                                onDelete: () => _delete(e.key),
                              ),
                          ],
                        ),
            ),
            if (_adding)
              Container(
                decoration: BoxDecoration(
                  color: t.surfaceMuted,
                  border: Border(top: BorderSide(color: t.border)),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.sm),
                    const FieldLabel('Value'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _valueCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: '••••••••'),
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
                          onPressed: _save,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton.ghost(
                          label: 'Cancel',
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
              )
            else if (_entries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.primary(
                    icon: Icons.add,
                    label: 'Add secret',
                    onPressed: () => setState(() => _adding = true),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SecretRow extends StatelessWidget {
  final String name;
  final String value;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SecretRow({
    required this.name,
    required this.value,
    required this.revealed,
    required this.onToggleReveal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final masked = value.isEmpty ? '(empty)' : '••••••••';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.divider)),
      ),
      child: Row(
        children: [
          Icon(Icons.vpn_key_outlined, size: 14, color: t.textMuted),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 180,
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: type.monoSm
                    .copyWith(color: t.textPrimary, fontSize: 12.5)),
          ),
          Expanded(
            child: SelectableText(
              revealed ? value : masked,
              style: type.monoSm.copyWith(
                  color: revealed ? t.textPrimary : t.textMuted,
                  fontSize: 12.5),
              maxLines: 1,
            ),
          ),
          Tooltip(
            message: revealed ? 'Hide value' : 'Reveal value',
            child: IconButton(
              icon: Icon(
                revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 15,
                color: t.textSecondary,
              ),
              onPressed: onToggleReveal,
            ),
          ),
          Tooltip(
            message: 'Edit',
            child: IconButton(
              icon: Icon(Icons.edit_outlined, size: 15, color: t.textSecondary),
              onPressed: onEdit,
            ),
          ),
          Tooltip(
            message: 'Delete',
            child: IconButton(
              icon: Icon(Icons.delete_outline, size: 15, color: t.danger),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

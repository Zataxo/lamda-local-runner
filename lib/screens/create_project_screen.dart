import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/run_state.dart';
import '../state/projects_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/log_panel.dart';
import '../widgets/section_header.dart';

class CreateProjectScreen extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onCancel;
  const CreateProjectScreen({
    super.key,
    required this.onDone,
    required this.onCancel,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _urlCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _logs = <LogLine>[];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _localCtrl.dispose();
    super.dispose();
  }

  void _log(String line, bool err) {
    setState(() => _logs.add(LogLine(line, isError: err)));
  }

  Future<void> _clone() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Enter a Git URL.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _logs.clear();
    });
    try {
      await context
          .read<ProjectsProvider>()
          .cloneRepo(url: url, onLine: _log);
      if (mounted) widget.onDone();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _browse() async {
    final picked = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose a local Git repository');
    if (picked == null) return;
    setState(() => _localCtrl.text = picked);
  }

  Future<void> _import() async {
    final path = _localCtrl.text.trim();
    if (path.isEmpty) {
      setState(() => _error = 'Enter a local folder path.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<ProjectsProvider>().importLocal(path);
      if (mounted) widget.onDone();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppButton.ghost(
                icon: Icons.arrow_back,
                label: 'Back',
                size: AppButtonSize.sm,
                onPressed: _busy ? null : widget.onCancel,
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Create Project', style: type.title),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('CLONE FROM GIT URL'),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _urlCtrl,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    hintText: 'https://github.com/user/repo.git',
                  ),
                  onSubmitted: (_) => _clone(),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  icon: Icons.cloud_download_outlined,
                  label: 'Clone repository',
                  onPressed: _busy ? null : _clone,
                  loading: _busy && _logs.isNotEmpty,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('OR IMPORT LOCAL REPOSITORY'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _localCtrl,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          hintText: '/Users/you/code/my-repo',
                        ),
                        onSubmitted: (_) => _import(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.secondary(
                      icon: Icons.folder_open_outlined,
                      label: 'Browse…',
                      onPressed: _busy ? null : _browse,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  icon: Icons.check_circle_outline,
                  label: 'Import this folder',
                  onPressed: _busy ? null : _import,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: t.danger.withOpacity(0.12),
                borderRadius: AppRadius.rMd,
                border: Border.all(color: t.danger.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 15, color: t.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(_error!,
                        style: type.caption
                            .copyWith(color: t.danger, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LogPanel(
              lines: _logs,
              title: 'CLONE OUTPUT',
              icon: Icons.terminal,
            ),
          ),
        ],
      ),
    );
  }
}

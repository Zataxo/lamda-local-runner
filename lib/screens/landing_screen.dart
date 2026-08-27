import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onCreate;
  const LandingScreen({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.accentSubtle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('LOCAL RUNNER · v1',
                      style: type.overline.copyWith(color: t.accent)),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Run workflows on your Mac.', style: type.display),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'GitHub Actions-style YAML, executed locally through zsh. '
                  'No servers, no runners in the cloud.',
                  style: type.body.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    AppButton.primary(
                      icon: Icons.add,
                      label: 'Create Project',
                      onPressed: onCreate,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                      child: _Step(
                        n: '1',
                        icon: Icons.folder_zip_outlined,
                        title: 'Import a repo',
                        body:
                            'Clone by URL or point at a local folder that already has .git/.',
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _Step(
                        n: '2',
                        icon: Icons.playlist_play_outlined,
                        title: 'Pick a workflow',
                        body:
                            'Choose from .github/workflows/, load a preset, or paste your own YAML.',
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _Step(
                        n: '3',
                        icon: Icons.terminal,
                        title: 'Run it live',
                        body:
                            'Each step runs in zsh -lc with streaming logs. Artifacts land in a folder you choose.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: t.textSecondary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('This runner is local-only.',
                                style: type.bodyStrong),
                            const SizedBox(height: 2),
                            Text(
                              'actions/checkout is a no-op (repo is already cloned). '
                              'setup-flutter verifies your local flutter. '
                              'Other uses: actions are logged and skipped.',
                              style: type.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final IconData icon;
  final String title;
  final String body;
  const _Step(
      {required this.n,
      required this.icon,
      required this.title,
      required this.body});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.surfaceMuted,
                  borderRadius: AppRadius.rSm,
                  border: Border.all(color: t.border),
                ),
                child: Icon(icon, size: 15, color: t.textSecondary),
              ),
              const Spacer(),
              Text(n,
                  style: type.overline.copyWith(color: t.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: type.bodyStrong),
          const SizedBox(height: 4),
          Text(body, style: type.caption),
        ],
      ),
    );
  }
}

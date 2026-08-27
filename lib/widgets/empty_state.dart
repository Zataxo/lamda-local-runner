import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final double maxWidth;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.maxWidth = 380,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.surfaceMuted,
                  borderRadius: AppRadius.rMd,
                  border: Border.all(color: t.border),
                ),
                child: Icon(icon, size: 20, color: t.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title,
                  style: type.section, textAlign: TextAlign.center),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(body!,
                    textAlign: TextAlign.center,
                    style: type.caption),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

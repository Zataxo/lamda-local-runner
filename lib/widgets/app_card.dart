import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final Color? background;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.elevated = false,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? (elevated ? t.surfaceElevated : t.surface),
        borderRadius: AppRadius.rLg,
        border: Border.all(color: t.border),
      ),
      child: child,
    );
  }
}

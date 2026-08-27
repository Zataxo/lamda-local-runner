import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final type = AppTheme.of(context).type;
    return Text(text.toUpperCase(), style: type.overline);
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final type = AppTheme.of(context).type;
    final t = AppTheme.of(context).tokens;
    return Text(text,
        style: type.caption.copyWith(
            color: t.textSecondary, fontWeight: FontWeight.w500));
  }
}

import 'package:flutter/material.dart';

import '../models/run_state.dart';
import '../theme/app_theme.dart';

class StatusColors {
  final Color fg;
  final Color bg;
  final Color dot;
  const StatusColors(this.fg, this.bg, this.dot);
}

StatusColors statusColors(BuildContext context, StepStatus s) {
  final t = AppTheme.of(context).tokens;
  switch (s) {
    case StepStatus.pending:
      return StatusColors(
          t.textSecondary, t.surfaceMuted, t.idle);
    case StepStatus.running:
      return StatusColors(
          t.warning, t.warning.withOpacity(0.14), t.warning);
    case StepStatus.success:
      return StatusColors(
          t.success, t.success.withOpacity(0.14), t.success);
    case StepStatus.failed:
      return StatusColors(
          t.danger, t.danger.withOpacity(0.14), t.danger);
    case StepStatus.skipped:
      return StatusColors(t.textMuted, t.surfaceMuted, t.textMuted);
  }
}

String statusLabel(StepStatus s) {
  switch (s) {
    case StepStatus.pending:
      return 'Pending';
    case StepStatus.running:
      return 'Running';
    case StepStatus.success:
      return 'Success';
    case StepStatus.failed:
      return 'Failed';
    case StepStatus.skipped:
      return 'Skipped';
  }
}

class StatusBadge extends StatelessWidget {
  final StepStatus status;
  final bool compact;
  const StatusBadge(this.status, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = statusColors(context, status);
    final type = AppTheme.of(context).type;
    final horizontal = compact ? 6.0 : 8.0;
    final vertical = compact ? 2.0 : 3.0;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(status: status, size: compact ? 6 : 7),
          const SizedBox(width: 6),
          Text(
            statusLabel(status),
            style: type.overline.copyWith(
              color: c.fg,
              fontSize: compact ? 10 : 10.5,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final StepStatus status;
  final double size;
  const StatusDot(this.status, {super.key, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return _StatusDot(status: status, size: size);
  }
}

class _StatusDot extends StatelessWidget {
  final StepStatus status;
  final double size;
  const _StatusDot({required this.status, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = statusColors(context, status);
    if (status == StepStatus.running) {
      return SizedBox(
        width: size + 2,
        height: size + 2,
        child: CircularProgressIndicator(
          strokeWidth: 1.6,
          valueColor: AlwaysStoppedAnimation(c.dot),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.dot, shape: BoxShape.circle),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/run_screen.dart';
import '../state/active_runs.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class MinimizedRunBar extends StatelessWidget {
  const MinimizedRunBar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final active = context.watch<ActiveRunsController>();
    final sessions = active.sessions;
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.dashboard_customize_outlined,
              size: 13, color: t.textMuted),
          const SizedBox(width: 6),
          Text('MINIMIZED', style: type.overline),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) => _SessionChip(session: sessions[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionChip extends StatefulWidget {
  final RunSession session;
  const _SessionChip({required this.session});

  @override
  State<_SessionChip> createState() => _SessionChipState();
}

class _SessionChipState extends State<_SessionChip> {
  bool _hover = false;

  Future<void> _open() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RunScreen(session: widget.session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final s = widget.session;
    final status = s.status;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _open,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: _hover ? t.surfaceMuted : Colors.transparent,
            borderRadius: AppRadius.rSm,
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              StatusDot(status, size: 8),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  s.workflowName,
                  overflow: TextOverflow.ellipsis,
                  style: type.body.copyWith(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                    color: t.textMuted, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(s.project.name,
                  overflow: TextOverflow.ellipsis,
                  style: type.caption
                      .copyWith(color: t.textMuted, fontSize: 11.5)),
              const SizedBox(width: 6),
              if (!s.isRunning)
                Tooltip(
                  message: 'Dismiss',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => context
                        .read<ActiveRunsController>()
                        .remove(s.id),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.close,
                          size: 12, color: t.textMuted),
                    ),
                  ),
                )
              else
                Icon(Icons.open_in_new,
                    size: 12, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

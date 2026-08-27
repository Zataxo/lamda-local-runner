import 'package:flutter/material.dart';

import '../models/run_state.dart';
import '../theme/app_theme.dart';

class LogPanel extends StatefulWidget {
  final List<LogLine> lines;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  const LogPanel({
    super.key,
    required this.lines,
    this.title,
    this.subtitle,
    this.icon,
  });

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void didUpdateWidget(covariant LogPanel old) {
    super.didUpdateWidget(old);
    if (widget.lines.length != _lastCount) {
      _lastCount = widget.lines.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: AppDurations.fast,
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;

    return Container(
      decoration: BoxDecoration(
        color: t.terminalBg,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: t.brightness == Brightness.dark
                    ? const Color(0xFF14181D)
                    : const Color(0xFF161A1F),
                border: Border(
                  bottom: BorderSide(color: t.border),
                ),
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon,
                        size: 13, color: t.terminalDim),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      widget.title!,
                      overflow: TextOverflow.ellipsis,
                      style: type.caption.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(widget.subtitle!,
                        style: type.caption.copyWith(
                            color: t.terminalDim, fontSize: 11)),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Scrollbar(
                controller: _scroll,
                child: widget.lines.isEmpty
                    ? Center(
                        child: Text('Waiting for output…',
                            style: type.monoSm.copyWith(
                                color: t.terminalDim)))
                    : ListView.builder(
                        controller: _scroll,
                        itemCount: widget.lines.length,
                        itemBuilder: (_, i) {
                          final l = widget.lines[i];
                          return SelectableText(
                            l.text,
                            style: type.mono.copyWith(
                              color: l.isError
                                  ? t.terminalErr
                                  : t.terminalFg,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

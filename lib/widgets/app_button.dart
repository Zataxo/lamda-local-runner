import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }
enum AppButtonSize { sm, md }

class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.expand = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.danger;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final type = AppTheme.of(context).type;
    final disabled = widget.onPressed == null || widget.loading;

    Color bg;
    Color fg;
    Color? border;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = _pressed
            ? t.accentPressed
            : _hover
                ? t.accentHover
                : t.accent;
        fg = Colors.white;
        border = null;
        break;
      case AppButtonVariant.secondary:
        bg = _pressed
            ? t.surfaceMuted
            : _hover
                ? t.surfaceElevated
                : t.surface;
        fg = t.textPrimary;
        border = t.border;
        break;
      case AppButtonVariant.ghost:
        bg = _pressed
            ? t.surfaceMuted
            : _hover
                ? (t.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.04))
                : Colors.transparent;
        fg = t.textPrimary;
        border = null;
        break;
      case AppButtonVariant.danger:
        bg = _pressed
            ? t.danger.withOpacity(0.85)
            : _hover
                ? t.danger.withOpacity(0.92)
                : t.danger;
        fg = Colors.white;
        border = null;
        break;
    }

    if (disabled) {
      bg = widget.variant == AppButtonVariant.ghost
          ? Colors.transparent
          : t.surfaceMuted;
      fg = t.textMuted;
      border = widget.variant == AppButtonVariant.secondary ? t.border : null;
    }

    final isSm = widget.size == AppButtonSize.sm;
    final padH = isSm ? 10.0 : 14.0;
    final padV = isSm ? 6.0 : 9.0;
    final iconSize = isSm ? 14.0 : 15.0;
    final textStyle = (isSm ? type.caption : type.bodyStrong)
        .copyWith(color: fg, fontWeight: FontWeight.w600);

    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: iconSize, color: fg),
        if (widget.loading || widget.icon != null)
          SizedBox(width: isSm ? 6 : 8),
        Flexible(
          child: Text(widget.label,
              overflow: TextOverflow.ellipsis, style: textStyle),
        ),
      ],
    );

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.rMd,
            border: border != null ? Border.all(color: border) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

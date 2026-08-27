import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
}

class AppTokens {
  final Brightness brightness;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;

  final Color border;
  final Color borderStrong;
  final Color divider;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;

  final Color accent;
  final Color accentHover;
  final Color accentPressed;
  final Color accentSubtle;

  final Color success;
  final Color danger;
  final Color warning;
  final Color idle;

  final Color terminalBg;
  final Color terminalFg;
  final Color terminalErr;
  final Color terminalDim;

  const AppTokens({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.accentSubtle,
    required this.success,
    required this.danger,
    required this.warning,
    required this.idle,
    required this.terminalBg,
    required this.terminalFg,
    required this.terminalErr,
    required this.terminalDim,
  });

  static const AppTokens dark = AppTokens(
    brightness: Brightness.dark,
    background: Color(0xFF0B0D10),
    surface: Color(0xFF111418),
    surfaceElevated: Color(0xFF161A1F),
    surfaceMuted: Color(0xFF1B2026),
    border: Color(0xFF20262D),
    borderStrong: Color(0xFF2A323B),
    divider: Color(0xFF1A2026),
    textPrimary: Color(0xFFE7EAEE),
    textSecondary: Color(0xFFAAB2BD),
    textMuted: Color(0xFF6C7480),
    textInverse: Color(0xFF0B0D10),
    accent: Color(0xFF5E6AD2),
    accentHover: Color(0xFF6D78DA),
    accentPressed: Color(0xFF4E58B8),
    accentSubtle: Color(0x1A5E6AD2),
    success: Color(0xFF3FB950),
    danger: Color(0xFFF85149),
    warning: Color(0xFFD29922),
    idle: Color(0xFF6C7480),
    terminalBg: Color(0xFF0A0C0F),
    terminalFg: Color(0xFFC9D1D9),
    terminalErr: Color(0xFFFF7B72),
    terminalDim: Color(0xFF6C7480),
  );

  static const AppTokens light = AppTokens(
    brightness: Brightness.light,
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F3F6),
    border: Color(0xFFE4E7EC),
    borderStrong: Color(0xFFD0D5DD),
    divider: Color(0xFFEEF0F3),
    textPrimary: Color(0xFF11151A),
    textSecondary: Color(0xFF515866),
    textMuted: Color(0xFF8A93A0),
    textInverse: Color(0xFFFFFFFF),
    accent: Color(0xFF5E6AD2),
    accentHover: Color(0xFF4E58B8),
    accentPressed: Color(0xFF404AA0),
    accentSubtle: Color(0x145E6AD2),
    success: Color(0xFF17803D),
    danger: Color(0xFFB42318),
    warning: Color(0xFFB54708),
    idle: Color(0xFF8A93A0),
    terminalBg: Color(0xFF0F1115),
    terminalFg: Color(0xFFE1E4EA),
    terminalErr: Color(0xFFFF8E85),
    terminalDim: Color(0xFF7A8391),
  );
}

class AppTypography {
  final TextStyle display;
  final TextStyle title;
  final TextStyle section;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle caption;
  final TextStyle overline;
  final TextStyle mono;
  final TextStyle monoSm;

  const AppTypography({
    required this.display,
    required this.title,
    required this.section,
    required this.body,
    required this.bodyStrong,
    required this.caption,
    required this.overline,
    required this.mono,
    required this.monoSm,
  });

  factory AppTypography.build(AppTokens t) {
    final ui = GoogleFonts.interTextTheme();
    final mono = GoogleFonts.jetBrainsMonoTextTheme();
    return AppTypography(
      display: ui.headlineSmall!.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: t.textPrimary,
        height: 1.2,
      ),
      title: ui.titleLarge!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: t.textPrimary,
        height: 1.3,
      ),
      section: ui.titleMedium!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: t.textPrimary,
        height: 1.35,
      ),
      body: ui.bodyMedium!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: t.textPrimary,
        height: 1.45,
      ),
      bodyStrong: ui.bodyMedium!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: t.textPrimary,
        height: 1.45,
      ),
      caption: ui.bodySmall!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: t.textSecondary,
        height: 1.4,
      ),
      overline: ui.labelSmall!.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: t.textMuted,
        height: 1.2,
      ),
      mono: mono.bodyMedium!.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: t.terminalFg,
        height: 1.55,
      ),
      monoSm: mono.bodySmall!.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: t.terminalFg,
        height: 1.5,
      ),
    );
  }
}

class AppTheme extends InheritedWidget {
  final AppTokens tokens;
  final AppTypography type;
  final ThemeMode mode;
  final void Function(ThemeMode) setMode;

  const AppTheme({
    super.key,
    required this.tokens,
    required this.type,
    required this.mode,
    required this.setMode,
    required super.child,
  });

  static AppTheme of(BuildContext context) {
    final t = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(t != null, 'AppTheme not found in tree');
    return t!;
  }

  @override
  bool updateShouldNotify(AppTheme old) =>
      old.tokens != tokens || old.mode != mode;

  static ThemeData materialTheme(AppTokens t, AppTypography type) {
    final scheme = ColorScheme(
      brightness: t.brightness,
      primary: t.accent,
      onPrimary: Colors.white,
      secondary: t.accent,
      onSecondary: Colors.white,
      error: t.danger,
      onError: Colors.white,
      surface: t.surface,
      onSurface: t.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      dividerColor: t.divider,
      splashFactory: NoSplash.splashFactory,
      hoverColor: t.brightness == Brightness.dark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.035),
      highlightColor: Colors.transparent,
      textTheme: TextTheme(
        displaySmall: type.display,
        titleLarge: type.title,
        titleMedium: type.section,
        bodyMedium: type.body,
        bodySmall: type.caption,
        labelSmall: type.overline,
      ),
      iconTheme: IconThemeData(color: t.textSecondary, size: 16),
      dividerTheme: DividerThemeData(color: t.divider, space: 1, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
          side: BorderSide(color: t.border),
        ),
        titleTextStyle: type.title,
        contentTextStyle: type.body,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        hintStyle: type.body.copyWith(color: t.textMuted),
        border: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: t.accent, width: 1.4),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: type.body,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surfaceElevated),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: AppRadius.rMd,
            side: BorderSide(color: t.border),
          )),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.brightness == Brightness.dark
              ? const Color(0xFF20262D)
              : const Color(0xFF1F2937),
          borderRadius: AppRadius.rSm,
        ),
        textStyle: type.caption.copyWith(color: Colors.white, fontSize: 11.5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        waitDuration: const Duration(milliseconds: 350),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        thumbColor: WidgetStatePropertyAll(t.borderStrong),
        radius: const Radius.circular(3),
      ),
    );
  }
}

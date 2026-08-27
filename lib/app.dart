import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/create_project_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/project_screen.dart';
import 'state/projects_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/sidebar.dart';

class ZataxoApp extends StatelessWidget {
  const ZataxoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => ProjectsProvider()..loadIfNeeded(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controller, _) {
          final tokens = controller.mode == ThemeMode.dark
              ? AppTokens.dark
              : AppTokens.light;
          final type = AppTypography.build(tokens);
          return AppTheme(
            tokens: tokens,
            type: type,
            mode: controller.mode,
            setMode: controller.set,
            child: MaterialApp(
              title: 'Zataxo Pipeline',
              debugShowCheckedModeBanner: false,
              themeMode: controller.mode,
              theme: AppTheme.materialTheme(
                AppTokens.light,
                AppTypography.build(AppTokens.light),
              ),
              darkTheme: AppTheme.materialTheme(
                AppTokens.dark,
                AppTypography.build(AppTokens.dark),
              ),
              home: const _Home(),
            ),
          );
        },
      ),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  bool _creating = false;
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final projects = context.watch<ProjectsProvider>();
    final selected = projects.selected;

    Widget main;
    if (!projects.loaded) {
      main = Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(t.accent),
          ),
        ),
      );
    } else if (_creating) {
      main = CreateProjectScreen(
        onDone: () => setState(() => _creating = false),
        onCancel: () => setState(() => _creating = false),
      );
    } else if (selected == null) {
      main = LandingScreen(onCreate: () => setState(() => _creating = true));
    } else {
      main = ProjectScreen(key: ValueKey(selected.id), project: selected);
    }

    return Scaffold(
      backgroundColor: t.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Sidebar(
            onCreate: () => setState(() => _creating = true),
            collapsed: _sidebarCollapsed,
            onToggleCollapse: () => setState(
                () => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDurations.normal,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(
                  _creating ? 'create' : (selected?.id ?? 'landing'),
                ),
                child: main,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

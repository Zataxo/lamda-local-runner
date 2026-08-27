import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/project.dart';
import 'screens/create_project_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/project_screen.dart';
import 'screens/secrets_manager_screen.dart';
import 'state/active_runs.dart';
import 'state/projects_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/minimized_run_bar.dart';
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
        ChangeNotifierProvider(create: (_) => ActiveRunsController()),
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
  bool _showSecrets = false;
  String? _secretsInitialProjectId;
  bool _sidebarCollapsed = false;

  void _goDashboard() {
    context.read<ProjectsProvider>().select(null);
    setState(() {
      _creating = false;
      _showSecrets = false;
    });
  }

  void _openSecrets({String? projectId}) {
    setState(() {
      _creating = false;
      _showSecrets = true;
      _secretsInitialProjectId = projectId;
    });
  }

  void _openProject(Project p) {
    context.read<ProjectsProvider>().select(p);
    setState(() {
      _creating = false;
      _showSecrets = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context).tokens;
    final projects = context.watch<ProjectsProvider>();
    final selected = projects.selected;

    final dashboardSelected =
        projects.loaded && !_creating && !_showSecrets && selected == null;
    final secretsSelected = _showSecrets;

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
    } else if (_showSecrets) {
      main = SecretsManagerScreen(
        initialProjectId: _secretsInitialProjectId,
        onBack: _goDashboard,
      );
    } else if (selected == null) {
      main = DashboardScreen(
        onCreate: () => setState(() => _creating = true),
        onOpenSecrets: () => _openSecrets(),
        onOpenProject: _openProject,
        onQuickRun: _openProject,
      );
    } else {
      main = ProjectScreen(
        key: ValueKey(selected.id),
        project: selected,
      );
    }

    String keyFor() {
      if (_creating) return 'create';
      if (_showSecrets) return 'secrets';
      if (selected == null) return 'dashboard';
      return 'project:${selected.id}';
    }

    return Scaffold(
      backgroundColor: t.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Sidebar(
                  onCreate: () => setState(() {
                    _creating = true;
                    _showSecrets = false;
                  }),
                  collapsed: _sidebarCollapsed,
                  onToggleCollapse: () => setState(
                      () => _sidebarCollapsed = !_sidebarCollapsed),
                  dashboardSelected: dashboardSelected,
                  onDashboard: _goDashboard,
                  secretsSelected: secretsSelected,
                  onSecrets: () => _openSecrets(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppDurations.normal,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(keyFor()),
                      child: main,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const MinimizedRunBar(),
        ],
      ),
    );
  }
}

# Zataxo Pipeline

A Flutter macOS desktop app that runs GitHub Actions-style workflow YAML **locally** on your Mac. It does **not** call GitHub Actions or GitHub's servers; every step runs in a real `zsh -lc` subprocess in the cloned repo directory.

## What it does

1. **Landing** — a short "How it works" screen and a **Create Project** button.
2. **Create Project** — paste a Git URL to `git clone` into `~/Library/Application Support/zataxo_pipeline/projects/<repo>`, or import an existing local `.git` repo.
3. **Project** — pick a branch (checkout + pull), pick a workflow file from `.github/workflows/`, or paste your own YAML into the editor.
4. **Run** — the workflow is parsed and executed job-by-job, step-by-step, with live-streaming logs and per-step status.
5. **Artifacts** — `actions/upload-artifact` copies matched files into `<project>/_artifacts/`; a **Reveal in Finder** button opens it.

## Workflow engine

- YAML is parsed with `package:yaml`.
- Jobs run sequentially. `needs:` and `strategy.matrix` are noted as unsupported and the job runs once.
- `run:` steps execute as `Process.start('zsh', ['-lc', script])` with `workingDirectory` set to the repo checkout, honoring `working-directory` and `env` and `continue-on-error`. stdout/stderr stream to the UI line-by-line.
- `uses:` steps are special-cased:
  - `actions/checkout*` → no-op (the repo is already cloned and on the chosen branch).
  - `subosito/flutter-action*`, `*setup-flutter*`, `*flutter-action*` → verifies `flutter --version` locally.
  - `actions/upload-artifact*` → reads `with.path` (supports newline-separated globs, files, and directories) and copies matches into `<project>/_artifacts/`.
  - Anything else → logged as `Unsupported action, skipped: <name>` and passed over.
- Expression expansion is intentionally minimal: `${{ github.ref_name }}` (current branch), `${{ github.workspace }}` (checkout path), and `${{ github.repository }}` (basename). Other `${{ ... }}` expressions are left as-is with a warning.
- Every child process gets an explicit `PATH` that includes `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `/bin` (plus the Flutter SDK `bin`), and `GITHUB_WORKSPACE` set to the repo path.

## macOS sandboxing — important

macOS Flutter apps ship sandboxed by default. A sandboxed app cannot spawn `git`, `zsh`, or `flutter` freely. **This app intentionally disables App Sandbox** in both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements` by removing `com.apple.security.app-sandbox`. This is deliberate: the whole point of the app is to invoke arbitrary local commands from a user-supplied workflow. Do not re-enable the sandbox unless you replace subprocess execution with a helper tool.

Because GUI apps launched from Finder get a minimal `PATH`, the app always shells out through `zsh -lc` **and** injects an explicit PATH. That way `git`, `brew`-installed tools, and `flutter` are always found.

## Project layout

```
lib/
  main.dart
  app.dart
  models/
    project.dart
    run_state.dart
  services/
    path_utils.dart      # support dir, projects dir, PATH assembly
    git_service.dart     # clone / branch / checkout / pull
    project_storage.dart # projects.json load/save
    workflow_runner.dart # YAML → jobs → steps → subprocess (the engine)
  state/
    projects_provider.dart
    run_provider.dart
  screens/
    landing_screen.dart
    create_project_screen.dart
    project_screen.dart
    run_screen.dart
  widgets/
    sidebar.dart
    log_panel.dart
    status_dot.dart
macos/Runner/
  DebugProfile.entitlements  # sandbox removed
  Release.entitlements       # sandbox removed
```

## Persistence

Projects are saved as JSON at `~/Library/Application Support/zataxo_pipeline/projects.json` (`{ id, name, repoUrl, localPath, lastBranch }`). Cloned checkouts live under `~/Library/Application Support/zataxo_pipeline/projects/<repo>/`.

## Building

```bash
flutter pub get
flutter run -d macos      # dev
flutter build macos       # release .app in build/macos/Build/Products/Release/
```

## Status colors

- grey — pending
- blue — running
- green — success
- red — failed
- light grey — skipped

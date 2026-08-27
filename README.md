<div align="center">

# Lamda Local Runner Pipeline

**Run your GitHub Actions workflows locally on your Mac — no servers, no minutes, no waiting.**

A Flutter macOS desktop app that parses GitHub Actions-style workflow YAML and executes each step in a real shell on your own machine, against any branch of any repo you point it at.

</div>

---

## Why

GitHub Actions is great, but iterating on a pipeline means pushing a commit, waiting in a queue, watching a remote log, and burning CI minutes for every small change. Zataxo Pipeline flips that around: it takes the **same workflow YAML** you already have in `.github/workflows/` and runs it **locally**, step by step, with live logs — so you can test, debug, and build without touching GitHub's servers.

Because it runs on real macOS hardware (not a Linux container), it can build **Apple targets** — iOS and macOS Flutter apps — which containerized local runners simply can't.

## Key features

- **Two ways to add a project**
  - **Clone a remote repo** — paste any Git URL (GitHub, GitLab, Bitbucket, self-hosted) and the app clones it locally.
  - **Import a local repo** — already have the repo on disk? Point the app at an existing folder with a `.git` directory and it uses it in place.
- **Work from any branch** — the app reads all branches and lets you check out and pull any one of them before a run.
- **Use your existing workflows or write your own** — it auto-discovers every file under `.github/workflows/`, or you can paste/edit YAML directly in the built-in editor.
- **Live, step-by-step execution** — jobs and steps run in order with real-time streaming stdout/stderr and per-step status indicators.
- **Real artifacts** — `upload-artifact` steps copy your build outputs into a local `_artifacts/` folder you can open in Finder.
- **Local & offline** — everything happens on your machine. No tokens for execution, no CI minutes, no queue.

## How it works

```
  ┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
  │  Add repo   │ ──▶ │ Pick branch  │ ──▶ │ Pick / write│ ──▶ │  Run & watch │
  │ clone/import│     │  checkout    │     │  workflow   │     │  live logs   │
  └─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
```

1. **Add a project.** Clone a remote repo by URL, or import an existing local `.git` repository. Cloned repos land in `~/Library/Application Support/zataxo_pipeline/projects/<repo>/`.
2. **Pick a branch.** The app lists every branch; selecting one runs a checkout and pull so your build reflects that branch's code.
3. **Choose a workflow.** Select any file the app finds under `.github/workflows/`, or paste your own YAML into the editor and tweak it freely.
4. **Run.** The workflow is parsed and executed job-by-job, step-by-step. Each step streams its output live, and you get a clear pass/fail status as it goes.
5. **Collect artifacts.** Anything an `upload-artifact` step matches is copied into `<project>/_artifacts/`, one click away in Finder.

## What the workflow engine supports

The engine executes real GitHub Actions YAML, with a pragmatic scope focused on what a typical build pipeline needs.

**Fully supported**

- **`run:` steps** — executed as `zsh -lc` subprocesses in the repo checkout, honoring `working-directory`, `env`, and `continue-on-error`, with output streamed to the UI line-by-line.
- **`actions/checkout`** — a no-op, since the repo is already cloned and on your chosen branch.
- **Flutter setup actions** (`subosito/flutter-action`, `*setup-flutter*`, `*flutter-action*`) — verified against your locally installed Flutter (`flutter --version`).
- **`actions/upload-artifact`** — reads `with.path` (newline-separated globs, files, or directories) and copies matches into `_artifacts/`.
- **A minimal set of expressions** — `${{ github.ref_name }}` (current branch), `${{ github.workspace }}` (checkout path), and `${{ github.repository }}`.

**Not supported (yet)**

- Third-party `uses:` actions beyond those above — logged as `Unsupported action, skipped: <name>` and passed over.
- `needs:` dependencies and `strategy.matrix` — noted as unsupported; the job runs once.
- Full `${{ }}` expression evaluation — anything outside the small set above is left as-is with a warning.

Every child process runs with an explicit `PATH` (`/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `/bin`, plus the Flutter SDK `bin`) and a `GITHUB_WORKSPACE` pointing at the repo, so `git`, Homebrew tools, and `flutter` are always found.

## Building from source

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install/macos) with macOS desktop support enabled.

```bash
flutter pub get
flutter run -d macos      # run in development
flutter build macos       # release .app → build/macos/Build/Products/Release/
```

## macOS sandboxing — important

macOS Flutter apps ship **sandboxed** by default, and a sandboxed app can't freely spawn `git`, `zsh`, or `flutter`. Because invoking arbitrary local commands from your workflow is the entire point of this tool, Zataxo Pipeline **intentionally disables App Sandbox** — `com.apple.security.app-sandbox` is removed from both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`.

This is deliberate. It also means the app is **not** distributable through the Mac App Store as-is. Don't re-enable the sandbox unless you move subprocess execution into a privileged helper tool.

> **Note:** This app runs workflow YAML as real shell commands on your machine. Only run workflows from repositories you trust — the same caution you'd apply to running any script you didn't write.

## Project structure

```
lib/
  main.dart
  app.dart
  models/
    project.dart
    run_state.dart
  services/
    path_utils.dart        # support dir, projects dir, PATH assembly
    git_service.dart       # clone / branch / checkout / pull
    project_storage.dart   # projects.json load/save
    workflow_runner.dart   # YAML → jobs → steps → subprocess (the engine)
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

Projects persist as JSON at `~/Library/Application Support/zataxo_pipeline/projects.json` (`{ id, name, repoUrl, localPath, lastBranch }`).

## Status colors

| Color      | Meaning |
| ---------- | ------- |
| Grey       | Pending |
| Blue       | Running |
| Green      | Success |
| Red        | Failed  |
| Light grey | Skipped |

## Roadmap

- `needs:` job dependencies and `strategy.matrix`
- Broader `${{ }}` expression evaluation and `secrets` support
- A wider library of built-in `uses:` actions
- Run history and re-run

## License

Add your license of choice here (e.g. MIT).

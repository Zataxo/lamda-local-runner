class WorkflowPreset {
  final String id;
  final String label;
  final String subtitle;
  final String yaml;
  const WorkflowPreset({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.yaml,
  });
}

const _macos = WorkflowPreset(
  id: 'macos',
  label: 'Build macOS (release)',
  subtitle: 'flutter build macos',
  yaml: '''
name: Build macOS
on: [workflow_dispatch]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - name: Versions
        run: |
          flutter --version
          dart --version
      - name: Pub get
        run: flutter pub get
      - name: Build macOS
        run: flutter build macos --release
      - name: Upload .app
        uses: actions/upload-artifact@v4
        with:
          name: macos-app
          path: build/macos/Build/Products/Release/*.app
''',
);

const _fba = WorkflowPreset(
  id: 'fba',
  label: 'fba — flutter build apk',
  subtitle: 'Release APK',
  yaml: '''
name: fba — Build APK
on: [workflow_dispatch]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - name: Versions
        run: |
          flutter --version
          dart --version
      - name: Pub get
        run: flutter pub get
      - name: Build APK
        run: flutter build apk
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: apk
          path: build/app/outputs/flutter-apk/*.apk
''',
);

const _fbaa = WorkflowPreset(
  id: 'fbaa',
  label: 'fbaa — flutter build appbundle',
  subtitle: 'Release AAB',
  yaml: '''
name: fbaa — Build App Bundle
on: [workflow_dispatch]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - name: Versions
        run: |
          flutter --version
          dart --version
      - name: Pub get
        run: flutter pub get
      - name: Build App Bundle
        run: flutter build appbundle
      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: aab
          path: build/app/outputs/bundle/release/*.aab
''',
);

const _fbaob = WorkflowPreset(
  id: 'fbaob',
  label: 'fbaob — flutter build apk --obfuscate',
  subtitle: 'Obfuscated APK + debug-info',
  yaml: '''
name: fbaob — Build APK (obfuscated)
on: [workflow_dispatch]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - name: Versions
        run: |
          flutter --version
          dart --version
      - name: Pub get
        run: flutter pub get
      - name: Build APK (obfuscated)
        run: flutter build apk --obfuscate --split-debug-info=build/debug-info
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: apk-obfuscated
          path: build/app/outputs/flutter-apk/*.apk
      - name: Upload debug-info
        uses: actions/upload-artifact@v4
        with:
          name: debug-info
          path: build/debug-info
''',
);

const _fbaabob = WorkflowPreset(
  id: 'fbaabob',
  label: 'fbaabob — flutter build appbundle --obfuscate',
  subtitle: 'Obfuscated AAB + debug-info',
  yaml: '''
name: fbaabob — Build App Bundle (obfuscated)
on: [workflow_dispatch]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - name: Versions
        run: |
          flutter --version
          dart --version
      - name: Pub get
        run: flutter pub get
      - name: Build App Bundle (obfuscated)
        run: flutter build appbundle --obfuscate --split-debug-info=build/debug-info
      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: aab-obfuscated
          path: build/app/outputs/bundle/release/*.aab
      - name: Upload debug-info
        uses: actions/upload-artifact@v4
        with:
          name: debug-info
          path: build/debug-info
''',
);

const List<WorkflowPreset> kWorkflowPresets = [
  _macos,
  _fba,
  _fbaa,
  _fbaob,
  _fbaabob,
];

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecretsService {
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(),
  );
  static const _prefix = 'zataxo/';

  String _key(String projectId, String name) => '$_prefix$projectId/$name';

  Future<Map<String, String>> readAll(String projectId) async {
    final all = await _storage.readAll();
    final scope = '$_prefix$projectId/';
    final out = <String, String>{};
    all.forEach((k, v) {
      if (k.startsWith(scope)) {
        out[k.substring(scope.length)] = v;
      }
    });
    return out;
  }

  Future<void> write({
    required String projectId,
    required String name,
    required String value,
  }) async {
    await _storage.write(key: _key(projectId, name), value: value);
  }

  Future<void> delete({
    required String projectId,
    required String name,
  }) async {
    await _storage.delete(key: _key(projectId, name));
  }

  Future<void> deleteAll(String projectId) async {
    final all = await readAll(projectId);
    for (final k in all.keys) {
      await delete(projectId: projectId, name: k);
    }
  }
}

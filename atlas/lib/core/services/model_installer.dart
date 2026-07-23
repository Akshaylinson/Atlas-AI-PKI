import 'dart:io';
import 'atlas_package_service.dart';

class ModelInstaller {
  /// Returns the model path if a supported model file exists in the active
  /// package's models/ directory, otherwise null.
  Future<String?> ensureInstalled() async {
    try {
      final modelsDir = await AtlasPackageService.getModelsDir();
      final dir = Directory(modelsDir);
      if (!dir.existsSync()) return null;

      final models = dir
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.task') ||
              f.path.endsWith('.bin'))
          .toList();

      if (models.isEmpty) return null;
      return models.first.path;
    } catch (_) {
      return null;
    }
  }
}





import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'atlas_package_service.dart';

const _modelExts = ['.gguf', '.task', '.bin'];

class ModelInstaller {
  /// Checks in order:
  ///   1. Active package models/ directory  (pendrive / package)
  ///   2. assets/models/gemma/              (bundled alongside the app binary)
  ///
  /// Returns an absolute path to the first model found, or null.
  Future<String?> ensureInstalled() async {
    // 1 — package models dir
    final fromPackage = await _scanPackageModels();
    if (fromPackage != null) return fromPackage;

    // 2 — bundled assets next to the binary (Linux / desktop)
    final fromAssets = await _scanBundledAssets();
    if (fromAssets != null) return fromAssets;

    return null;
  }

  Future<String?> _scanPackageModels() async {
    try {
      final modelsDir = await AtlasPackageService.getModelsPath();
      return _firstModelIn(modelsDir);
    } catch (_) {
      return null;
    }
  }

  /// On Linux/desktop the app binary sits next to an `assets/` folder.
  /// On Android the assets are inside the APK — we copy to the package dir.
  Future<String?> _scanBundledAssets() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // The binary is at e.g. /path/to/bundle/atlas
      // Assets are at       /path/to/bundle/data/flutter_assets/assets/models/gemma/
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final candidates = [
        p.join(exeDir, 'data', 'flutter_assets', 'assets', 'models', 'gemma'),
        p.join(exeDir, 'assets', 'models', 'gemma'),
        // Also check right next to the project source (dev mode)
        p.join(exeDir, '..', '..', '..', '..', 'assets', 'models', 'gemma'),
      ];
      for (final dir in candidates) {
        final found = _firstModelIn(dir);
        if (found != null) return found;
      }
    } else if (Platform.isAndroid) {
      // On Android, copy from asset bundle into the package models dir
      return _copyAndroidBundledModel();
    }
    return null;
  }

  Future<String?> _copyAndroidBundledModel() async {
    try {
      // List known bundled model asset paths
      const bundledPaths = [
        'assets/models/gemma/model.gguf',
        'assets/models/gemma/model.task',
        'assets/models/gemma/model.bin',
      ];
      for (final assetPath in bundledPaths) {
        try {
          final data = await rootBundle.load(assetPath);
          final modelsDir = await AtlasPackageService.getModelsPath();
          final dest = File(p.join(modelsDir, p.basename(assetPath)));
          if (!dest.existsSync()) {
            await dest.create(recursive: true);
            await dest.writeAsBytes(data.buffer.asUint8List());
          }
          return dest.path;
        } catch (_) {
          // asset not bundled, try next
        }
      }
    } catch (_) {}
    return null;
  }

  String? _firstModelIn(String dirPath) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return null;
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => _modelExts.any(f.path.toLowerCase().endsWith))
          .toList();
      if (files.isEmpty) return null;
      return files.first.path;
    } catch (_) {
      return null;
    }
  }
}

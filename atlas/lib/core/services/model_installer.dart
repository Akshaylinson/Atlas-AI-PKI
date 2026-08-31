import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'atlas_package_service.dart';

/// Gemma-only model formats supported by flutter_gemma / MediaPipe.
const _gemmaExts = ['.task', '.bin'];

class ModelInstaller {
  /// Checks in order:
  ///   1. Active Atlas Package  models/ directory  (pendrive / package)
  ///   2. assets/models/gemma/ bundled with the app binary (desktop)
  ///   3. APK asset bundle copy (Android)
  ///
  /// Returns absolute path to first Gemma model found, or null.
  Future<String?> ensureInstalled() async {
    return await _scanPackageModels()
        ?? await _scanBundledAssets();
  }

  Future<String?> _scanPackageModels() async {
    try {
      final dir = await AtlasPackageService.getModelsPath();
      return _firstIn(dir);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _scanBundledAssets() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final exe = p.dirname(Platform.resolvedExecutable);
      final candidates = [
        p.join(exe, 'data', 'flutter_assets', 'assets', 'models', 'gemma'),
        p.join(exe, 'assets', 'models', 'gemma'),
        // dev mode — source tree
        p.join(exe, '..', '..', '..', '..', 'assets', 'models', 'gemma'),
      ];
      for (final dir in candidates) {
        final found = _firstIn(dir);
        if (found != null) return found;
      }
    } else if (Platform.isAndroid) {
      return _copyAndroidAsset();
    }
    return null;
  }

  Future<String?> _copyAndroidAsset() async {
    const candidates = [
      'assets/models/gemma/model.task',
      'assets/models/gemma/model.bin',
    ];
    for (final asset in candidates) {
      try {
        final data = await rootBundle.load(asset);
        final dest = File(p.join(
          await AtlasPackageService.getModelsPath(),
          p.basename(asset),
        ));
        if (!dest.existsSync()) {
          await dest.create(recursive: true);
          await dest.writeAsBytes(data.buffer.asUint8List());
        }
        return dest.path;
      } catch (_) {}
    }
    return null;
  }

  String? _firstIn(String dirPath) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return null;
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => _gemmaExts.any(f.path.toLowerCase().endsWith))
          .toList();
      return files.isEmpty ? null : files.first.path;
    } catch (_) {
      return null;
    }
  }
}

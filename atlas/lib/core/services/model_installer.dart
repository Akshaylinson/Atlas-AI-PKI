import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'atlas_package_service.dart';

/// Gemma-only model formats supported by flutter_gemma / MediaPipe.
const _gemmaExts = ['.task', '.bin'];
const _defaultBundledModelName = 'gemma3-1b-it-int4.task';

class ModelInstaller {
  /// Checks in order:
  ///   1. Local cache (~/.cache/atlas/models/) — fast internal disk
  ///   2. Active Atlas Package models/ directory (pendrive / package)
  ///   3. assets/models/gemma/ bundled with the app binary (desktop)
  ///   4. APK asset bundle copy (Android)
  ///
  /// On first run from pendrive, copies model to local cache for fast loads.
  /// Returns absolute path to first Gemma model found, or null.
  Future<String?> ensureInstalled() async {
    final cached = await _scanLocalCache();
    if (cached != null) return cached;
    final packagePath = await _scanPackageModels();
    if (packagePath != null) {
      // Cache it locally for fast subsequent loads
      final localPath = await _cacheModel(packagePath);
      return localPath ?? packagePath;
    }
    return await _scanBundledAssets();
  }

  Future<String?> _localCacheDir() async {
    try {
      final base = await getApplicationCacheDirectory();
      final dir = Directory(p.join(base.path, 'atlas', 'models'));
      await dir.create(recursive: true);
      return dir.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _scanLocalCache() async {
    final dir = await _localCacheDir();
    if (dir == null) return null;
    return _firstIn(dir);
  }

  Future<String?> _cacheModel(String sourcePath) async {
    try {
      final dir = await _localCacheDir();
      if (dir == null) return null;
      final dest = File(p.join(dir, p.basename(sourcePath)));
      if (dest.existsSync()) return dest.path;
      await File(sourcePath).copy(dest.path);
      return dest.path;
    } catch (_) {
      return null;
    }
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
    final preferredName = await _preferredBundledModelName();
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final exe = p.dirname(Platform.resolvedExecutable);
      final candidates = [
        p.join(exe, 'data', 'flutter_assets', 'assets', 'models', 'gemma'),
        p.join(exe, 'assets', 'models', 'gemma'),
        // dev mode — source tree
        p.join(exe, '..', '..', '..', '..', 'assets', 'models', 'gemma'),
      ];
      for (final dir in candidates) {
        final found = _firstIn(dir, preferredName: preferredName);
        if (found != null) return found;
      }
    } else if (Platform.isAndroid) {
      return _copyAndroidAsset(preferredName: preferredName);
    }
    return null;
  }

  Future<String> _preferredBundledModelName() async {
    try {
      final raw =
          await rootBundle.loadString('assets/models/gemma/metadata.json');
      final meta = jsonDecode(raw);
      if (meta is Map) {
        final assetFile = meta['asset_file']?.toString().trim();
        if (assetFile != null &&
            assetFile.isNotEmpty &&
            _gemmaExts.any(assetFile.toLowerCase().endsWith)) {
          return assetFile;
        }
        final recommended = meta['recommended']?.toString().trim();
        if (recommended != null &&
            recommended.isNotEmpty &&
            _gemmaExts.any(recommended.toLowerCase().endsWith)) {
          return recommended;
        }
      }
    } catch (_) {}
    return _defaultBundledModelName;
  }

  Future<String?> _copyAndroidAsset({required String preferredName}) async {
    final candidates = <String>[
      'assets/models/gemma/$preferredName',
      'assets/models/gemma/$_defaultBundledModelName',
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

  String? _firstIn(String dirPath, {String? preferredName}) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return null;
      final files = dir.listSync(recursive: true).whereType<File>().where((f) {
        return _gemmaExts.any(f.path.toLowerCase().endsWith);
      }).toList();
      if (preferredName != null && preferredName.isNotEmpty) {
        final preferred =
            files.where((f) => p.basename(f.path) == preferredName).toList();
        if (preferred.isNotEmpty) return preferred.first.path;
      }
      return files.isEmpty ? null : files.first.path;
    } catch (_) {
      return null;
    }
  }
}

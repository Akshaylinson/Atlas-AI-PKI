import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'atlas_storage.dart';

const packageExt = '.atlas';

class AtlasPackageService {
  static final _uuid = const Uuid();

  // ── Active package ────────────────────────────────────────────────────────

  static Future<String?> getActivePackageDir() =>
      AtlasStorage.getActivePackageDir();

  static Future<void> setActivePackageDir(String dir) async {
    await AtlasStorage.ensurePackageStructure(dir);
    await AtlasStorage.setActivePackageDir(dir);
  }

  static Future<String> getActiveDatabasePath() => AtlasStorage.getDatabasePath();

  static Future<String> getDatabasePath() => AtlasStorage.getDatabasePath();
  static Future<String> getEmbeddingsPath() => AtlasStorage.getEmbeddingsPath();
  static Future<String> getKnowledgeGraphPath() => AtlasStorage.getKnowledgeGraphPath();
  static Future<String> getPatternsPath() => AtlasStorage.getPatternsPath();
  static Future<String> getAnalyticsPath() => AtlasStorage.getAnalyticsPath();
  static Future<String> getFilesPath() => AtlasStorage.getFilesPath();
  static Future<String> getImagesPath() => AtlasStorage.getImagesPath();
  static Future<String> getAudioPath() => AtlasStorage.getAudioPath();
  static Future<String> getDocumentsPath() => AtlasStorage.getDocumentsPath();
  static Future<String> getVideoPath() => AtlasStorage.getVideoPath();
  static Future<String> getModelsPath() => AtlasStorage.getModelsPath();
  static Future<String> getConfigPath() => AtlasStorage.getConfigPath();
  static Future<String> getCachePath() => AtlasStorage.getCachePath();
  static Future<String> getLogsPath() => AtlasStorage.getLogsPath();

  static Future<String> resolvePath(String path) => AtlasStorage.resolvePath(path);

  static Future<String> relativePathOf(String path) => AtlasStorage.relativePathOf(path);

  static Future<void> beginSession() => AtlasStorage.beginSession();

  static Future<void> endSession() => AtlasStorage.endSession();

  // ── Model handling ────────────────────────────────────────────────────────

  /// Copies a model file into the active package's models/ directory.
  /// Returns a package-relative path.
  static Future<String> installModelFile(String sourcePath) async {
    final modelsDir = await getModelsPath();
    final dest = p.join(modelsDir, p.basename(sourcePath));
    await File(sourcePath).copy(dest);
    return AtlasStorage.relativePathOf(dest);
  }

  // ── Create ────────────────────────────────────────────────────────────────

  static Future<String> createNewPackage(String name) async {
    final appDir = await getApplicationDocumentsDirectory();
    final packagesRoot = Directory(p.join(appDir.path, 'atlas_packages'));
    await packagesRoot.create(recursive: true);

    final safeName = name
        .trim()
        .replaceAll(RegExp(r'[^\w\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final packageId = safeName.isEmpty
        ? 'atlas_${DateTime.now().millisecondsSinceEpoch}'
        : safeName;

    final packageDir = Directory(p.join(packagesRoot.path, packageId));
    await packageDir.create(recursive: true);
    await AtlasStorage.ensurePackageStructure(packageDir.path);

    final now = DateTime.now();
    final manifest = AtlasPackageManifest.fresh(
      packageId: packageId,
      timestamp: now,
    );
    await AtlasStorage.writeManifest(packageDir.path, manifest);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atlas_package_dir', packageDir.path);
    await AtlasStorage.setActivePackageDir(packageDir.path);
    await beginSession();
    return packageDir.path;
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Accepts either a .atlas zip file or an existing package directory path.
  static Future<String> importPackage(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final packagesRoot = Directory(p.join(appDir.path, 'atlas_packages'));
    await packagesRoot.create(recursive: true);

    late final Directory packageDir;
    if (sourcePath.endsWith(packageExt)) {
      final bytes = await File(sourcePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final packageName = p.basenameWithoutExtension(sourcePath).trim();
      final safeName = packageName.isEmpty
          ? 'atlas_${DateTime.now().millisecondsSinceEpoch}'
          : packageName.replaceAll(RegExp(r'[^\w\-]+'), '_');
      packageDir = Directory(p.join(packagesRoot.path, safeName));
      await packageDir.create(recursive: true);

      for (final file in archive) {
        final filePath = p.join(packageDir.path, file.name);
        if (file.isFile) {
          final out = File(filePath);
          await out.create(recursive: true);
          await out.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }
    } else {
      final incoming = Directory(sourcePath);
      final sourceManifest = File(p.join(sourcePath, kAtlasManifestFileName));
      final safeName = sourceManifest.existsSync()
          ? p.basename(sourcePath)
          : 'atlas_${_uuid.v4()}';
      packageDir = Directory(p.join(packagesRoot.path, safeName));
      await packageDir.create(recursive: true);
      await _copyDir(incoming, packageDir);
    }

    await AtlasStorage.ensurePackageStructure(packageDir.path);

    final manifest = await AtlasStorage.readManifest(packageDir.path) ??
        AtlasPackageManifest.fresh(
          packageId: p.basename(packageDir.path),
          timestamp: DateTime.now(),
        );
    await AtlasStorage.writeManifest(
      packageDir.path,
      AtlasPackageManifest(
        atlasVersion: manifest.atlasVersion,
        packageId: manifest.packageId.isEmpty
            ? p.basename(packageDir.path)
            : manifest.packageId,
        packageType: manifest.packageType,
        createdAt: manifest.createdAt,
        updatedAt: DateTime.now(),
        schemaVersion: manifest.schemaVersion,
        minimumRuntimeVersion: manifest.minimumRuntimeVersion,
        memory: manifest.memory,
        data: manifest.data,
        models: manifest.models,
        configuration: manifest.configuration,
      ),
    );

    await AtlasStorage.setActivePackageDir(packageDir.path);
    await beginSession();
    return packageDir.path;
  }

  // ── Export ────────────────────────────────────────────────────────────────

  static Future<String> exportPackage() async {
    final packageDir = await getActivePackageDir();
    if (packageDir == null) throw StateError('No active package');

    final manifest = await AtlasStorage.readManifest(packageDir) ??
        AtlasPackageManifest.fresh(
          packageId: p.basename(packageDir),
          timestamp: DateTime.now(),
        );
    final safeName = manifest.packageId
        .replaceAll(RegExp(r'[^\w\s\-]+'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');

    final appDir = await getApplicationDocumentsDirectory();
    final outPath = p.join(appDir.path, '$safeName$packageExt');

    final encoder = ZipFileEncoder();
    encoder.create(outPath);
    await encoder.addDirectory(Directory(packageDir), includeDirName: false);
    encoder.close();

    return outPath;
  }

  // ── Package info ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPackageMeta() async {
    final dir = await getActivePackageDir();
    if (dir == null) return {};
    final manifest = await AtlasStorage.readManifest(dir);
    return manifest?.toJson() ?? {};
  }

  static Future<AtlasPackageValidationResult> validateActivePackage() async {
    final dir = await getActivePackageDir();
    if (dir == null) {
      return const AtlasPackageValidationResult(
        isValid: false,
        issues: ['No active Atlas package'],
        manifest: null,
      );
    }
    return AtlasStorage.validatePackage(dir);
  }

  static Future<AtlasSessionState?> getSessionState() =>
      AtlasStorage.readSessionState();

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<void> _copyDir(Directory src, Directory dest) async {
    await dest.create(recursive: true);
    await for (final entity in src.list(recursive: false, followLinks: false)) {
      final destPath = p.join(dest.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDir(entity, Directory(destPath));
      } else if (entity is File) {
        await entity.copy(destPath);
      }
    }
  }
}

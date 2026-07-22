import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'atlas_package_dir';
const packageExt = '.atlas';

/// The Atlas Package is a portable directory containing:
///   atlas.db, attachments/, audio/, models/, vectors/, settings.json, meta.json
///
/// It can be zipped into a single .atlas file for sharing/backup/restore.
class AtlasPackageService {
  // ── Active package ────────────────────────────────────────────────────────

  static Future<String?> getActivePackageDir() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = prefs.getString(_prefKey);
    if (dir != null && Directory(dir).existsSync()) return dir;
    return null;
  }

  static Future<void> setActivePackageDir(String dir) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, dir);
  }

  static Future<String> getActiveDatabasePath() async {
    final dir = await getActivePackageDir();
    if (dir == null) throw StateError('No active Atlas package');
    return p.join(dir, 'atlas.db');
  }

  static Future<String> getAttachmentsDir() async {
    final dir = await _requirePackageDir();
    final d = Directory(p.join(dir, 'attachments'));
    await d.create(recursive: true);
    return d.path;
  }

  static Future<String> getAudioDir() async {
    final dir = await _requirePackageDir();
    final d = Directory(p.join(dir, 'audio'));
    await d.create(recursive: true);
    return d.path;
  }

  static Future<String> getModelsDir() async {
    final dir = await _requirePackageDir();
    final d = Directory(p.join(dir, 'models'));
    await d.create(recursive: true);
    return d.path;
  }

  /// Copies a model file into the active package's models/ directory.
  /// Returns the destination path.
  static Future<String> installModelFile(String sourcePath) async {
    final modelsDir = await getModelsDir();
    final dest = p.join(modelsDir, p.basename(sourcePath));
    await File(sourcePath).copy(dest);
    return dest;
  }

  // ── Create ────────────────────────────────────────────────────────────────

  static Future<String> createNewPackage(String name) async {
    final appDir = await getApplicationDocumentsDirectory();
    final packagesRoot = Directory(p.join(appDir.path, 'atlas_packages'));
    await packagesRoot.create(recursive: true);

    final safeName = name.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
    final packageDir = Directory(p.join(packagesRoot.path, safeName));
    await packageDir.create(recursive: true);

    for (final sub in [
      'attachments/images',
      'attachments/documents',
      'attachments/others',
      'audio',
      'models',
      'vectors',
      'patterns',
    ]) {
      await Directory(p.join(packageDir.path, sub)).create(recursive: true);
    }

    await _writeMeta(packageDir.path, name);
    await File(p.join(packageDir.path, 'settings.json'))
        .writeAsString(jsonEncode({}));

    await setActivePackageDir(packageDir.path);
    return packageDir.path;
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Accepts either a .atlas zip file or an existing package directory path.
  static Future<String> importPackage(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final packagesRoot = Directory(p.join(appDir.path, 'atlas_packages'));
    await packagesRoot.create(recursive: true);

    if (sourcePath.endsWith(packageExt)) {
      final bytes = await File(sourcePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final name = p.basenameWithoutExtension(sourcePath);
      final packageDir = Directory(p.join(packagesRoot.path, name));
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
      await setActivePackageDir(packageDir.path);
      return packageDir.path;
    } else {
      // Directory — copy into private storage
      final name = p.basename(sourcePath);
      final packageDir = Directory(p.join(packagesRoot.path, name));
      await _copyDir(Directory(sourcePath), packageDir);
      await setActivePackageDir(packageDir.path);
      return packageDir.path;
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  static Future<String> exportPackage() async {
    final packageDir = await getActivePackageDir();
    if (packageDir == null) throw StateError('No active package');

    final meta = await _readMeta(packageDir);
    final name = (meta['name'] as String? ?? 'MyLife')
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim();

    final docsDir = await getApplicationDocumentsDirectory();
    final outPath = p.join(docsDir.path, '$name$packageExt');

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
    return _readMeta(dir);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<String> _requirePackageDir() async {
    final dir = await getActivePackageDir();
    if (dir == null) throw StateError('No active Atlas package');
    return dir;
  }

  static Future<void> _writeMeta(String packageDir, String name) async {
    final meta = {
      'name': name,
      'version': '1.0.0',
      'created': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
    };
    await File(p.join(packageDir, 'meta.json'))
        .writeAsString(jsonEncode(meta));
  }

  static Future<Map<String, dynamic>> _readMeta(String packageDir) async {
    final f = File(p.join(packageDir, 'meta.json'));
    if (!f.existsSync()) return {};
    return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
  }

  static Future<void> _copyDir(Directory src, Directory dest) async {
    await dest.create(recursive: true);
    await for (final entity in src.list()) {
      final destPath = p.join(dest.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDir(entity, Directory(destPath));
      } else if (entity is File) {
        await entity.copy(destPath);
      }
    }
  }
}

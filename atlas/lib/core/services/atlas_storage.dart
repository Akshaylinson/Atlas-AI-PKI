import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

const String kAtlasActivePackagePrefKey = 'atlas_package_dir';
const String kAtlasManifestFileName = 'atlas-manifest.json';
const String kAtlasSessionLockFileName = 'session.lock';

abstract class AtlasStorageProvider {
  String get packageRoot;

  String get packageRootAbs => p.normalize(packageRoot);

  String resolveRelativePath(String relativePath) {
    final normalized = p.posix.normalize(relativePath.replaceAll('\\', '/'));
    return p.normalize(p.join(packageRootAbs, normalized));
  }

  String relativePathOf(String absolutePath) {
    final relative = p.relative(absolutePath, from: packageRootAbs);
    return p.posix.normalize(relative.replaceAll('\\', '/'));
  }
}

class AtlasPackageStorageProvider extends AtlasStorageProvider {
  @override
  final String packageRoot;

  AtlasPackageStorageProvider(this.packageRoot);
}

class AtlasPackageManifest {
  final String atlasVersion;
  final String packageId;
  final String packageType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;
  final String minimumRuntimeVersion;
  final Map<String, dynamic> memory;
  final Map<String, dynamic> data;
  final Map<String, dynamic> models;
  final Map<String, dynamic> configuration;

  const AtlasPackageManifest({
    required this.atlasVersion,
    required this.packageId,
    required this.packageType,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
    required this.minimumRuntimeVersion,
    required this.memory,
    required this.data,
    required this.models,
    required this.configuration,
  });

  factory AtlasPackageManifest.fresh({
    required String packageId,
    required DateTime timestamp,
  }) {
    return AtlasPackageManifest(
      atlasVersion: '2.0.0',
      packageId: packageId,
      packageType: 'portable_personal_intelligence',
      createdAt: timestamp,
      updatedAt: timestamp,
      schemaVersion: 4,
      minimumRuntimeVersion: '2.0.0',
      memory: const {
        'database': 'memory/atlas.db',
        'embeddings': 'memory/embeddings',
        'knowledge_graph': 'memory/knowledge_graph',
        'relationships': 'memory/relationships',
        'patterns': 'memory/patterns',
        'analytics': 'memory/analytics',
        'decisions': 'memory/decisions',
      },
      data: const {
        'root': 'data',
        'images': 'data/images',
        'audio': 'data/audio',
        'documents': 'data/documents',
        'video': 'data/video',
      },
      models: const {
        'primary': {
          'path': 'models/primary/gemma-3n-E2B-it-int4.task',
          'format': 'task',
        },
        'auxiliary': 'models/auxiliary',
      },
      configuration: const {
        'path': 'config',
      },
    );
  }

  factory AtlasPackageManifest.fromJson(Map<String, dynamic> json) {
    return AtlasPackageManifest(
      atlasVersion: json['atlas_version']?.toString() ?? '2.0.0',
      packageId: json['package_id']?.toString() ?? '',
      packageType:
          json['package_type']?.toString() ?? 'portable_personal_intelligence',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      schemaVersion:
          int.tryParse(json['schema_version']?.toString() ?? '') ?? 4,
      minimumRuntimeVersion:
          json['minimum_runtime_version']?.toString() ?? '2.0.0',
      memory: Map<String, dynamic>.from(json['memory'] as Map? ?? const {}),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      models: Map<String, dynamic>.from(json['models'] as Map? ?? const {}),
      configuration:
          Map<String, dynamic>.from(json['configuration'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'atlas_version': atlasVersion,
        'package_id': packageId,
        'package_type': packageType,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'schema_version': schemaVersion,
        'minimum_runtime_version': minimumRuntimeVersion,
        'memory': memory,
        'data': data,
        'models': models,
        'configuration': configuration,
      };
}

class AtlasPackageValidationResult {
  final bool isValid;
  final List<String> issues;
  final AtlasPackageManifest? manifest;

  const AtlasPackageValidationResult({
    required this.isValid,
    required this.issues,
    required this.manifest,
  });
}

class AtlasSessionState {
  final String host;
  final String sessionId;
  final DateTime startedAt;
  final DateTime? lastTouchedAt;

  const AtlasSessionState({
    required this.host,
    required this.sessionId,
    required this.startedAt,
    this.lastTouchedAt,
  });

  Map<String, dynamic> toJson() => {
        'host': host,
        'session_id': sessionId,
        'started_at': startedAt.toIso8601String(),
        'last_touched_at': lastTouchedAt?.toIso8601String(),
      };

  factory AtlasSessionState.fromJson(Map<String, dynamic> json) {
    return AtlasSessionState(
      host: json['host']?.toString() ?? 'unknown',
      sessionId: json['session_id']?.toString() ?? '',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastTouchedAt: json['last_touched_at'] == null
          ? null
          : DateTime.tryParse(json['last_touched_at'].toString()),
    );
  }
}

class AtlasStorage {
  static AtlasStorageProvider? _provider;
  static AtlasPackageManifest? _manifest;

  static AtlasStorageProvider? get provider => _provider;

  static Future<void> bootstrap() async {
    final envDir = Platform.environment['ATLAS_PACKAGE_ROOT'];
    if (envDir != null && envDir.trim().isNotEmpty) {
      final resolved = p.normalize(envDir.trim());
      final validation = await validatePackage(resolved);
      if (validation.isValid) {
        _provider = AtlasPackageStorageProvider(resolved);
        _manifest = validation.manifest;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kAtlasActivePackagePrefKey, resolved);
        return;
      }
    }

    final activeDir = await getActivePackageDir();
    if (activeDir != null) {
      final validation = await validatePackage(activeDir);
      if (validation.isValid) {
        _provider = AtlasPackageStorageProvider(activeDir);
        _manifest = validation.manifest;
        return;
      }
    }

    final discovered = await discoverPackageRoot();
    if (discovered != null) {
      final validation = await validatePackage(discovered);
      if (validation.isValid) {
        _provider = AtlasPackageStorageProvider(discovered);
        _manifest = validation.manifest;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kAtlasActivePackagePrefKey, discovered);
      }
    }
  }

  static Future<String?> discoverPackageRoot() async {
    final envHint = Platform.environment['ATLAS_PACKAGE_ROOT'];
    if (envHint != null && envHint.trim().isNotEmpty) {
      final resolved = p.normalize(envHint.trim());
      if (await _isValidPackageRoot(resolved)) {
        return resolved;
      }
    }

    final user = Platform.environment['USER'] ??
        Platform.environment['LOGNAME'] ??
        Platform.environment['USERNAME'];
    final searchRoots = <String>[
      if (user != null && user.isNotEmpty) '/run/media/$user',
      if (user != null && user.isNotEmpty) '/media/$user',
      '/run/media',
      '/media',
      '/mnt',
    ];

    for (final root in searchRoots) {
      final found = await _searchForPackageRoot(root);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  static Future<bool> _isValidPackageRoot(String root) async {
    final dir = Directory(root);
    if (!await dir.exists()) return false;
    final validation = await validatePackage(root);
    return validation.isValid;
  }

  static Future<String?> _searchForPackageRoot(String rootDir) async {
    final root = Directory(rootDir);
    if (!await root.exists()) return null;

    final queue = <({Directory dir, int depth})>[(dir: root, depth: 0)];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (current.depth > 4) continue;

      final manifest = File(p.join(current.dir.path, kAtlasManifestFileName));
      if (await manifest.exists()) {
        final validation = await validatePackage(current.dir.path);
        if (validation.isValid) {
          return current.dir.path;
        }
      }

      for (final child
          in current.dir.listSync(followLinks: false).whereType<Directory>()) {
        queue.add((dir: child, depth: current.depth + 1));
      }
    }
    return null;
  }

  static Future<String?> getActivePackageDir() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = prefs.getString(kAtlasActivePackagePrefKey);
    if (dir == null) return null;
    if (!Directory(dir).existsSync()) return null;
    return dir;
  }

  static Future<void> setActivePackageDir(String dir) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAtlasActivePackagePrefKey, dir);
    _provider = AtlasPackageStorageProvider(dir);
    _manifest = await readManifest(dir);
  }

  static Future<void> clearActivePackageDir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kAtlasActivePackagePrefKey);
    _provider = null;
    _manifest = null;
  }

  static Future<AtlasPackageManifest?> readManifest(String packageRoot) async {
    final manifestFile = File(p.join(packageRoot, kAtlasManifestFileName));
    if (await manifestFile.exists()) {
      final decoded = jsonDecode(await manifestFile.readAsString());
      if (decoded is Map<String, dynamic>) {
        return AtlasPackageManifest.fromJson(decoded);
      }
      if (decoded is Map) {
        return AtlasPackageManifest.fromJson(decoded.cast<String, dynamic>());
      }
    }

    final legacyMetaFile = File(p.join(packageRoot, 'meta.json'));
    if (await legacyMetaFile.exists()) {
      final decoded = jsonDecode(await legacyMetaFile.readAsString());
      if (decoded is Map<String, dynamic>) {
        return AtlasPackageManifest.fresh(
          packageId: decoded['name']?.toString().isNotEmpty == true
              ? decoded['name'].toString()
              : p.basename(packageRoot),
          timestamp: DateTime.tryParse(decoded['created']?.toString() ?? '') ??
              DateTime.now(),
        );
      }
      if (decoded is Map) {
        final data = decoded.cast<String, dynamic>();
        return AtlasPackageManifest.fresh(
          packageId: data['name']?.toString().isNotEmpty == true
              ? data['name'].toString()
              : p.basename(packageRoot),
          timestamp: DateTime.tryParse(data['created']?.toString() ?? '') ??
              DateTime.now(),
        );
      }
    }
    return null;
  }

  static AtlasPackageManifest? get cachedManifest => _manifest;

  static Future<AtlasPackageValidationResult> validatePackage(
      String packageRoot) async {
    final issues = <String>[];
    final manifest = await readManifest(packageRoot);

    if (manifest == null) {
      issues.add('Missing atlas-manifest.json');
    } else {
      if (manifest.packageType != 'portable_personal_intelligence') {
        issues.add('Unsupported package type: ${manifest.packageType}');
      }
      if (manifest.schemaVersion <= 0) {
        issues.add('Invalid schema version');
      }
    }

    final requiredDirs = <String>[
      'memory',
      'memory/embeddings',
      'memory/knowledge_graph',
      'memory/relationships',
      'memory/patterns',
      'memory/analytics',
      'memory/decisions',
      'data',
      'data/images',
      'data/audio',
      'data/documents',
      'data/video',
      'models',
      'models/primary',
      'models/auxiliary',
      'config',
      'cache',
      'logs',
    ];

    for (final relative in requiredDirs) {
      final dir = Directory(p.join(packageRoot, relative));
      if (!await dir.exists()) {
        issues.add('Missing directory: $relative');
      }
    }

    final dbPath = p.join(packageRoot, 'memory', 'atlas.db');
    final dbFile = File(dbPath);
    if (!(await dbFile.exists())) {
      final parent = dbFile.parent;
      if (!(await parent.exists())) {
        issues.add('Database parent directory missing');
      }
    }

    return AtlasPackageValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      manifest: manifest,
    );
  }

  static Future<String> getPackageRoot() async {
    final provider = _provider;
    if (provider != null) return provider.packageRoot;
    final active = await getActivePackageDir();
    if (active == null) {
      throw StateError('No active Atlas package');
    }
    _provider = AtlasPackageStorageProvider(active);
    return active;
  }

  static Future<String> getPackageRootOrNull() async {
    final active = await getActivePackageDir();
    if (active == null) {
      throw StateError('No active Atlas package');
    }
    return active;
  }

  static Future<String> resolvePath(String path) async {
    if (path.isEmpty) return path;
    if (p.isAbsolute(path)) return path;
    final root = await getPackageRoot();
    return p
        .normalize(p.join(root, p.posix.normalize(path.replaceAll('\\', '/'))));
  }

  static String resolvePathSync(String path) {
    if (path.isEmpty) return path;
    if (p.isAbsolute(path)) return path;
    final provider = _provider;
    if (provider == null) {
      throw StateError('No active Atlas package');
    }
    return p.normalize(
      p.join(provider.packageRootAbs,
          p.posix.normalize(path.replaceAll('\\', '/'))),
    );
  }

  static Future<String> relativePathOf(String path) async {
    final root = await getPackageRoot();
    if (!p.isAbsolute(path)) {
      return p.posix.normalize(path.replaceAll('\\', '/'));
    }
    return p.posix
        .normalize(p.relative(path, from: root).replaceAll('\\', '/'));
  }

  static String relativePathOfSync(String path) {
    if (!p.isAbsolute(path)) {
      return p.posix.normalize(path.replaceAll('\\', '/'));
    }
    final provider = _provider;
    if (provider == null) {
      throw StateError('No active Atlas package');
    }
    return p.posix.normalize(
      p.relative(path, from: provider.packageRootAbs).replaceAll('\\', '/'),
    );
  }

  static Future<String> getDatabasePath() async {
    final root = await getPackageRoot();
    return p.join(root, 'memory', 'atlas.db');
  }

  static Future<String> getEmbeddingsPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'memory', 'embeddings'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getKnowledgeGraphPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'memory', 'knowledge_graph'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getPatternsPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'memory', 'patterns'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getAnalyticsPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'memory', 'analytics'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getFilesPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'data'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getImagesPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'data', 'images'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getAudioPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'data', 'audio'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getDocumentsPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'data', 'documents'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getVideoPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'data', 'video'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getModelsPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'models'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getConfigPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'config'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getCachePath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'cache'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> getLogsPath() async {
    final root = await getPackageRoot();
    final dir = Directory(p.join(root, 'logs'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<void> ensurePackageStructure(String packageRoot) async {
    for (final relative in [
      'memory/embeddings',
      'memory/knowledge_graph',
      'memory/relationships',
      'memory/patterns',
      'memory/analytics',
      'memory/decisions',
      'data/images',
      'data/audio',
      'data/documents',
      'data/video',
      'models/primary',
      'models/auxiliary',
      'config',
      'cache',
      'logs',
    ]) {
      await Directory(p.join(packageRoot, relative)).create(recursive: true);
    }
  }

  static Future<void> writeManifest(
      String packageRoot, AtlasPackageManifest manifest) async {
    final file = File(p.join(packageRoot, kAtlasManifestFileName));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    await File(p.join(packageRoot, 'meta.json')).writeAsString(
      jsonEncode({
        'name': manifest.packageId,
        'version': manifest.atlasVersion,
        'created': manifest.createdAt.toIso8601String(),
        'updated': manifest.updatedAt.toIso8601String(),
        'appVersion': manifest.atlasVersion,
      }),
    );
  }

  static Future<AtlasSessionState?> readSessionState() async {
    final root = await getPackageRoot();
    final file = File(p.join(root, kAtlasSessionLockFileName));
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is Map<String, dynamic>) {
      return AtlasSessionState.fromJson(decoded);
    }
    if (decoded is Map) {
      return AtlasSessionState.fromJson(decoded.cast<String, dynamic>());
    }
    return null;
  }

  static Future<void> beginSession() async {
    final root = await getPackageRoot();
    final file = File(p.join(root, kAtlasSessionLockFileName));
    final session = AtlasSessionState(
      host: Platform.operatingSystem,
      sessionId: DateTime.now().microsecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      lastTouchedAt: DateTime.now(),
    );
    await file.writeAsString(jsonEncode(session.toJson()));
  }

  static Future<void> endSession() async {
    final root = await getPackageRoot();
    final file = File(p.join(root, kAtlasSessionLockFileName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<AtlasPackageManifest?> manifestForActivePackage() async {
    final root = await getActivePackageDir();
    if (root == null) return null;
    return readManifest(root);
  }
}

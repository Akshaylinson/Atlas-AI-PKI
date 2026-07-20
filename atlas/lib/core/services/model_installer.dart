import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

const _assetBase = 'assets/models/gemma';
const _versionKey = 'installed_gemma_version';

class ModelInstaller {
  /// Ensures the model is installed and up to date.
  /// Returns the installed model.gguf path, or null on failure.
  Future<String?> ensureInstalled() async {
    final bundledVersion = await _bundledVersion();
    final prefs = await SharedPreferences.getInstance();
    final installedVersion = prefs.getString(_versionKey);

    final docsDir = (await getApplicationDocumentsDirectory()).path;
    final modelPath = p.join(docsDir, 'model.gguf');

    final needsInstall = installedVersion != bundledVersion ||
        !File(modelPath).existsSync();

    if (needsInstall) {
      try {
        // Use flutter_gemma's built-in asset installer for the large GGUF
        await FlutterGemmaPlugin.instance.modelManager
            .installModelFromAsset('$_assetBase/model.gguf');

        // Copy the small support files ourselves
        for (final file in ['tokenizer.json', 'config.json', 'metadata.json']) {
          final bytes = await rootBundle.load('$_assetBase/$file');
          await File(p.join(docsDir, file))
              .writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        }

        await prefs.setString(_versionKey, bundledVersion);
      } catch (e) {
        return null;
      }
    }

    return File(modelPath).existsSync() ? modelPath : null;
  }

  Future<String> _bundledVersion() async {
    final raw = await rootBundle.loadString('$_assetBase/metadata.json');
    return (jsonDecode(raw) as Map<String, dynamic>)['version'] as String? ?? '';
  }
}

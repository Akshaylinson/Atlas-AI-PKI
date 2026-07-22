import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'atlas_package_service.dart';

const _assetBase = 'assets/models/gemma';

class ModelInstaller {
  /// Returns the model.gguf path from the active Atlas package's models/ dir,
  /// falling back to the bundled asset support files if needed.
  /// Returns null if no model is found.
  Future<String?> ensureInstalled() async {
    try {
      final modelsDir = await AtlasPackageService.getModelsDir();
      final modelPath = p.join(modelsDir, 'model.gguf');

      if (!File(modelPath).existsSync()) return null;

      // Copy small support files from assets if missing
      for (final file in ['tokenizer.json', 'config.json', 'metadata.json']) {
        final dest = File(p.join(modelsDir, file));
        if (!dest.existsSync()) {
          try {
            final bytes = await rootBundle.load('$_assetBase/$file');
            await dest.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
          } catch (_) {}
        }
      }

      return modelPath;
    } catch (_) {
      return null;
    }
  }

  Future<String> bundledVersion() async {
    try {
      final raw = await rootBundle.loadString('$_assetBase/metadata.json');
      return (jsonDecode(raw) as Map<String, dynamic>)['version'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}

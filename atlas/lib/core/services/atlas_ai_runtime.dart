import 'dart:io';
import 'package:path/path.dart' as p;
import 'host_capability.dart';
import 'model_loader.dart';

/// Abstract AI runtime interface — separates the model from the runtime.
/// Business logic calls AtlasAIRuntime; the concrete implementation is
/// selected by AtlasAIRuntimeManager based on host capabilities.
abstract class AtlasAIRuntime {
  bool get isLoaded;
  bool get isLoading;
  String? get loadError;

  Future<bool> loadModel(String modelPath);
  Future<String> generate(String prompt);
  Future<void> dispose();
}

/// Flutter Gemma runtime — used on Android and as the default fallback.
class FlutterGemmaRuntime implements AtlasAIRuntime {
  final ModelLoader _loader = ModelLoader();

  @override
  bool get isLoaded => _loader.isLoaded;
  @override
  bool get isLoading => _loader.isLoading;
  @override
  String? get loadError => _loader.loadError;

  @override
  Future<bool> loadModel(String modelPath) => _loader.load(modelPath);

  @override
  Future<String> generate(String prompt) => _loader.generate(prompt);

  @override
  Future<void> dispose() => _loader.dispose();
}

/// llama.cpp process-based runtime for Linux (CPU or Vulkan GPU).
/// Expects `llama-cli` to be in the same directory as the app binary,
/// or at the path stored in the LLAMA_CLI_PATH environment variable.
class LlamaCppRuntime implements AtlasAIRuntime {
  final bool _useVulkan;
  String? _modelPath;
  bool _loaded = false;
  bool _loading = false;
  String? _loadError;

  LlamaCppRuntime({required bool useVulkan}) : _useVulkan = useVulkan;

  static String _resolveBinary() {
    final env = Platform.environment['LLAMA_CLI_PATH'];
    if (env != null && env.isNotEmpty && File(env).existsSync()) return env;
    // Look next to the running executable
    final sibling = p.join(p.dirname(Platform.resolvedExecutable), 'llama-cli');
    if (File(sibling).existsSync()) return sibling;
    return 'llama-cli'; // hope it's on PATH
  }

  @override
  bool get isLoaded => _loaded;
  @override
  bool get isLoading => _loading;
  @override
  String? get loadError => _loadError;

  @override
  Future<bool> loadModel(String modelPath) async {
    _loading = true;
    _loadError = null;
    try {
      if (!File(modelPath).existsSync()) {
        throw StateError('Model file not found: $modelPath');
      }
      // Smoke-test: run with 0 tokens to verify the binary + model load
      final binary = _resolveBinary();
      final result = await Process.run(binary, [
        '-m', modelPath,
        '-n', '0',
        '--no-warmup',
        if (_useVulkan) ...['--n-gpu-layers', '99'],
      ]);
      if (result.exitCode != 0) {
        throw StateError('llama-cli smoke-test failed: ${result.stderr}');
      }
      _modelPath = modelPath;
      _loaded = true;
      return true;
    } catch (e) {
      _loadError = e.toString();
      _loaded = false;
      return false;
    } finally {
      _loading = false;
    }
  }

  @override
  Future<String> generate(String prompt) async {
    if (!_loaded || _modelPath == null) throw StateError('Model not loaded');
    final binary = _resolveBinary();
    final result = await Process.run(binary, [
      '-m', _modelPath!,
      '-p', prompt,
      '-n', '512',
      '--temp', '0.7',
      '--repeat-penalty', '1.1',
      '--no-display-prompt',
      if (_useVulkan) ...['--n-gpu-layers', '99'],
    ]);
    if (result.exitCode != 0) {
      throw StateError('llama-cli generation failed: ${result.stderr}');
    }
    return (result.stdout as String).trim();
  }

  @override
  Future<void> dispose() async {
    _loaded = false;
    _modelPath = null;
  }
}

/// Selects the appropriate runtime based on host capabilities.
class AtlasAIRuntimeManager {
  static Future<AtlasAIRuntime> selectRuntimeAsync(
      HostCapabilityProfile profile) async {
    if (Platform.isLinux) {
      final vulkan = await HostCapabilityProfile.detectVulkan();
      return LlamaCppRuntime(useVulkan: vulkan);
    }
    return FlutterGemmaRuntime();
  }

  // Kept for backward compatibility — sync callers get FlutterGemmaRuntime on non-Linux.
  static AtlasAIRuntime selectRuntime(HostCapabilityProfile profile) {
    if (Platform.isLinux) {
      // Vulkan check is async; callers should prefer selectRuntimeAsync.
      // Default to CPU until async result is available.
      return LlamaCppRuntime(useVulkan: false);
    }
    return FlutterGemmaRuntime();
  }
}

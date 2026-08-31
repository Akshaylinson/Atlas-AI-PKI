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

/// Selects the appropriate runtime based on host capabilities.
class AtlasAIRuntimeManager {
  static AtlasAIRuntime selectRuntime(HostCapabilityProfile profile) {
    // Currently only FlutterGemmaRuntime is implemented.
    // Future: add LlamaCppRuntime for Linux/Windows when llama.cpp FFI is wired.
    return FlutterGemmaRuntime();
  }
}

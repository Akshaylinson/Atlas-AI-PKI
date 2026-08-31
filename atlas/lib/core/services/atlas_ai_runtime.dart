import 'host_capability.dart';
import 'model_loader.dart';

/// Abstract AI runtime - separates the model from the provider/runtime.
/// GemmaService calls AtlasAIRuntime; the concrete implementation
/// is selected by AtlasAIRuntimeManager based on host capabilities.
abstract class AtlasAIRuntime {
  bool get isLoaded;
  bool get isLoading;
  String? get loadError;

  Future<bool> loadModel(String modelPath);
  Future<String> generate(String prompt);
  Future<void> dispose();
}

/// Flutter Gemma runtime - uses MediaPipe on-device inference.
/// Supports Gemma .task and .bin model files only.
/// Works on Android (primary) and can run on desktop via flutter_gemma fallback.
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

/// Selects the best available runtime for the detected host.
/// Currently only FlutterGemmaRuntime is implemented.
/// Future: add alternate local or remote providers if needed.
class AtlasAIRuntimeManager {
  static AtlasAIRuntime selectRuntime(HostCapabilityProfile profile) {
    return FlutterGemmaRuntime();
  }
}

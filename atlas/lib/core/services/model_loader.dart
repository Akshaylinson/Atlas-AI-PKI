import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

const supportedGemmaModelExtensions = <String>{'.task', '.bin'};

class ModelLoader {
  InferenceModel? _model;
  bool _loading = false;
  String? _error;

  bool get isLoaded => _model != null;
  bool get isLoading => _loading;
  String? get loadError => _error;

  Future<bool> load(String modelPath) async {
    _loading = true;
    _error = null;
    try {
      final lowerPath = modelPath.toLowerCase();
      if (!supportedGemmaModelExtensions.any(lowerPath.endsWith)) {
        throw ArgumentError(
          'Unsupported model format. Use a .task or .bin file.',
        );
      }

      // Close any existing model first
      await _model?.close();
      _model = null;

      final gemma = FlutterGemmaPlugin.instance;
      await gemma.modelManager.setModelPath(modelPath);
      _model = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        maxTokens: 1024,
        preferredBackend: PreferredBackend.cpu,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      _model = null;
      return false;
    } finally {
      _loading = false;
    }
  }

  Future<String> generate(String prompt) async {
    if (_model == null) throw StateError('Model not loaded');
    // Re-create model if it was closed due to a previous error
    InferenceModelSession? session;
    try {
      session = await _model!.createSession();
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      // Collect streaming tokens with a 60-second timeout
      final buffer = StringBuffer();
      await session
          .getResponseAsync()
          .timeout(const Duration(seconds: 60))
          .forEach(buffer.write);
      final result = buffer.toString().trim();
      return result;
    } finally {
      await session?.close();
    }
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}


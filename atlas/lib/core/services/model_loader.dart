import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';

class ModelLoader {
  InferenceModel? _model;

  bool get isLoaded => _model != null;

  Future<bool> load(String modelPath) async {
    try {
      final gemma = FlutterGemmaPlugin.instance;
      await gemma.modelManager.setModelPath(modelPath);
      _model = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        maxTokens: 2048,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> generate(String prompt) async {
    if (_model == null) throw StateError('Model not loaded');
    final session = await _model!.createSession();
    await session.addQueryChunk(Message(text: prompt, isUser: true));
    final response = await session.getResponse();
    await session.close();
    return response;
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}

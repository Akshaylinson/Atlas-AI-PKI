import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';

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
      final gemma = FlutterGemmaPlugin.instance;
      await gemma.modelManager.setModelPath(modelPath);
      _model = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        maxTokens: 2048,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
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

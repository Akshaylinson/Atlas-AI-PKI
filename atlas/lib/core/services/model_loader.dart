import 'package:flutter/services.dart';

class ModelLoader {
  static const _ch = MethodChannel('com.atlas.atlas/llama');

  bool _loaded = false;
  bool _loading = false;
  String? _error;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;
  String? get loadError => _error;

  Future<bool> load(String modelPath) async {
    _loading = true;
    _error = null;
    try {
      await _ch.invokeMethod('unloadModel');
      final ok = await _ch.invokeMethod<bool>('loadModel', {'path': modelPath});
      _loaded = ok == true;
      if (!_loaded) _error = 'Native model load returned false';
      return _loaded;
    } on PlatformException catch (e) {
      _error = e.message ?? e.code;
      _loaded = false;
      return false;
    } catch (e) {
      _error = e.toString();
      _loaded = false;
      return false;
    } finally {
      _loading = false;
    }
  }

  Future<String> generate(String prompt) async {
    if (!_loaded) throw StateError('Model not loaded');
    try {
      final text = await _ch.invokeMethod<String>(
        'generate',
        {'prompt': prompt, 'maxTokens': 512},
      );
      return (text ?? '').trim();
    } on PlatformException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  Future<void> dispose() async {
    if (_loaded) {
      await _ch.invokeMethod('unloadModel');
      _loaded = false;
    }
  }
}

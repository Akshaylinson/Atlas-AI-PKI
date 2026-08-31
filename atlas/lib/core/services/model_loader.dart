import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

/// Supported Gemma model formats (flutter_gemma / MediaPipe only).
/// GGUF is NOT supported here — Gemma runs via flutter_gemma on-device.
const supportedGemmaModelExtensions = <String>{'.task', '.bin'};

class ModelLoader {
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  _GemmaWorkerClient? _worker;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;
  String? get loadError => _error;

  Future<bool> load(String modelPath) async {
    _loading = true;
    _error = null;
    try {
      final lower = modelPath.toLowerCase();
      if (!supportedGemmaModelExtensions.any(lower.endsWith)) {
        throw ArgumentError(
          'Unsupported format. Gemma local AI requires a .task or .bin file.\n'
          'Download from: https://www.kaggle.com/models/google/gemma/frameworks/tfLite',
        );
      }
      _worker ??= _GemmaWorkerClient();
      await _worker!.load(modelPath);
      _loaded = true;
      return true;
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
    return _worker!.generate(prompt);
  }

  Future<void> dispose() async {
    final w = _worker;
    _worker = null;
    _loaded = false;
    if (w != null) await w.dispose();
  }
}

class _GemmaWorkerClient {
  Isolate? _isolate;
  SendPort? _commandPort;
  final ReceivePort _responsePort = ReceivePort();
  final Map<int, Completer<Object?>> _pending = {};
  StreamSubscription<dynamic>? _sub;
  int _nextId = 0;
  Future<void>? _startup;

  Future<void> _ensureStarted() {
    if (_commandPort != null) return Future.value();
    return _startup ??= _start();
  }

  Future<void> _start() async {
    final token = ServicesBinding.rootIsolateToken;
    if (token == null) throw StateError('Root isolate token unavailable');
    _sub = _responsePort.listen(_onResponse);
    final ready = ReceivePort();
    _isolate = await Isolate.spawn(
      _workerEntry,
      [ready.sendPort, _responsePort.sendPort, token],
      debugName: 'GemmaWorker',
    );
    _commandPort = await ready.first as SendPort;
    ready.close();
  }

  void _onResponse(dynamic msg) {
    if (msg is! List || msg.length < 3) return;
    final id = msg[0] as int;
    final ok = msg[1] as bool;
    final payload = msg[2];
    final c = _pending.remove(id);
    if (c == null) return;
    ok
        ? c.complete(payload)
        : c.completeError(StateError(payload?.toString() ?? 'error'));
  }

  Future<T> _send<T>(String action, [Object? payload]) async {
    await _ensureStarted();
    final id = ++_nextId;
    final c = Completer<Object?>();
    _pending[id] = c;
    _commandPort!.send([id, action, payload]);
    try {
      return await c.future as T;
    } catch (_) {
      _pending.remove(id);
      rethrow;
    }
  }

  Future<void> load(String path) => _send<void>('load', path);
  Future<String> generate(String prompt) => _send<String>('generate', prompt);

  Future<void> dispose() async {
    final port = _commandPort;
    _commandPort = null;
    _startup = null;
    if (port != null) {
      try {
        final id = ++_nextId;
        final c = Completer<Object?>();
        _pending[id] = c;
        port.send([id, 'dispose', null]);
        await c.future;
      } catch (_) {}
    }
    await _sub?.cancel();
    _responsePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _pending.clear();
  }
}

@pragma('vm:entry-point')
Future<void> _workerEntry(List<Object?> args) async {
  final ready = args[0] as SendPort;
  final response = args[1] as SendPort;
  final token = args[2] as RootIsolateToken;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final cmd = ReceivePort();
  final engine = _GemmaEngine();
  ready.send(cmd.sendPort);

  await for (final msg in cmd) {
    if (msg is! List || msg.length < 3) continue;
    final id = msg[0] as int;
    final action = msg[1] as String;
    final payload = msg[2];
    try {
      switch (action) {
        case 'load':
          await engine.load(payload as String);
          response.send([id, true, null]);
        case 'generate':
          final text = await engine.generate(payload as String);
          response.send([id, true, text]);
        case 'dispose':
          await engine.dispose();
          response.send([id, true, null]);
          cmd.close();
          return;
        default:
          response.send([id, false, 'Unknown action: $action']);
      }
    } catch (e, st) {
      response.send([id, false, '$e\n$st']);
    }
  }
}

class _GemmaEngine {
  InferenceModel? _model;

  Future<void> load(String path) async {
    final gemma = FlutterGemmaPlugin.instance;
    await gemma.modelManager.setModelPath(path);
    await _model?.close();
    _model = await _createWithFallbacks(gemma);
  }

  Future<InferenceModel> _createWithFallbacks(FlutterGemmaPlugin gemma) async {
    final backends = <PreferredBackend?>[
      PreferredBackend.gpuMixed,
      PreferredBackend.gpuFloat16,
      PreferredBackend.gpu,
      null,
      PreferredBackend.cpu,
    ];
    Object? last;
    for (final b in backends) {
      try {
        return await gemma.createModel(
          modelType: ModelType.gemmaIt,
          maxTokens: 512,
          preferredBackend: b,
        );
      } catch (e) {
        last = e;
      }
    }
    throw StateError('Failed to load Gemma model: $last');
  }

  Future<String> generate(String prompt) async {
    final model = _model;
    if (model == null) throw StateError('Model not loaded');
    InferenceModelSession? session;
    try {
      session = await model.createSession();
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      final buf = StringBuffer();
      await session
          .getResponseAsync()
          .timeout(const Duration(seconds: 120))
          .forEach(buf.write);
      return buf.toString().trim();
    } finally {
      await session?.close();
    }
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}

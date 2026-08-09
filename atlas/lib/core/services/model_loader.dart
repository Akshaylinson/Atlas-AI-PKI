import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

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
      final lowerPath = modelPath.toLowerCase();
      if (!supportedGemmaModelExtensions.any(lowerPath.endsWith)) {
        throw ArgumentError(
          'Unsupported model format. Use a .task or .bin file.',
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
    final worker = _worker;
    if (worker == null) {
      throw StateError('Model worker not initialized');
    }
    return worker.generate(prompt);
  }

  Future<void> dispose() async {
    final worker = _worker;
    _worker = null;
    _loaded = false;
    if (worker != null) {
      await worker.dispose();
    }
  }
}

class _GemmaWorkerClient {
  Isolate? _isolate;
  SendPort? _commandPort;
  final ReceivePort _responsePort = ReceivePort();
  final Map<int, Completer<Object?>> _pending = {};
  StreamSubscription<dynamic>? _responseSubscription;
  int _nextRequestId = 0;
  Future<void>? _startup;

  Future<void> _ensureStarted() {
    if (_commandPort != null) return Future.value();
    return _startup ??= _start();
  }

  Future<void> _start() async {
    final rootToken = ServicesBinding.rootIsolateToken;
    if (rootToken == null) {
      throw StateError('Root isolate token is unavailable');
    }

    _responseSubscription = _responsePort.listen(_handleResponse);
    final readyPort = ReceivePort();
    _isolate = await Isolate.spawn(
      _gemmaWorkerEntry,
      <Object?>[
        readyPort.sendPort,
        _responsePort.sendPort,
        rootToken,
      ],
      debugName: 'GemmaWorker',
    );
    _commandPort = await readyPort.first as SendPort;
    readyPort.close();
  }

  void _handleResponse(dynamic message) {
    if (message is! List || message.length < 3) return;
    final requestId = message[0] as int;
    final ok = message[1] as bool;
    final payload = message[2];
    final completer = _pending.remove(requestId);
    if (completer == null) return;
    if (ok) {
      completer.complete(payload);
    } else {
      completer.completeError(StateError(payload?.toString() ?? 'Unknown error'));
    }
  }

  Future<T> _send<T>(String action, [Object? payload]) async {
    await _ensureStarted();
    final commandPort = _commandPort;
    if (commandPort == null) {
      throw StateError('Gemma worker is not ready');
    }

    final requestId = ++_nextRequestId;
    final completer = Completer<Object?>();
    _pending[requestId] = completer;
    commandPort.send(<Object?>[requestId, action, payload]);

    try {
      final result = await completer.future;
      return result as T;
    } catch (_) {
      _pending.remove(requestId);
      rethrow;
    }
  }

  Future<void> load(String modelPath) async {
    await _send<void>('load', modelPath);
  }

  Future<String> generate(String prompt) async {
    return _send<String>('generate', prompt);
  }

  Future<void> dispose() async {
    final commandPort = _commandPort;
    _commandPort = null;
    _startup = null;

    if (commandPort != null) {
      try {
        final requestId = ++_nextRequestId;
        final completer = Completer<Object?>();
        _pending[requestId] = completer;
        commandPort.send(<Object?>[requestId, 'dispose', null]);
        await completer.future;
      } catch (_) {
        // Best effort shutdown.
      }
    }

    await _responseSubscription?.cancel();
    _responseSubscription = null;
    _responsePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _pending.clear();
  }
}

@pragma('vm:entry-point')
Future<void> _gemmaWorkerEntry(List<Object?> args) async {
  final readyPort = args[0] as SendPort;
  final responsePort = args[1] as SendPort;
  final rootToken = args[2] as RootIsolateToken;

  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

  final commandPort = ReceivePort();
  final engine = _GemmaWorkerEngine();
  readyPort.send(commandPort.sendPort);

  await for (final message in commandPort) {
    if (message is! List || message.length < 3) continue;

    final requestId = message[0] as int;
    final action = message[1] as String;
    final payload = message[2];

    try {
      switch (action) {
        case 'load':
          await engine.load(payload as String);
          responsePort.send(<Object?>[requestId, true, null]);
          break;
        case 'generate':
          final text = await engine.generate(payload as String);
          responsePort.send(<Object?>[requestId, true, text]);
          break;
        case 'dispose':
          await engine.dispose();
          responsePort.send(<Object?>[requestId, true, null]);
          commandPort.close();
          return;
        default:
          responsePort.send(<Object?>[
            requestId,
            false,
            'Unknown action: $action',
          ]);
      }
    } catch (e, st) {
      responsePort.send(<Object?>[requestId, false, '$e\n$st']);
    }
  }
}

class _GemmaWorkerEngine {
  InferenceModel? _model;

  Future<void> load(String modelPath) async {
    final gemma = FlutterGemmaPlugin.instance;
    await gemma.modelManager.setModelPath(modelPath);

    await _model?.close();
    _model = await gemma.createModel(
      modelType: ModelType.gemmaIt,
      maxTokens: 1024,
      preferredBackend: PreferredBackend.cpu,
    );
  }

  Future<String> generate(String prompt) async {
    final model = _model;
    if (model == null) {
      throw StateError('Model not loaded');
    }

    InferenceModelSession? session;
    try {
      session = await model.createSession();
      await session.addQueryChunk(Message(text: prompt, isUser: true));

      final buffer = StringBuffer();
      await session
          .getResponseAsync()
          .timeout(const Duration(seconds: 60))
          .forEach(buffer.write);
      return buffer.toString().trim();
    } finally {
      await session?.close();
    }
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}

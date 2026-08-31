import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/atlas_storage.dart';
import 'core/services/atlas_ai_runtime.dart';

const _llamaBinary =
    '/home/akshay-linson/Projects/atlas/Atlas-AI-PKI/llama-linux/llama-b10712/llama-cli';
const _defaultModelPath =
    '/home/akshay-linson/Models/Qwen2.5-Omni-3B-Q4_K_M.gguf';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AtlasStorage.bootstrap();

  if (Platform.isLinux) {
    if (File(_llamaBinary).existsSync()) {
      LlamaCppRuntime.binaryPath = _llamaBinary;
    }
    if (File(_defaultModelPath).existsSync()) {
      LlamaCppRuntime.defaultModelPath = _defaultModelPath;
    }
  }

  runApp(const ProviderScope(child: AtlasApp()));
}

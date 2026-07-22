package com.atlas.atlas

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val channel = "com.atlas.atlas/llama"
    private val bridge = LlamaBridge()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadModel" -> {
                        val path = call.argument<String>("path") ?: run {
                            result.error("INVALID_ARG", "path required", null); return@setMethodCallHandler
                        }
                        scope.launch {
                            val ok = bridge.loadModel(path)
                            withContext(Dispatchers.Main) {
                                if (ok) result.success(true)
                                else result.error("LOAD_FAILED", "Failed to load model", null)
                            }
                        }
                    }
                    "generate" -> {
                        val prompt = call.argument<String>("prompt") ?: run {
                            result.error("INVALID_ARG", "prompt required", null); return@setMethodCallHandler
                        }
                        val maxTokens = call.argument<Int>("maxTokens") ?: 512
                        scope.launch {
                            val text = bridge.generate(prompt, maxTokens)
                            withContext(Dispatchers.Main) { result.success(text) }
                        }
                    }
                    "unloadModel" -> {
                        scope.launch {
                            bridge.unloadModel()
                            withContext(Dispatchers.Main) { result.success(null) }
                        }
                    }
                    "isLoaded" -> result.success(bridge.isLoaded())
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        scope.cancel()
        bridge.unloadModel()
        super.onDestroy()
    }
}

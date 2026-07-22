package com.atlas.atlas

class LlamaBridge {
    external fun loadModel(path: String): Boolean
    external fun generate(prompt: String, maxTokens: Int): String
    external fun unloadModel()
    external fun isLoaded(): Boolean

    companion object {
        init { System.loadLibrary("atlas_llama_bridge") }
    }
}

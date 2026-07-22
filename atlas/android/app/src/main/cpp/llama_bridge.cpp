#include <jni.h>
#include <dlfcn.h>
#include <string>
#include <vector>
#include <android/log.h>

#define TAG "AtlasLlama"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// ── llama.cpp opaque types ────────────────────────────────────────────────────
struct llama_model;
struct llama_context;
struct llama_sampler;

struct llama_model_params {
    int32_t n_gpu_layers;
    int32_t split_mode;
    int32_t main_gpu;
    const float* tensor_split;
    const char* rpc_servers;
    void* progress_callback;
    void* progress_callback_user_data;
    void* kv_overrides;
    bool vocab_only;
    bool use_mmap;
    bool use_mlock;
    bool check_tensors;
};

struct llama_context_params {
    uint32_t n_ctx;
    uint32_t n_batch;
    uint32_t n_ubatch;
    uint32_t n_seq_max;
    int32_t  n_threads;
    int32_t  n_threads_batch;
    int32_t  rope_scaling_type;
    int32_t  pooling_type;
    int32_t  attention_type;
    float    rope_freq_base;
    float    rope_freq_scale;
    float    yarn_ext_factor;
    float    yarn_attn_factor;
    float    yarn_beta_fast;
    float    yarn_beta_slow;
    uint32_t yarn_orig_ctx;
    float    defrag_thold;
    void*    cb_eval;
    void*    cb_eval_user_data;
    int32_t  type_k;
    int32_t  type_v;
    bool     logits_all;
    bool     embeddings;
    bool     offload_kqv;
    bool     flash_attn;
    bool     no_perf;
    void*    abort_callback;
    void*    abort_callback_data;
};

struct llama_batch {
    int32_t  n_tokens;
    int32_t* token;
    float*   embd;
    int32_t* pos;
    int32_t* n_seq_id;
    int32_t** seq_id;
    int8_t*  logits;
};

struct llama_sampler_chain_params { bool no_perf; };

// ── Function pointer types ────────────────────────────────────────────────────
typedef void        (*fn_llama_backend_init)();
typedef void        (*fn_llama_backend_free)();
typedef llama_model_params (*fn_llama_model_default_params)();
typedef llama_context_params (*fn_llama_context_default_params)();
typedef llama_model* (*fn_llama_load_model_from_file)(const char*, llama_model_params);
typedef void        (*fn_llama_free_model)(llama_model*);
typedef llama_context* (*fn_llama_new_context_with_model)(llama_model*, llama_context_params);
typedef void        (*fn_llama_free)(llama_context*);
typedef llama_batch (*fn_llama_batch_init)(int32_t, int32_t, int32_t);
typedef void        (*fn_llama_batch_free)(llama_batch);
typedef int32_t     (*fn_llama_tokenize)(const llama_model*, const char*, int32_t, int32_t*, int32_t, bool, bool);
typedef int32_t     (*fn_llama_decode)(llama_context*, llama_batch);
typedef llama_sampler_chain_params (*fn_llama_sampler_chain_default_params)();
typedef llama_sampler* (*fn_llama_sampler_chain_init)(llama_sampler_chain_params);
typedef void        (*fn_llama_sampler_chain_add)(llama_sampler*, llama_sampler*);
typedef llama_sampler* (*fn_llama_sampler_init_greedy)();
typedef int32_t     (*fn_llama_sampler_sample)(llama_sampler*, llama_context*, int32_t);
typedef void        (*fn_llama_sampler_free)(llama_sampler*);
typedef bool        (*fn_llama_token_is_eog)(const llama_model*, int32_t);
typedef int32_t     (*fn_llama_token_to_piece)(const llama_model*, int32_t, char*, int32_t, int32_t, bool);
typedef int32_t     (*fn_llama_n_ctx)(const llama_context*);

// ── State ─────────────────────────────────────────────────────────────────────
static void*           g_lib = nullptr;
static llama_model*    g_model = nullptr;
static llama_context*  g_ctx = nullptr;
static llama_sampler*  g_sampler = nullptr;

static fn_llama_backend_init              f_backend_init;
static fn_llama_backend_free              f_backend_free;
static fn_llama_model_default_params      f_model_default_params;
static fn_llama_context_default_params    f_context_default_params;
static fn_llama_load_model_from_file      f_load_model_from_file;
static fn_llama_free_model                f_free_model;
static fn_llama_new_context_with_model    f_new_context_with_model;
static fn_llama_free                      f_free;
static fn_llama_batch_init                f_batch_init;
static fn_llama_batch_free                f_batch_free;
static fn_llama_tokenize                  f_tokenize;
static fn_llama_decode                    f_decode;
static fn_llama_sampler_chain_default_params f_sampler_chain_default_params;
static fn_llama_sampler_chain_init        f_sampler_chain_init;
static fn_llama_sampler_chain_add         f_sampler_chain_add;
static fn_llama_sampler_init_greedy       f_sampler_init_greedy;
static fn_llama_sampler_sample            f_sampler_sample;
static fn_llama_sampler_free              f_sampler_free;
static fn_llama_token_is_eog              f_token_is_eog;
static fn_llama_token_to_piece            f_token_to_piece;
static fn_llama_n_ctx                     f_n_ctx;

#define LOAD_SYM(name) \
    f_##name = (fn_llama_##name)dlsym(g_lib, "llama_" #name); \
    if (!f_##name) { LOGE("Missing symbol: llama_" #name); return false; }

static bool load_symbols() {
    LOAD_SYM(backend_init)
    LOAD_SYM(backend_free)
    LOAD_SYM(model_default_params)
    LOAD_SYM(context_default_params)
    LOAD_SYM(load_model_from_file)
    LOAD_SYM(free_model)
    LOAD_SYM(new_context_with_model)
    LOAD_SYM(free)
    LOAD_SYM(batch_init)
    LOAD_SYM(batch_free)
    LOAD_SYM(tokenize)
    LOAD_SYM(decode)
    LOAD_SYM(sampler_chain_default_params)
    LOAD_SYM(sampler_chain_init)
    LOAD_SYM(sampler_chain_add)
    LOAD_SYM(sampler_init_greedy)
    LOAD_SYM(sampler_sample)
    LOAD_SYM(sampler_free)
    LOAD_SYM(token_is_eog)
    LOAD_SYM(token_to_piece)
    LOAD_SYM(n_ctx)
    return true;
}

static void unload_all() {
    if (g_sampler) { f_sampler_free(g_sampler); g_sampler = nullptr; }
    if (g_ctx)     { f_free(g_ctx);               g_ctx = nullptr; }
    if (g_model)   { f_free_model(g_model);       g_model = nullptr; }
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_atlas_atlas_LlamaBridge_loadModel(JNIEnv* env, jobject, jstring jpath) {
    if (!g_lib) {
        g_lib = dlopen("libllama.so", RTLD_NOW | RTLD_GLOBAL);
        if (!g_lib) { LOGE("dlopen failed: %s", dlerror()); return JNI_FALSE; }
        if (!load_symbols()) { dlclose(g_lib); g_lib = nullptr; return JNI_FALSE; }
        f_backend_init();
    }

    unload_all();

    const char* path = env->GetStringUTFChars(jpath, nullptr);
    LOGI("Loading model: %s", path);

    auto mp = f_model_default_params();
    mp.n_gpu_layers = 0;
    mp.use_mmap = true;
    mp.use_mlock = false;

    g_model = f_load_model_from_file(path, mp);
    env->ReleaseStringUTFChars(jpath, path);

    if (!g_model) { LOGE("Failed to load model"); return JNI_FALSE; }

    auto cp = f_context_default_params();
    cp.n_ctx = 2048;
    cp.n_batch = 512;
    cp.n_threads = 4;

    g_ctx = f_new_context_with_model(g_model, cp);
    if (!g_ctx) { f_free_model(g_model); g_model = nullptr; LOGE("Failed to create context"); return JNI_FALSE; }

    auto sp = f_sampler_chain_default_params();
    sp.no_perf = true;
    g_sampler = f_sampler_chain_init(sp);
    f_sampler_chain_add(g_sampler, f_sampler_init_greedy());

    LOGI("Model loaded successfully");
    return JNI_TRUE;
}

JNIEXPORT jstring JNICALL
Java_com_atlas_atlas_LlamaBridge_generate(JNIEnv* env, jobject, jstring jprompt, jint maxTokens) {
    if (!g_model || !g_ctx || !g_sampler) {
        return env->NewStringUTF("");
    }

    const char* prompt = env->GetStringUTFChars(jprompt, nullptr);
    int prompt_len = (int)strlen(prompt);

    // Tokenize
    int n_ctx = f_n_ctx(g_ctx);
    std::vector<int32_t> tokens(n_ctx);
    int n_tokens = f_tokenize(g_model, prompt, prompt_len,
                              tokens.data(), n_ctx, true, true);
    env->ReleaseStringUTFChars(jprompt, prompt);

    if (n_tokens < 0 || n_tokens > n_ctx - maxTokens) {
        return env->NewStringUTF("[Prompt too long]");
    }

    // Decode prompt
    auto batch = f_batch_init(n_tokens, 0, 1);
    for (int i = 0; i < n_tokens; i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = i;
        batch.n_seq_id[i] = 1;
        batch.seq_id[i][0] = 0;
        batch.logits[i] = (i == n_tokens - 1) ? 1 : 0;
    }
    batch.n_tokens = n_tokens;

    if (f_decode(g_ctx, batch) != 0) {
        f_batch_free(batch);
        return env->NewStringUTF("[Decode error]");
    }

    // Generate
    std::string result;
    int pos = n_tokens;
    for (int i = 0; i < maxTokens; i++) {
        int32_t token = f_sampler_sample(g_sampler, g_ctx, -1);
        if (f_token_is_eog(g_model, token)) break;

        char piece[128];
        int n = f_token_to_piece(g_model, token, piece, sizeof(piece), 0, true);
        if (n > 0) result.append(piece, n);

        batch.n_tokens = 1;
        batch.token[0] = token;
        batch.pos[0] = pos++;
        batch.n_seq_id[0] = 1;
        batch.seq_id[0][0] = 0;
        batch.logits[0] = 1;

        if (f_decode(g_ctx, batch) != 0) break;
    }

    f_batch_free(batch);
    return env->NewStringUTF(result.c_str());
}

JNIEXPORT void JNICALL
Java_com_atlas_atlas_LlamaBridge_unloadModel(JNIEnv*, jobject) {
    unload_all();
}

JNIEXPORT jboolean JNICALL
Java_com_atlas_atlas_LlamaBridge_isLoaded(JNIEnv*, jobject) {
    return (g_model != nullptr && g_ctx != nullptr) ? JNI_TRUE : JNI_FALSE;
}

} // extern "C"

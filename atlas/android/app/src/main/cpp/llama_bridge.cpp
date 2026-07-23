#include <jni.h>
#include <dlfcn.h>
#include <string>
#include <vector>
#include <cstring>
#include <android/log.h>

#define TAG "AtlasLlama"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// Opaque handle types
struct llama_model;
struct llama_context;
struct llama_sampler;
struct llama_vocab;

// Opaque param blobs — sized generously above the actual binary sizes:
//   llama_model_params:        0x48 bytes (confirmed from disasm)
//   llama_context_params:      0x90 bytes (confirmed from disasm)
//   llama_sampler_chain_params: small
// We declare them as plain byte arrays so the compiler never tries to
// pass/return them in registers — it always uses the hidden-pointer (x8) ABI.
struct llama_model_params        { uint8_t d[128]; };
struct llama_context_params      { uint8_t d[256]; };
struct llama_sampler_chain_params{ uint8_t d[64];  };

// Confirmed field offsets from disassembly of libllama.so (arm64-v8a):
//
// llama_model_params:
//   +0x18  n_gpu_layers  (int32)
//   +0x41  use_mmap      (bool)   strb at [x8+0x41]
//   +0x43  use_mlock     (bool)   (two bools after use_mmap)
//
// llama_context_params:
//   +0x00  n_ctx         (uint32)
//   +0x04  n_batch       (uint32)
//   +0x20  n_threads     (int32)  ldr w8,[x20,#0x20] in llama_init_from_model

#define MP_N_GPU  0x18
#define MP_MMAP   0x41
#define MP_MLOCK  0x43
#define CP_NCTX   0x00
#define CP_BATCH  0x04
#define CP_THRD   0x20

// llama_batch is stable across versions
struct llama_batch {
    int32_t   n_tokens;
    int32_t*  token;
    float*    embd;
    int32_t*  pos;
    int32_t*  n_seq_id;
    int32_t** seq_id;
    int8_t*   logits;
};

// Function pointer types — default_params return structs by value;
// the AArch64 ABI passes a hidden output pointer in x8 automatically
// when the caller's typedef matches the callee's definition.
typedef llama_model_params        (*fn_mp_default)();
typedef llama_context_params      (*fn_cp_default)();
typedef llama_sampler_chain_params(*fn_sp_default)();
typedef llama_model*   (*fn_load_model)(const char*, llama_model_params);
typedef void           (*fn_free_model)(llama_model*);
typedef llama_context* (*fn_new_ctx)(llama_model*, llama_context_params);
typedef void           (*fn_free_ctx)(llama_context*);
typedef void           (*fn_backend_init)();
typedef void           (*fn_backend_free)();
typedef void           (*fn_ggml_backend_load_all)();
typedef llama_batch    (*fn_batch_init)(int32_t, int32_t, int32_t);
typedef void           (*fn_batch_free)(llama_batch);
typedef const llama_vocab* (*fn_get_vocab)(const llama_model*);
typedef int32_t        (*fn_tokenize)(const llama_vocab*, const char*, int32_t,
                                      int32_t*, int32_t, bool, bool);
typedef int32_t        (*fn_decode)(llama_context*, llama_batch);
typedef llama_sampler* (*fn_sc_init)(llama_sampler_chain_params);
typedef void           (*fn_sc_add)(llama_sampler*, llama_sampler*);
typedef llama_sampler* (*fn_s_greedy)();
typedef int32_t        (*fn_s_sample)(llama_sampler*, llama_context*, int32_t);
typedef void           (*fn_s_free)(llama_sampler*);
typedef bool           (*fn_is_eog)(const llama_vocab*, int32_t);
typedef int32_t        (*fn_tok_piece)(const llama_vocab*, int32_t, char*, int32_t, int32_t, bool);
typedef uint32_t       (*fn_n_ctx)(const llama_context*);
typedef void           (*fn_log_set)(void(*)(int32_t, const char*, void*), void*);

static void*          g_lib     = nullptr;
static llama_model*   g_model   = nullptr;
static llama_context* g_ctx     = nullptr;
static llama_sampler* g_sampler = nullptr;

static fn_mp_default    f_mp_default;
static fn_cp_default    f_cp_default;
static fn_sp_default    f_sp_default;
static fn_load_model    f_load_model;
static fn_free_model    f_free_model;
static fn_new_ctx       f_new_ctx;
static fn_free_ctx      f_free_ctx;
static fn_backend_init        f_backend_init;
static fn_backend_free        f_backend_free;
static fn_batch_init    f_batch_init;
static fn_batch_free    f_batch_free;
static fn_get_vocab     f_get_vocab;
static fn_tokenize      f_tokenize;
static fn_decode        f_decode;
static fn_sc_init       f_sc_init;
static fn_sc_add        f_sc_add;
static fn_s_greedy      f_s_greedy;
static fn_s_sample      f_s_sample;
static fn_s_free        f_s_free;
static fn_is_eog        f_is_eog;
static fn_tok_piece     f_tok_piece;
static fn_n_ctx         f_n_ctx;
static fn_log_set       f_log_set;

#define LOAD_SYM(var, sym) \
    var = (decltype(var))dlsym(g_lib, sym); \
    if (!var) { LOGE("Missing symbol: %s", sym); return false; }

static bool load_symbols() {
    LOAD_SYM(f_mp_default,    "llama_model_default_params")
    LOAD_SYM(f_cp_default,    "llama_context_default_params")
    LOAD_SYM(f_sp_default,    "llama_sampler_chain_default_params")
    LOAD_SYM(f_load_model,    "llama_load_model_from_file")
    LOAD_SYM(f_free_model,    "llama_free_model")
    LOAD_SYM(f_new_ctx,       "llama_new_context_with_model")
    LOAD_SYM(f_free_ctx,      "llama_free")
    LOAD_SYM(f_backend_init,  "llama_backend_init")
    LOAD_SYM(f_backend_free,  "llama_backend_free")
    LOAD_SYM(f_batch_init,    "llama_batch_init")
    LOAD_SYM(f_batch_free,    "llama_batch_free")
    LOAD_SYM(f_get_vocab,     "llama_model_get_vocab")
    LOAD_SYM(f_tokenize,      "llama_tokenize")
    LOAD_SYM(f_decode,        "llama_decode")
    LOAD_SYM(f_sc_init,       "llama_sampler_chain_init")
    LOAD_SYM(f_sc_add,        "llama_sampler_chain_add")
    LOAD_SYM(f_s_greedy,      "llama_sampler_init_greedy")
    LOAD_SYM(f_s_sample,      "llama_sampler_sample")
    LOAD_SYM(f_s_free,        "llama_sampler_free")
    LOAD_SYM(f_is_eog,        "llama_vocab_is_eog")
    LOAD_SYM(f_tok_piece,     "llama_token_to_piece")
    LOAD_SYM(f_n_ctx,         "llama_n_ctx")
    f_log_set = (fn_log_set)dlsym(g_lib, "llama_log_set"); // optional
    return true;
}

static void llama_log_cb(int32_t level, const char* text, void*) {
    if (level == 2) LOGE("[llama] %s", text);
    else            LOGI("[llama] %s", text);
}

static void unload_all() {
    if (g_sampler) { f_s_free(g_sampler);   g_sampler = nullptr; }
    if (g_ctx)     { f_free_ctx(g_ctx);      g_ctx     = nullptr; }
    if (g_model)   { f_free_model(g_model);  g_model   = nullptr; }
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_atlas_atlas_LlamaBridge_loadModel(JNIEnv* env, jobject, jstring jpath) {
    if (!g_lib) {
        // Load libs in dependency order, all GLOBAL so symbols are shared
        dlopen("libggml-base.so",   RTLD_NOW | RTLD_GLOBAL);
        dlopen("libggml.so",        RTLD_NOW | RTLD_GLOBAL);
        dlopen("libllama-common.so",RTLD_NOW | RTLD_GLOBAL);
        g_lib = dlopen("libllama.so", RTLD_NOW | RTLD_GLOBAL);
        if (!g_lib) {
            LOGE("dlopen libllama.so failed: %s", dlerror());
            jclass exc = env->FindClass("java/lang/RuntimeException");
            env->ThrowNew(exc, "dlopen libllama.so failed");
            return JNI_FALSE;
        }
        if (!load_symbols()) { dlclose(g_lib); g_lib = nullptr; return JNI_FALSE; }
        if (f_log_set) f_log_set(llama_log_cb, nullptr);

        // Try ggml_backend_load_all from libllama.so first (newer builds bundle it),
        // then fall back to libggml.so, then skip gracefully.
        fn_ggml_backend_load_all f_load_all =
            (fn_ggml_backend_load_all)dlsym(g_lib, "ggml_backend_load_all");
        if (!f_load_all) {
            void* ggml = dlopen("libggml.so", RTLD_NOW | RTLD_GLOBAL);
            if (ggml) f_load_all = (fn_ggml_backend_load_all)dlsym(ggml, "ggml_backend_load_all");
        }
        if (f_load_all) {
            LOGI("Calling ggml_backend_load_all");
            f_load_all();
        } else {
            LOGI("ggml_backend_load_all not found — relying on llama_backend_init");
        }

        // Always call llama_backend_init — it registers CPU backend on older builds
        LOGI("Calling llama_backend_init");
        f_backend_init();
    }

    unload_all();

    const char* path = env->GetStringUTFChars(jpath, nullptr);
    LOGI("Loading model: %s", path);

    // Get default params, then patch only the fields we need
    llama_model_params mp = f_mp_default();
    *reinterpret_cast<int32_t*>(mp.d + MP_N_GPU) = 0; // n_gpu_layers = 0
    mp.d[MP_MMAP]  = 1; // use_mmap  = true
    mp.d[MP_MLOCK] = 0; // use_mlock = false

    g_model = f_load_model(path, mp);
    env->ReleaseStringUTFChars(jpath, path);

    if (!g_model) { LOGE("llama_load_model_from_file returned null"); return JNI_FALSE; }

    llama_context_params cp = f_cp_default();
    *reinterpret_cast<uint32_t*>(cp.d + CP_NCTX)  = 2048;
    *reinterpret_cast<uint32_t*>(cp.d + CP_BATCH)  = 512;
    *reinterpret_cast<int32_t*> (cp.d + CP_THRD)   = 4;

    g_ctx = f_new_ctx(g_model, cp);
    if (!g_ctx) {
        f_free_model(g_model); g_model = nullptr;
        LOGE("llama_new_context_with_model returned null");
        return JNI_FALSE;
    }

    llama_sampler_chain_params sp = f_sp_default();
    g_sampler = f_sc_init(sp);
    f_sc_add(g_sampler, f_s_greedy());

    LOGI("Model loaded successfully");
    return JNI_TRUE;
}

JNIEXPORT jstring JNICALL
Java_com_atlas_atlas_LlamaBridge_generate(JNIEnv* env, jobject, jstring jprompt, jint maxTokens) {
    if (!g_model || !g_ctx || !g_sampler) return env->NewStringUTF("");

    const llama_vocab* vocab = f_get_vocab(g_model);
    const char* prompt = env->GetStringUTFChars(jprompt, nullptr);
    int prompt_len = (int)strlen(prompt);

    int n_ctx = (int)f_n_ctx(g_ctx);
    std::vector<int32_t> tokens(n_ctx);
    int n_tokens = f_tokenize(vocab, prompt, prompt_len, tokens.data(), n_ctx, true, true);
    env->ReleaseStringUTFChars(jprompt, prompt);

    if (n_tokens < 0 || n_tokens > n_ctx - maxTokens) return env->NewStringUTF("[Prompt too long]");

    auto batch = f_batch_init(n_tokens, 0, 1);
    for (int i = 0; i < n_tokens; i++) {
        batch.token[i]     = tokens[i];
        batch.pos[i]       = i;
        batch.n_seq_id[i]  = 1;
        batch.seq_id[i][0] = 0;
        batch.logits[i]    = (i == n_tokens - 1) ? 1 : 0;
    }
    batch.n_tokens = n_tokens;

    if (f_decode(g_ctx, batch) != 0) {
        f_batch_free(batch);
        return env->NewStringUTF("[Decode error]");
    }

    std::string result;
    int pos = n_tokens;
    for (int i = 0; i < maxTokens; i++) {
        int32_t token = f_s_sample(g_sampler, g_ctx, -1);
        if (f_is_eog(vocab, token)) break;

        char piece[128];
        int n = f_tok_piece(vocab, token, piece, sizeof(piece), 0, true);
        if (n > 0) result.append(piece, n);

        batch.n_tokens     = 1;
        batch.token[0]     = token;
        batch.pos[0]       = pos++;
        batch.n_seq_id[0]  = 1;
        batch.seq_id[0][0] = 0;
        batch.logits[0]    = 1;

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
    return (g_model && g_ctx) ? JNI_TRUE : JNI_FALSE;
}

} // extern "C"

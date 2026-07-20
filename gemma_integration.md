# Architecture Update – Local Gemma Model Integration (Option 2A)

## Decision

We have decided to implement the local LLM using **Option 2A – Bundled Model with First-Run Installation**.

This is a **deliberate architectural decision** based on the project's goals.

Project constraints:

* Personal project only
* Completely offline
* No Play Store distribution requirements
* APK size is not a concern
* The LLM is dedicated exclusively to this application
* We are comfortable rebuilding the APK whenever the model is updated

Because of these constraints, there is no need to optimize for Play Store download size or dynamic model downloads.

---

# Model Location

The default Gemma model will be bundled inside the Flutter project.

Example structure:

```text
assets/
└── models/
    └── gemma/
        ├── model.gguf
        ├── tokenizer.json
        ├── config.json
        └── metadata.json
```

The GGUF model is treated as an application asset and shipped together with the APK.

---

# First-Run Installation Flow

The application **must not perform inference directly from the asset**.

Instead, on the first launch:

1. Check whether the model already exists inside the application's internal storage.
2. If it does not exist:

   * Copy the bundled model and supporting files from the assets directory into the application's private storage.
3. Verify that the copy completed successfully.
4. Store the installed model version.
5. Load the model only from the installed location.

Workflow:

```text
App Starts
      │
      ▼
Check Installed Model
      │
      ├── Exists
      │       │
      │       ▼
      │   Load Model
      │
      └── Missing
              │
              ▼
Copy Assets → Internal Storage
              │
              ▼
Verify
              │
              ▼
Load Model
```

This copy operation happens **only once** (or again only if the bundled model version changes).

---

# Runtime Loading

After installation, **all inference must use the installed copy** located in the application's internal storage.

The runtime **must never execute inference directly from the Flutter assets**.

Reason:

Flutter assets are packaged resources and are not intended for repeated high-performance model access.

Loading from internal storage provides:

* faster startup
* memory-mapped file support where available
* better compatibility with GGUF inference libraries
* cleaner runtime architecture

The runtime should always reference:

```text
Internal App Storage
└── models/
    └── gemma/
        ├── model.gguf
        ├── tokenizer.json
        ├── config.json
        └── metadata.json
```

---

# Why This Architecture

This project does **not** need:

* downloadable models
* cloud model management
* Play Store optimization
* runtime model marketplace

Instead, it prioritizes:

* simplicity
* reliability
* offline operation
* maintainability

Whenever the Gemma model needs to be upgraded:

1. Replace the bundled model inside `assets/models/gemma/`.
2. Rebuild the APK.
3. Install the updated APK.
4. On first launch after the update, compare the bundled model version with the installed version.
5. If the bundled version is newer, replace the installed model automatically.

No additional setup is required.

---

# Required Components

Implement the following modules:

### ModelInstaller

Responsibilities:

* Detect whether the model is installed.
* Compare bundled and installed model versions.
* Copy model files from assets to internal storage.
* Verify successful installation.
* Replace older versions when necessary.

---

### ModelLoader

Responsibilities:

* Load the installed GGUF model.
* Initialize the inference runtime.
* Expose the model instance to the AI Runtime.
* Never load directly from Flutter assets.

---

### metadata.json

Store model information separately.

Example:

```json
{
  "name": "Gemma",
  "version": "4.0",
  "context_length": 32768,
  "quantization": "Q4_K_M"
}
```

This allows the application to determine whether an update is required without hardcoding version information.

---

# Final Decision

The application will ship with a bundled Gemma model inside the assets directory.

During the first launch, the model will be copied into the application's private storage and all future inference will use that installed copy.

This architecture provides a dedicated, offline, high-performance AI runtime while keeping the implementation simple and aligned with the goals of this personal project.

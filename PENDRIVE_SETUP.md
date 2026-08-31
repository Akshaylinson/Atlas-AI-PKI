# ATLAS — PENDRIVE SETUP & RUN GUIDE

Everything you need to put Atlas on a pendrive and run it on any Linux machine.

---

## ARCHITECTURE CLARITY FIRST

Before touching anything, understand this mental model:

```
YOUR PENDRIVE
└── Atlas/                          ← ATLAS PACKAGE  (your brain, travels with you)
    ├── atlas-manifest.json         ← identity file, app reads this first
    ├── session.lock                ← written on open, deleted on clean close
    ├── memory/
    │   └── atlas.db                ← ALL your data (entities, events, PKI, patterns)
    ├── data/
    │   ├── images/                 ← your attached images
    │   ├── audio/                  ← your attached audio
    │   ├── documents/              ← your attached documents
    │   └── video/                  ← your attached video
    ├── models/
    │   └── primary/
    │       └── gemma.gguf          ← AI model (travels with you)
    ├── config/
    ├── cache/
    └── logs/

YOUR MACHINE (any Linux PC)
└── atlas-linux-bundle/             ← ATLAS HOST APP  (just an interface, replaceable)
    ├── atlas                       ← the Flutter Linux binary
    └── data/
        └── flutter_assets/
            └── assets/
                └── models/
                    └── gemma/
                        └── gemma.gguf   ← OPTIONAL: model bundled with app
```

**Key rule:**
- The PACKAGE on the pendrive = your persistent identity and data
- The HOST APP on the machine = just a viewer/interface, has no data of its own
- The model can live in EITHER place — the app checks the package first, then the bundled assets

---

## PART 1 — BUILD THE APP (do this once on your dev machine)

### Step 1 — Get dependencies

```bash
cd /home/akshay-linson/Projects/atlas/Atlas-AI-PKI/atlas
flutter pub get
```

### Step 2 — Build the Linux desktop binary

```bash
flutter build linux --release
```

Output will be at:
```
build/linux/x64/release/bundle/
├── atlas                    ← main binary
├── lib/                     ← shared libraries
└── data/
    └── flutter_assets/      ← all assets including model slot
```

### Step 3 — Copy the built bundle to the pendrive

Plug in your pendrive. It will mount at something like `/media/akshay-linson/YOURPENDRIVE/`

```bash
# Create the app folder on the pendrive
mkdir -p /media/akshay-linson/YOURPENDRIVE/atlas-app

# Copy the entire built bundle
cp -r build/linux/x64/release/bundle/* /media/akshay-linson/YOURPENDRIVE/atlas-app/

# Make the binary executable
chmod +x /media/akshay-linson/YOURPENDRIVE/atlas-app/atlas
```

---

## PART 2 — SET UP THE ATLAS PACKAGE ON THE PENDRIVE

The Atlas Package is your data. It lives separately from the app.

### Option A — Let the app create it (easiest)

1. Run the app (see Part 3)
2. On first launch you see "Welcome to Atlas"
3. Type a name like `MyAtlas` and tap **Create & Start**
4. The app creates the package in `~/Documents/atlas_packages/MyAtlas/`
5. Then go to **Settings → Switch Package**
6. Pick a folder ON THE PENDRIVE instead

### Option B — Create the package folder manually on the pendrive

```bash
PENDRIVE=/media/akshay-linson/YOURPENDRIVE

mkdir -p $PENDRIVE/Atlas/memory/embeddings
mkdir -p $PENDRIVE/Atlas/memory/knowledge_graph
mkdir -p $PENDRIVE/Atlas/memory/relationships
mkdir -p $PENDRIVE/Atlas/memory/patterns
mkdir -p $PENDRIVE/Atlas/memory/analytics
mkdir -p $PENDRIVE/Atlas/memory/decisions
mkdir -p $PENDRIVE/Atlas/data/images
mkdir -p $PENDRIVE/Atlas/data/audio
mkdir -p $PENDRIVE/Atlas/data/documents
mkdir -p $PENDRIVE/Atlas/data/video
mkdir -p $PENDRIVE/Atlas/models/primary
mkdir -p $PENDRIVE/Atlas/models/auxiliary
mkdir -p $PENDRIVE/Atlas/config
mkdir -p $PENDRIVE/Atlas/cache
mkdir -p $PENDRIVE/Atlas/logs

# Create the manifest
cat > $PENDRIVE/Atlas/atlas-manifest.json << 'EOF'
{
  "atlas_version": "2.0.0",
  "package_id": "MyAtlas",
  "package_type": "portable_personal_intelligence",
  "created_at": "2025-01-01T00:00:00.000Z",
  "updated_at": "2025-01-01T00:00:00.000Z",
  "schema_version": 4,
  "minimum_runtime_version": "2.0.0",
  "memory": {
    "database": "memory/atlas.db",
    "embeddings": "memory/embeddings",
    "knowledge_graph": "memory/knowledge_graph",
    "relationships": "memory/relationships",
    "patterns": "memory/patterns",
    "analytics": "memory/analytics",
    "decisions": "memory/decisions"
  },
  "data": {
    "root": "data",
    "images": "data/images",
    "audio": "data/audio",
    "documents": "data/documents",
    "video": "data/video"
  },
  "models": {
    "primary": {
      "path": "models/primary/model.gguf",
      "format": "gguf"
    },
    "auxiliary": "models/auxiliary"
  },
  "configuration": {
    "path": "config"
  }
}
EOF
```

---

## PART 3 — PLACE THE AI MODEL

You have two options for where the model lives:

### Option A — Model inside the Atlas Package (RECOMMENDED for pendrive use)

```bash
# Copy your model into the package on the pendrive
cp /path/to/gemma-2b-it-q4_k_m.gguf \
   /media/akshay-linson/YOURPENDRIVE/Atlas/models/primary/

# Then in the app: Settings → AI Model → Browse
# Navigate to: /media/akshay-linson/YOURPENDRIVE/Atlas/models/primary/gemma-2b-it-q4_k_m.gguf
```

This way the model travels with your data. Plug into any machine, everything works.

### Option B — Model bundled with the app binary (for fixed machines)

```bash
# Copy model into the app's assets folder BEFORE building
cp /path/to/gemma-2b-it-q4_k_m.gguf \
   /home/akshay-linson/Projects/atlas/Atlas-AI-PKI/atlas/assets/models/gemma/

# Then rebuild
flutter build linux --release

# The app will auto-detect it at startup via ModelInstaller
```

### Where to get a model

For Linux desktop (`.gguf` format):
- https://huggingface.co/google/gemma-2-2b-it-GGUF
- Recommended file: `gemma-2-2b-it-Q4_K_M.gguf` (~1.5 GB, good balance)
- Minimum RAM needed: 4 GB

For Android (`.task` format):
- https://www.kaggle.com/models/google/gemma/frameworks/tfLite
- Pick: `gemma-2b-it-gpu-int4.bin` or `gemma-2b-it-cpu-int4.bin`

---

## PART 4 — RUN THE APP

### Run from pendrive on any Linux machine

```bash
# Plug in pendrive, then:
cd /media/akshay-linson/YOURPENDRIVE/atlas-app

# Run it
./atlas
```

If it says "permission denied":
```bash
chmod +x ./atlas
./atlas
```

### Run in development mode (from source)

```bash
cd /home/akshay-linson/Projects/atlas/Atlas-AI-PKI/atlas
flutter run -d linux
```

### Run on Android

```bash
cd /home/akshay-linson/Projects/atlas/Atlas-AI-PKI/atlas
flutter run  # with Android device connected via USB
```

---

## PART 5 — FIRST LAUNCH FLOW

```
App starts
    │
    ▼
AtlasStorage.bootstrap() runs
    │
    ├── Found saved package path? ──YES──► Validate it ──VALID──► Open MainShell
    │                                                  └─INVALID──► PackageSetupScreen
    │
    └── No saved path? ──────────────────────────────────────────► PackageSetupScreen
                                                                         │
                                                              ┌──────────┴──────────┐
                                                              ▼                     ▼
                                                       Create New              Import Existing
                                                       (type a name)           (pick .atlas file
                                                                                or folder)
```

On first launch on a new machine with your pendrive:
1. App opens → PackageSetupScreen appears
2. Tap **"Import Existing Package"**
3. Navigate to your pendrive → select the `Atlas/` folder
4. App loads all your data, PKI, patterns, everything

---

## PART 6 — COMPLETE PENDRIVE LAYOUT

This is what your pendrive should look like when fully set up:

```
PENDRIVE/
│
├── atlas-app/                          ← HOST APP (the Flutter binary)
│   ├── atlas                           ← run this
│   ├── lib/
│   │   ├── libflutter_linux.so
│   │   └── ...
│   └── data/
│       └── flutter_assets/
│           └── assets/
│               └── models/
│                   └── gemma/
│                       └── metadata.json
│
└── Atlas/                              ← ATLAS PACKAGE (your data)
    ├── atlas-manifest.json
    ├── session.lock                    ← only exists while app is open
    ├── memory/
    │   ├── atlas.db                    ← your entire knowledge base
    │   ├── embeddings/
    │   ├── knowledge_graph/
    │   ├── relationships/
    │   ├── patterns/
    │   ├── analytics/
    │   └── decisions/
    ├── data/
    │   ├── images/
    │   ├── audio/
    │   ├── documents/
    │   └── video/
    ├── models/
    │   └── primary/
    │       └── gemma-2b-it-Q4_K_M.gguf   ← AI model
    ├── config/
    ├── cache/
    └── logs/
```

---

## PART 7 — MOVING TO A NEW MACHINE

```bash
# On the new machine, plug in pendrive
# Find where it mounted:
lsblk
# or
ls /media/$(whoami)/

# Run the app directly from pendrive
/media/$(whoami)/YOURPENDRIVE/atlas-app/atlas

# On first launch → Import Existing Package
# → navigate to /media/$(whoami)/YOURPENDRIVE/Atlas/
# → everything loads
```

---

## PART 8 — SAFE SHUTDOWN (IMPORTANT)

**Never just unplug the pendrive while the app is open.**

The app writes `session.lock` while open. Always:

1. Close the app normally (window close button)
2. The app calls `endSession()` which deletes `session.lock`
3. Wait for the app to fully close
4. Then safely eject:

```bash
# Safely eject the pendrive
udisksctl unmount -b /dev/sdX
udisksctl power-off -b /dev/sdX
# Then physically unplug
```

If you see `session.lock` still in the Atlas folder after closing, the app crashed. On next open it will detect this and warn you. The database uses SQLite WAL mode so data is safe.

---

## PART 9 — EXPORT / BACKUP

To create a portable `.atlas` zip backup:

In the app: **Settings → Export Package**

This creates a `.atlas` file (zip) you can store anywhere. To restore:

In the app: **Settings → Import Package** → pick the `.atlas` file

---

## QUICK REFERENCE

| Task | Command / Action |
|---|---|
| Build app | `flutter build linux --release` |
| Copy to pendrive | `cp -r build/linux/x64/release/bundle/* /media/.../atlas-app/` |
| Run from pendrive | `./atlas` (from atlas-app folder) |
| Run in dev | `flutter run -d linux` |
| First launch on new machine | Import Existing Package → pick Atlas/ folder on pendrive |
| Place model (package) | Copy `.gguf` to `Atlas/models/primary/` |
| Place model (bundled) | Copy `.gguf` to `atlas/assets/models/gemma/` then rebuild |
| Safe eject | Close app → `udisksctl unmount -b /dev/sdX` |
| Backup | Settings → Export Package |

---

## CURRENT STATUS — YOUR MACHINE

- Flutter: 3.47.0 ✓
- Target: Linux desktop (Ubuntu 26.04) ✓
- Pendrive: Not currently mounted (plug it in, it will appear under `/media/akshay-linson/`)
- Model: Not yet placed — download from HuggingFace (link above)

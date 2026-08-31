# ATLAS - PENDRIVE SETUP & RUN GUIDE

This guide shows how to keep Atlas portable on a USB drive and run it on Linux with the new launcher flow.

## Architecture

Atlas now uses two separate pieces on the pendrive:

- `atlas-app/` = the host app bundle
- `Atlas/` = the persistent package with your data, configuration, and model

The launcher at the USB root sets `ATLAS_PACKAGE_ROOT` so the app opens the USB package automatically.

```
YOUR PENDRIVE
├── run_atlas.sh                    ← launcher
├── atlas-app/                      ← host app bundle
│   ├── atlas
│   └── data/
│       └── flutter_assets/
│           └── assets/
│               └── models/
│                   └── gemma/
│                       └── gemma-3n-E2B-it-int4.task   ← optional bundled model
└── Atlas/                          ← your portable package
    ├── atlas-manifest.json
    ├── session.lock
    ├── memory/
    │   └── atlas.db
    ├── data/
    │   ├── images/
    │   ├── audio/
    │   ├── documents/
    │   └── video/
    ├── models/
    │   └── primary/
    │       └── gemma-3n-E2B-it-int4.task
    ├── config/
    ├── cache/
    └── logs/
```

## Key Rules

- The package on the pendrive is the persistent identity.
- The host app is replaceable.
- The launcher points Atlas to the USB package.
- The model can live in either place, but the package copy is preferred.

## Step 1 - Build the Linux app

From the Flutter project root:

```bash
cd /home/akshay-linson/Projects/atlas/Atlas-AI-PKI/atlas
flutter pub get
flutter build linux --release
```

The release bundle is created at:

```text
build/linux/x64/release/bundle/
```

## Step 2 - Copy the app bundle to the pendrive

Plug in the USB drive and find its mount point. In this setup it is mounted at:

```text
/run/media/akshay-linson/UBUNTU 26_0
```

Then copy the Linux bundle:

```bash
cp -r /home/akshay-linson/Projects/atlas/Atlas-AI-PKI/atlas/build/linux/x64/release/bundle/. \
  "/run/media/akshay-linson/UBUNTU 26_0/atlas-app/"
chmod +x "/run/media/akshay-linson/UBUNTU 26_0/atlas-app/atlas"
```

## Step 3 - Add the launcher

Copy the launcher to the pendrive root:

```bash
cp /home/akshay-linson/Projects/atlas/Atlas-AI-PKI/run_atlas.sh \
  "/run/media/akshay-linson/UBUNTU 26_0/"
chmod +x "/run/media/akshay-linson/UBUNTU 26_0/run_atlas.sh"
```

## Step 4 - Create the Atlas package structure

If the package does not already exist, create it on the USB:

```bash
PENDRIVE="/run/media/akshay-linson/UBUNTU 26_0"

mkdir -p "$PENDRIVE/Atlas/memory/embeddings"
mkdir -p "$PENDRIVE/Atlas/memory/knowledge_graph"
mkdir -p "$PENDRIVE/Atlas/memory/relationships"
mkdir -p "$PENDRIVE/Atlas/memory/patterns"
mkdir -p "$PENDRIVE/Atlas/memory/analytics"
mkdir -p "$PENDRIVE/Atlas/memory/decisions"
mkdir -p "$PENDRIVE/Atlas/data/images"
mkdir -p "$PENDRIVE/Atlas/data/audio"
mkdir -p "$PENDRIVE/Atlas/data/documents"
mkdir -p "$PENDRIVE/Atlas/data/video"
mkdir -p "$PENDRIVE/Atlas/models/primary"
mkdir -p "$PENDRIVE/Atlas/models/auxiliary"
mkdir -p "$PENDRIVE/Atlas/config"
mkdir -p "$PENDRIVE/Atlas/cache"
mkdir -p "$PENDRIVE/Atlas/logs"
```

Create the manifest:

```bash
cat > "$PENDRIVE/Atlas/atlas-manifest.json" << 'EOF'
{
  "atlas_version": "2.0.0",
  "package_id": "Atlas",
  "package_type": "portable_personal_intelligence",
  "created_at": "2026-08-31T00:00:00.000Z",
  "updated_at": "2026-08-31T00:00:00.000Z",
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
      "path": "models/primary/gemma-3n-E2B-it-int4.task",
      "format": "task"
    },
    "auxiliary": "models/auxiliary"
  },
  "configuration": {
    "path": "config"
  }
}
EOF
```

## Step 5 - Put the model in the package

Recommended:

```bash
cp /path/to/gemma-3n-E2B-it-int4.task \
  "/run/media/akshay-linson/UBUNTU 26_0/Atlas/models/primary/"
```

This is the preferred portable setup because the model travels with your data.

Optional bundled copy:

```bash
cp /path/to/gemma-3n-E2B-it-int4.task \
  /home/akshay-linson/Projects/atlas/Atlas-AI-PKI/atlas/assets/models/gemma/
flutter build linux --release
```

## Step 6 - Run Atlas from the pendrive

From the pendrive root:

```bash
cd "/run/media/akshay-linson/UBUNTU 26_0"
./run_atlas.sh
```

If needed:

```bash
chmod +x ./run_atlas.sh
./run_atlas.sh
```

The launcher sets `ATLAS_PACKAGE_ROOT` and starts the host app.

## First Launch Flow

```text
Plug in pendrive
    ↓
Run ./run_atlas.sh
    ↓
Atlas opens
    ↓
Boot checks ATLAS_PACKAGE_ROOT
    ↓
Validate /Atlas
    ↓
Open MainShell if valid
    ↓
Show PackageSetupScreen only if missing or invalid
```

## Complete USB Layout

```text
PENDRIVE/
├── run_atlas.sh
├── atlas-app/
│   ├── atlas
│   ├── lib/
│   └── data/
│       └── flutter_assets/
└── Atlas/
    ├── atlas-manifest.json
    ├── session.lock
    ├── memory/
    │   └── atlas.db
    ├── data/
    ├── models/
    │   └── primary/
    │       └── gemma-3n-E2B-it-int4.task
    ├── config/
    ├── cache/
    └── logs/
```

## Moving To A New Machine

```bash
# Plug in the USB drive
cd "/run/media/$(whoami)/UBUNTU 26_0"
./run_atlas.sh
```

Atlas should open the USB package automatically.

## Safe Shutdown

Never unplug the drive while Atlas is open.

1. Close the app normally.
2. Let `session.lock` be removed.
3. Eject the USB safely.

```bash
udisksctl unmount -b /dev/sdX
udisksctl power-off -b /dev/sdX
```

## Quick Reference

| Task | Command |
|---|---|
| Build app | `flutter build linux --release` |
| Copy app | `cp -r build/linux/x64/release/bundle/. /run/media/.../atlas-app/` |
| Copy launcher | `cp run_atlas.sh /run/media/.../` |
| Run from USB | `./run_atlas.sh` |
| Put model in package | `Atlas/models/primary/gemma-3n-E2B-it-int4.task` |
| Put model in app bundle | `atlas/assets/models/gemma/gemma-3n-E2B-it-int4.task` |
| Safe eject | Close Atlas, then unmount and power off the drive |


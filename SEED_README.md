# Atlas Seed Data

Test data script for the Atlas app. **Never ship this data to production.**

## What it inserts

| Table              | Count  |
|--------------------|--------|
| Entities           | 12     |
| Events             | ~155   |
| Relationships      | 14     |
| Patterns           | 6      |
| Entity Statistics  | 12     |
| Embeddings         | ~155   |

Data spans **120 days**. Every seeded row is tagged with `"SEED"` so it can be
wiped cleanly without touching any real user data.

## Requirements

- Python 3.8+
- `adb` in your PATH (Android Debug Bridge — comes with Android SDK)
- App installed and device/emulator connected with USB debugging on

## Commands

```bash
# Populate the connected device
python seed_data.py push

# Wipe all seeded rows from the device (leaves real user data untouched)
python seed_data.py clean

# Just generate atlas_seed.db locally (no device needed)
python seed_data.py local
```
set ADB_PATH=E:\Android\Sdk\platform-tools\adb.exe && set PYTHONIOENCODING=utf-8 && python seed_data.py push

## How it works

1. `push` — builds a local SQLite file, pushes it to `/data/local/tmp/` via ADB,
   then uses `run-as com.atlas.atlas sqlite3` to merge it into the live app DB.
2. `clean` — deletes every row whose `tags` column contains `"SEED"`, then
   cascade-deletes orphaned relationships, statistics, and embeddings.
3. `local` — writes `atlas_seed.db` in the project root for inspection with any
   SQLite browser (e.g. DB Browser for SQLite).

## Removing before release

Just run `python seed_data.py clean` and delete `seed_data.py` and this file.

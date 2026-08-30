# ATLAS — PORTABLE PERSONAL INTELLIGENCE SYSTEM

## COMPLETE ARCHITECTURE UPGRADE & IMPLEMENTATION PROMPT

You are upgrading an existing project called **ATLAS**.

This is NOT a new application built from scratch.

A substantial part of the existing ATLAS system already works, including:

* Flutter UI
* Drift database
* Entity management
* Event recording
* Personal Knowledge Index (PKI)
* Entity extraction
* Relationship extraction
* Embeddings
* Pattern detection
* Statistics
* Retrieval engine
* Keyword search
* Semantic search
* Analytics engine
* Adaptive analytics
* Decision intelligence
* File storage
* Knowledge graph
* Seed data system
* Settings
* Local AI architecture placeholder

The purpose of this upgrade is to fundamentally evolve ATLAS from a **device-bound mobile application** into a **portable, offline-first personal intelligence system**.

---

# 1. NEW CORE DEFINITION OF ATLAS

ATLAS must now be officially designed as:

> **ATLAS is a portable, offline-first personal intelligence system. The Atlas Package contains the user's persistent memory, knowledge graph, data, AI models, configuration, and compatible runtimes. Atlas can connect to compatible host devices, temporarily borrowing their computational resources while keeping the user's intelligence and persistent data independent of any single device.**

The most important architectural principle is:

# THE DEVICE IS NOT ATLAS.

The device is only a temporary computational host.

The persistent ATLAS identity belongs to the user and travels independently of devices.

---

# 2. CORE MENTAL MODEL

The architecture should follow this model:

```text
                  ┌───────────────────────┐
                  │                       │
                  │     ATLAS PACKAGE     │
                  │                       │
                  │  Persistent Identity  │
                  │  Personal Memory      │
                  │  Knowledge Graph      │
                  │  AI Models            │
                  │  Personal Files       │
                  │  Patterns             │
                  │  Analytics            │
                  │  Configuration        │
                  │                       │
                  └───────────┬───────────┘
                              │
                       Connected to
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
       Android              Linux              Windows
          │                   │                   │
          ▼                   ▼                   ▼
     Temporary Host     Temporary Host     Temporary Host
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                              ▼
                       HOST RESOURCES

                    CPU / RAM / GPU
                    Display / Input
```

The host provides computing resources.

The ATLAS Package provides identity and persistent intelligence.

---

# 3. ABSOLUTE ARCHITECTURAL PRINCIPLE

The persistent personal intelligence system must NOT permanently belong to:

* one phone
* one laptop
* one operating system
* one installation
* one application sandbox

Instead:

```text
OLD ARCHITECTURE

Phone
 └── ATLAS
      ├── Database
      ├── Files
      ├── AI
      └── Knowledge


NEW ARCHITECTURE

ATLAS PACKAGE
 ├── Database
 ├── Files
 ├── Knowledge
 ├── Models
 ├── Patterns
 ├── Embeddings
 └── Configuration

        │
        ▼

Temporary Host Device
 ├── Android
 ├── Linux
 └── Windows
```

The host should be replaceable.

The ATLAS Package should preserve continuity.

---

# 4. DO NOT REBUILD WORKING INTELLIGENCE

Before modifying anything, audit the existing project.

Preserve and migrate the existing:

* Entity system
* Event system
* Drift schema
* Existing database
* PKI pipeline
* Embedding system
* Retrieval system
* Analytics engine
* Adaptive analytics engine
* Decision intelligence
* Pattern detection
* Knowledge graph
* File storage
* Existing UI functionality
* Seed data functionality

Do NOT replace real functionality with placeholders.

Do NOT create fake demo implementations.

Do NOT hardcode sample data.

The objective is:

> **Change where and how ATLAS persists and loads its intelligence—not destroy the intelligence architecture that already exists.**

---

# 5. CREATE THE ATLAS PACKAGE STANDARD

Create a formal portable package structure.

The root folder represents one complete ATLAS identity.

Example:

```text
ATLAS/
│
├── atlas-manifest.json
│
├── core/
│   │
│   ├── schemas/
│   ├── prompts/
│   ├── intelligence/
│   └── defaults/
│
├── memory/
│   │
│   ├── atlas.db
│   │
│   ├── embeddings/
│   │
│   ├── knowledge_graph/
│   │
│   ├── relationships/
│   │
│   ├── patterns/
│   │
│   ├── analytics/
│   │
│   └── decisions/
│
├── data/
│   │
│   ├── images/
│   ├── audio/
│   ├── documents/
│   └── video/
│
├── models/
│   │
│   ├── primary/
│   │   └── model.gguf
│   │
│   └── auxiliary/
│
├── apps/
│   │
│   ├── android/
│   │   └── atlas.apk
│   │
│   ├── linux/
│   │
│   └── windows/
│
├── runtimes/
│   │
│   ├── linux/
│   │   ├── x86_64/
│   │   └── arm64/
│   │
│   ├── windows/
│   │
│   └── android/
│
├── config/
│
├── cache/
│
└── logs/
```

The exact structure may be refined during implementation, but the conceptual separation must remain.

---

# 6. ATLAS PACKAGE COMPONENTS

## A. atlas-manifest.json

This is the identity and discovery file.

Every ATLAS-compatible application must be able to locate this file.

Example:

```json
{
  "atlas_version": "1.0.0",
  "package_id": "unique-atlas-id",
  "package_type": "portable_personal_intelligence",

  "created_at": "",
  "updated_at": "",

  "memory": {
    "database": "memory/atlas.db",
    "embeddings": "memory/embeddings",
    "knowledge_graph": "memory/knowledge_graph",
    "patterns": "memory/patterns"
  },

  "data": {
    "root": "data",
    "images": "data/images",
    "audio": "data/audio",
    "documents": "data/documents"
  },

  "models": {
    "primary": {
      "path": "models/primary/model.gguf",
      "format": "gguf"
    }
  },

  "configuration": {
    "path": "config"
  }
}
```

Do not rely on hardcoded absolute paths.

Everything should be discoverable relative to the package root.

---

# 7. CREATE A STORAGE ABSTRACTION LAYER

This is one of the most important upgrades.

Currently, parts of the application may directly use paths such as:

```dart
getApplicationDocumentsDirectory()
```

This architecture must be removed from business logic.

The application must never directly assume where persistent data lives.

Create a centralized abstraction.

Conceptually:

```text
AtlasStorage
        │
        ├── Database Provider
        │
        ├── File Provider
        │
        ├── Model Provider
        │
        ├── Configuration Provider
        │
        └── Cache Provider
```

Suggested interface:

```text
AtlasStorageProvider

getPackageRoot()

getDatabasePath()

getEmbeddingsPath()

getKnowledgeGraphPath()

getPatternsPath()

getAnalyticsPath()

getFilesPath()

getImagesPath()

getAudioPath()

getDocumentsPath()

getModelsPath()

getConfigPath()

getCachePath()
```

The rest of the application should ask the storage provider.

Example:

```text
AtlasStorage.getDatabasePath()
```

NOT:

```text
Hardcoded Android documents directory
```

---

# 8. STORAGE PROVIDERS

Implement storage providers appropriate for each environment.

Conceptually:

```text
AtlasStorageProvider
│
├── InternalStorageProvider
│
├── AtlasPackageStorageProvider
│
├── LinuxPortableStorageProvider
│
├── WindowsPortableStorageProvider
│
└── AndroidAtlasStorageProvider
```

The UI, database, PKI, analytics, and AI systems should not care which provider is active.

They should only receive valid paths.

---

# 9. ATLAS PACKAGE DISCOVERY

Create an Atlas Package Discovery system.

When ATLAS starts, it should be able to determine:

```text
Where is the Atlas Package?
```

Boot flow:

```text
Application Starts
       │
       ▼
Atlas Package Discovery
       │
       ▼
Find atlas-manifest.json
       │
       ├── Found
       │      │
       │      ▼
       │   Validate Package
       │
       └── Not Found
              │
              ▼
       Ask user to create/open ATLAS
```

Validation should check:

* Manifest exists
* Manifest version supported
* Database path exists or can be created
* Required directories exist
* Package structure is valid
* Database integrity
* Storage permissions
* Model availability

---

# 10. ATLAS BOOT SEQUENCE

Implement a clear startup architecture.

```text
1. START HOST APPLICATION
        │
        ▼
2. DETECT PLATFORM
        │
        ▼
3. DETECT ATLAS PACKAGE
        │
        ▼
4. LOAD atlas-manifest.json
        │
        ▼
5. VALIDATE PACKAGE
        │
        ├── Database
        ├── Files
        ├── Configuration
        └── Model
        │
        ▼
6. INITIALIZE STORAGE PROVIDER
        │
        ▼
7. OPEN ATLAS DATABASE
        │
        ▼
8. INITIALIZE FILE STORAGE
        │
        ▼
9. INITIALIZE PKI
        │
        ▼
10. LOAD ANALYTICS STATE
        │
        ▼
11. DETECT HOST CAPABILITIES
        │
        ├── CPU
        ├── RAM
        ├── GPU
        ├── Architecture
        └── OS
        │
        ▼
12. SELECT AI RUNTIME
        │
        ▼
13. LOAD MODEL WHEN REQUIRED
        │
        ▼
14. ATLAS READY
```

The application should expose a clean boot status.

---

# 11. HOST CAPABILITY DETECTION

ATLAS should understand the host device.

Create a Host Capability Profile.

Example:

```text
HostCapabilityProfile

Operating System

Architecture

CPU Cores

Available RAM

GPU Available

GPU Type

Storage Access

USB Access

AI Runtime Compatibility
```

Example:

```json
{
  "os": "linux",
  "architecture": "x86_64",
  "cpu_cores": 8,
  "ram_gb": 16,
  "gpu_available": true,
  "gpu_type": "NVIDIA",
  "ai_runtime": "llama_cpp_cuda"
}
```

This information should be used to select the best compatible runtime.

---

# 12. RUNTIME ABSTRACTION

Do NOT tie the entire AI system to one platform.

Create an AI runtime abstraction.

Conceptually:

```text
AtlasAIEngine
       │
       ├── Android Runtime
       │
       ├── Linux CPU Runtime
       │
       ├── Linux GPU Runtime
       │
       ├── Windows CPU Runtime
       │
       └── Windows GPU Runtime
```

The higher-level application should simply call:

```text
AtlasAI.generate()
```

The runtime manager determines:

```text
Which engine should execute this?
```

---

# 13. MODEL MANAGEMENT

AI models belong conceptually to the ATLAS Package.

Example:

```text
ATLAS/
└── models/
    ├── primary/
    │   └── gemma.gguf
    │
    └── auxiliary/
```

However, do not assume that every platform can directly execute the same runtime binary.

The model is portable.

The runtime is platform-dependent.

Architecture:

```text
ATLAS MODEL

      │

      ▼

Runtime Manager

      │

      ├── Android Runtime
      │
      ├── Linux Runtime
      │
      └── Windows Runtime

      │

      ▼

HOST CPU / RAM / GPU
```

---

# 14. IMPORTANT MODEL LOADING RULE

The AI model should not be permanently copied into random host locations.

Preferred behavior:

```text
ATLAS Package
     │
     ▼
Model File
     │
     ▼
Compatible Runtime
     │
     ▼
Host RAM
     │
     ▼
Inference
```

Temporary runtime caching is acceptable where required.

But the canonical model belongs to the ATLAS Package.

---

# 15. DATABASE ARCHITECTURE

Continue using the existing Drift/SQLite architecture unless there is a strong technical reason to change it.

Do NOT migrate to JSON simply to make the data portable.

SQLite is actually a strong fit because:

* single portable database file
* transactional
* indexed
* reliable
* scalable
* easy to move
* works offline
* supports complex queries
* suitable for long-term data

The canonical database should live conceptually here:

```text
ATLAS/memory/atlas.db
```

The database is part of the ATLAS identity.

---

# 16. DO NOT BREAK DATABASE PORTABILITY

The database path must become configurable.

The database must not assume:

```text
Android sandbox path
```

Instead:

```text
AtlasStorageProvider
        │
        ▼
ATLAS PACKAGE
        │
        ▼
memory/atlas.db
```

The same database should theoretically be understandable across supported platforms.

Use migrations carefully.

Never silently destroy data.

---

# 17. FILE STORAGE ARCHITECTURE

Attachments must also become portable.

Current architecture may look like:

```text
Application Storage
├── images
├── audio
└── files
```

Upgrade to:

```text
ATLAS/
└── data/
    ├── images/
    ├── audio/
    ├── documents/
    └── video/
```

Database records should preferably reference files relative to the ATLAS Package.

Example:

```text
data/images/event_001.jpg
```

NOT:

```text
/storage/emulated/0/Android/data/...
```

This is extremely important.

Absolute device paths destroy portability.

---

# 18. RELATIVE PATH RULE

All persistent paths inside ATLAS should use relative references.

Example:

```text
GOOD

data/images/image001.jpg


BAD

/home/user/Desktop/atlas/data/images/image001.jpg
```

The Atlas Package root can change.

The internal structure must remain portable.

---

# 19. PERSONAL KNOWLEDGE INDEX

Preserve the PKI architecture.

When a new event is created:

```text
EVENT SAVED
      │
      ▼
Entity Extraction
      │
      ▼
Relationship Detection
      │
      ▼
Embedding Generation
      │
      ▼
Knowledge Graph Update
      │
      ▼
Statistics Update
      │
      ▼
Pattern Detection
      │
      ▼
Confidence Update
      │
      ▼
Analytics Refresh
```

The only change is that persistent outputs must be stored inside the ATLAS Package.

---

# 20. ATLAS MEMORY STRUCTURE

Conceptually:

```text
ATLAS MEMORY
│
├── Raw Memory
│   ├── Entities
│   ├── Events
│   └── Decisions
│
├── Structured Memory
│   ├── Relationships
│   ├── Knowledge Graph
│   └── Statistics
│
├── Semantic Memory
│   └── Embeddings
│
├── Analytical Memory
│   ├── Patterns
│   ├── Trends
│   └── Insights
│
└── Decision Memory
    ├── Decisions
    ├── Expectations
    ├── Outcomes
    └── Reviews
```

This entire intelligence structure belongs to the ATLAS Package.

---

# 21. PACKAGE OWNERSHIP PRINCIPLE

Define two types of storage.

## Persistent Storage

Belongs to ATLAS:

```text
Database
Entities
Events
Knowledge Graph
Embeddings
Patterns
Analytics
Decisions
Attachments
Models
Configuration
```

## Temporary Storage

Belongs to the Host:

```text
Runtime Cache
Temporary Thumbnails
Temporary Model Cache
Temporary Processing Files
Logs if configured
```

The application must clearly separate these.

---

# 22. SESSION LIFECYCLE

When ATLAS connects to a host:

```text
CONNECT
   │
   ▼
DISCOVER PACKAGE
   │
   ▼
VALIDATE
   │
   ▼
OPEN DATABASE
   │
   ▼
START SESSION
   │
   ▼
USE HOST RESOURCES
   │
   ▼
SAVE ALL CHANGES
   │
   ▼
FLUSH DATABASE
   │
   ▼
COMPLETE BACKGROUND TASKS
   │
   ▼
CLEAR TEMP CACHE
   │
   ▼
CLOSE DATABASE
   │
   ▼
SAFE TO DISCONNECT
```

Never assume a USB device can simply be removed while the database is actively writing.

Implement safe shutdown procedures.

---

# 23. SAFE EJECTION

Create a proper session shutdown system.

Before disconnecting:

```text
Atlas Session Shutdown

✓ Pending events saved

✓ Database flushed

✓ PKI jobs completed or queued

✓ File writes completed

✓ Analytics state saved

✓ Cache cleared

✓ Database closed

SAFE TO DISCONNECT
```

The UI should clearly communicate this.

---

# 24. IMPORTANT WARNING ABOUT USB REMOVAL

Design for unexpected disconnection.

Potential risks:

* database corruption
* incomplete file writes
* interrupted PKI processing

Implement protection strategies.

Consider:

* SQLite transactions
* Write-ahead logging where appropriate
* Atomic file writes
* Temporary files + rename
* Processing job checkpoints
* Startup integrity checks
* Recovery mechanism

Never assume clean shutdown.

---

# 25. ATLAS PACKAGE VERSIONING

Implement package versioning.

Example:

```json
{
  "atlas_version": "1.0.0",
  "schema_version": 1,
  "minimum_runtime_version": "1.0.0"
}
```

Future versions must support migrations.

Example:

```text
ATLAS Package v1

       │

       ▼

New ATLAS Runtime

       │

       ▼

Check Compatibility

       │

       ▼

Migration Required?

       │

   YES ─────────► Backup Transaction
       │
       ▼
Migration
       │
       ▼
Validate
```

Never silently perform destructive migrations.

---

# 26. PACKAGE INTEGRITY

Add integrity checks.

Potential metadata:

```text
Database Version

Package Version

Last Clean Shutdown

Last Opened

Last Modified

Integrity Status
```

Optional future architecture:

```text
Checksums
```

for critical files.

Do not overcomplicate the first implementation, but design the manifest to support future integrity validation.

---

# 27. PACKAGE LOCKING

Consider preventing accidental simultaneous access.

Example problem:

```text
Computer A
      │
      └── Opens Atlas.db

Computer B
      │
      └── Opens same Atlas.db
```

This can cause problems.

For Version 1:

ATLAS should assume one active host session.

Create:

```text
session.lock
```

or equivalent session metadata.

Example:

```json
{
  "host": "Linux",
  "started_at": "",
  "session_id": ""
}
```

On startup:

```text
Lock exists?

YES
 │
 ├── Previous crash?
 │
 └── Active session?
```

Provide recovery behavior.

---

# 28. ATLAS HOST APPLICATIONS

The UI should remain primarily Flutter.

The same Flutter codebase should be reused as much as possible.

Target:

```text
ATLAS Flutter UI
        │
        ├── Android
        │
        ├── Linux
        │
        └── Windows
```

But platform-specific integration should be isolated.

Do not scatter:

```dart
if (Platform.isAndroid)
```

throughout business logic.

Create platform adapters.

---

# 29. PLATFORM ADAPTER ARCHITECTURE

Suggested:

```text
PlatformServices
│
├── Storage Adapter
│
├── USB Adapter
│
├── Runtime Adapter
│
├── Hardware Capability Adapter
│
└── File Access Adapter
```

Each platform implements its own adapter.

Business logic communicates through interfaces.

---

# 30. ANDROID ARCHITECTURE

Android requires special treatment.

Do NOT assume arbitrary executables can simply run directly from USB storage.

Android should use:

```text
ATLAS ANDROID HOST APP
         │
         │ USB / OTG
         ▼
ATLAS PACKAGE
```

The installed Android application provides:

* UI
* USB access
* Storage access
* Host capability detection
* Runtime integration
* AI execution bridge

The ATLAS Package provides persistent identity.

---

# 31. ANDROID FIRST CONNECTION FLOW

Conceptually:

```text
Open ATLAS Android App

       │

       ▼

No Active Atlas Found

       │

       ▼

[ Connect Atlas Package ]

       │

       ▼

USB / OTG File Access

       │

       ▼

Select ATLAS Root

       │

       ▼

Find atlas-manifest.json

       │

       ▼

Validate Package

       │

       ▼

Open ATLAS
```

Do not assume unrestricted raw filesystem access.

Use Android-supported storage APIs.

---

# 32. LINUX PORTABLE MODE

Linux should be the first fully portable proof of concept.

Target experience:

```bash
./atlas
```

The launcher should:

```text
Locate Package Root

↓

Inspect Linux Architecture

↓

Select Runtime

↓

Open Database

↓

Start Flutter Application

↓

Initialize AI Runtime

↓

ATLAS Ready
```

The Linux implementation should prove that ATLAS can genuinely operate independently of installation-specific data.

---

# 33. WINDOWS MODE

Architecture should mirror Linux conceptually.

```text
Atlas.exe

↓

Discover Atlas Package Root

↓

Initialize Storage

↓

Detect Host

↓

Select Runtime

↓

Open Atlas
```

Avoid hardcoding Windows paths.

---

# 34. DO NOT SHIP EVERYTHING AS ONE EXECUTABLE

The architecture should distinguish:

```text
ATLAS PACKAGE
```

from:

```text
ATLAS HOST APPLICATION
```

The package is persistent intelligence.

The host application is an interface/runtime capable of opening the package.

This distinction is important.

---

# 35. UPDATED APPLICATION UI CONCEPT

The UI should communicate portability.

ATLAS should have a subtle status:

```text
ATLAS

● Connected

Portable Intelligence
```

or:

```text
ATLAS PACKAGE

Connected

128 GB Available
Last synced locally: Now
```

Do not make USB management the central UI.

It should remain mostly invisible.

The user should experience ATLAS as a continuous personal intelligence system.

---

# 36. SETTINGS — NEW PORTABILITY SECTION

Add:

## ATLAS PACKAGE

Display:

```text
Package Name

Package ID

Version

Storage Location

Database Size

Media Size

Model Size

Total Intelligence Size

Last Clean Shutdown

Package Integrity
```

Actions:

```text
Open Package

Validate Package

Safe Disconnect

Optimize Storage

Package Information
```

---

# 37. DATA SIZE ANALYTICS

Because ATLAS grows over years, show storage growth.

Example:

```text
ATLAS GROWTH

Memory
1.2 GB

Media
8.4 GB

Models
3.1 GB

Knowledge Index
450 MB

Total
13.15 GB
```

Also show growth over time.

This reinforces the philosophy:

> Your intelligence system grows as your recorded knowledge grows.

---

# 38. CREATE / OPEN ATLAS EXPERIENCE

On first launch, support:

```text
WELCOME TO ATLAS

Create New Atlas

or

Open Existing Atlas
```

Create New:

```text
Choose Storage Location

↓

Create Atlas Package

↓

Generate Package ID

↓

Create Directory Structure

↓

Create Database

↓

Create Manifest

↓

Initialize Knowledge Index

↓

ATLAS Ready
```

Open Existing:

```text
Select Atlas Root

↓

Find Manifest

↓

Validate

↓

Open Database

↓

Load Intelligence

↓

ATLAS Ready
```

---

# 39. EXISTING USER MIGRATION

The existing Android application already contains data.

Do NOT lose it.

Create a migration tool.

Flow:

```text
Existing Atlas App

Database
Files
Embeddings
Patterns

        │

        ▼

EXPORT TO ATLAS PACKAGE

        │

        ▼

Create Portable Structure

        │

        ▼

Copy Database

Copy Attachments

Copy Intelligence Data

Create Manifest

        │

        ▼

VALIDATE

        │

        ▼

PORTABLE ATLAS CREATED
```

This is mandatory before switching architecture.

---

# 40. SEED DATA ARCHITECTURE

Seed data should no longer be treated as normal application assets after initialization.

Support three concepts:

## A. Development Seed

Used for testing.

```text
seed/
```

Can create test entities/events.

## B. New Atlas Template

Used when creating a new Atlas.

May contain:

* schema
* defaults
* configuration

Should NOT automatically mix test data into real user intelligence.

## C. Existing Atlas Memory

The actual persistent personal data.

Never overwrite this automatically.

---

# 41. SEED DATA REQUIREMENTS

Provide explicit actions:

```text
Load Development Seed Data

Clear Development Seed Data

Create Empty Atlas

Import Existing Atlas
```

Seed data must be identifiable.

Do not create a system where deleting seed data accidentally deletes real data.

---

# 42. ADAPTIVE ANALYTICS ENGINE

Preserve the adaptive analytics concept.

The AI must NOT generate arbitrary executable code and run it unrestricted.

Continue the safe architecture:

```text
User Question

↓

Intent Analysis

↓

Analytics Requirement

↓

Analytics DSL / Query Plan

↓

Validation

↓

Approved Analytics Operations

↓

Execution

↓

Results

↓

AI Interpretation
```

Do not regress to unsafe arbitrary code execution.

The analytics engine should remain data-driven and extensible.

---

# 43. AI RESPONSE REQUIREMENTS

ATLAS AI should provide:

* evidence
* counts
* percentages
* trends
* comparisons
* patterns
* confidence
* source events

Avoid unsupported absolute statements.

Preferred:

```text
Based on 24 similar events:

17 had positive outcomes
5 had neutral outcomes
2 had negative outcomes

Observed success rate:
70.8%

Confidence:
Medium

Reason:
Sample size is moderate.
```

Not:

```text
You should definitely do this.
```

The user's historical data is evidence.

The user makes decisions.

---

# 44. PERSONAL KNOWLEDGE INDEX UPDATE

Every event continues to update the PKI.

```text
EVENT CREATED

↓

Save Event

↓

Extract Entities

↓

Update Relationships

↓

Generate Embedding

↓

Update Statistics

↓

Detect Pattern Changes

↓

Update Confidence

↓

Refresh Relevant Analytics

↓

Commit Changes to ATLAS Package
```

The final commit must be safely persisted.

---

# 45. PERFORMANCE RULE

Do not load the entire ATLAS database into memory.

Even though the storage is portable:

```text
ATLAS Package

        │

        ▼

Query Required Data

        │

        ▼

Process

        │

        ▼

Return Result
```

Use:

* indexed database queries
* lazy loading
* pagination
* caching
* isolates
* background workers

The package may eventually contain decades of data.

Design accordingly.

---

# 46. LARGE DATA DESIGN

ATLAS should be designed for:

```text
10 years

50,000+ events

10,000+ entities

Large attachment collections

Thousands of decisions

Large knowledge graph

Multiple AI models
```

Do not optimize only for demo-sized data.

---

# 47. HOST TEMPORARY CACHE

Hosts may use temporary cache.

Example:

```text
/tmp/atlas/

model_cache/

thumbnails/

processing/

temporary_embeddings/
```

Rules:

* Never treat host cache as canonical memory.
* Clear sensitive temporary data where practical.
* Never silently leave permanent copies.
* ATLAS Package remains the source of truth.

---

# 48. LOGGING

Separate logs into:

## Persistent Atlas Logs

Optional diagnostic history.

```text
ATLAS/logs/
```

## Temporary Host Logs

Debug/runtime logs.

Should not necessarily remain permanently.

Never store sensitive personal content unnecessarily in logs.

---

# 49. ERROR RECOVERY

Implement recovery scenarios.

Examples:

### Database damaged

```text
Integrity Check

↓

Attempt Recovery

↓

Report Status
```

### USB disconnected unexpectedly

```text
Session Interrupted

↓

Do Not Write Further

↓

Wait for Reconnection

↓

Run Integrity Check

↓

Resume / Recover
```

### Model unavailable

The application must still work.

Only AI features degrade.

Core:

* entities
* events
* database
* retrieval
* analytics

should remain usable where possible.

---

# 50. OFFLINE-FIRST REQUIREMENT

ATLAS must function without:

* cloud
* backend
* internet
* user accounts
* API keys
* remote databases

Internet connectivity must never be required for core operation.

The primary architecture is:

```text
LOCAL DATA

+

LOCAL PROCESSING

+

LOCAL AI

=

ATLAS
```

---

# 51. PRIVACY PRINCIPLE

ATLAS should assume personal data is sensitive.

Core philosophy:

> The user's life data belongs to the user and remains physically under their control.

Do not silently upload:

* events
* entities
* embeddings
* relationships
* decisions
* files
* analytics

No cloud dependency should be introduced without explicit future design decisions.

---

# 52. UPDATED SYSTEM ARCHITECTURE

The final architecture should look conceptually like:

```text
                        USER
                         │
                         ▼
              ┌─────────────────────┐
              │   ATLAS HOST APP    │
              │                     │
              │ Flutter UI          │
              │ Navigation          │
              │ Visualization       │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │   ATLAS CORE API    │
              │                     │
              │ Entities            │
              │ Events              │
              │ Decisions           │
              │ Retrieval           │
              │ Analytics           │
              │ PKI                 │
              └──────────┬──────────┘
                         │
          ┌──────────────┼───────────────┐
          │              │               │
          ▼              ▼               ▼
      Storage         AI Engine      Host Manager
      Manager                          │
          │              │             │
          │              │             ▼
          │              │        CPU / RAM / GPU
          │              │
          ▼              ▼
     ATLAS PACKAGE    AI MODEL
          │
          ├── Database
          ├── Files
          ├── Embeddings
          ├── Knowledge Graph
          ├── Patterns
          ├── Decisions
          ├── Configuration
          └── Models
```

---

# 53. PROJECT RESTRUCTURING

Reorganize the codebase logically.

Suggested conceptual architecture:

```text
lib/

├── app/
│
├── core/
│   ├── storage/
│   ├── platform/
│   ├── package/
│   ├── runtime/
│   └── configuration/
│
├── data/
│   ├── database/
│   ├── repositories/
│   └── file_storage/
│
├── intelligence/
│   ├── pki/
│   ├── retrieval/
│   ├── analytics/
│   ├── decisions/
│   ├── patterns/
│   └── ai/
│
├── features/
│   ├── dashboard/
│   ├── entities/
│   ├── events/
│   ├── decisions/
│   ├── insights/
│   ├── search/
│   └── settings/
│
├── services/
│
└── ui/
    ├── theme/
    ├── components/
    └── layouts/
```

Do not blindly move files if doing so risks breaking working systems.

Refactor incrementally.

---

# 54. IMPLEMENTATION PHASES

Do NOT attempt one giant rewrite.

Follow these phases.

---

## PHASE 0 — AUDIT

Before changing code:

* Inspect architecture.
* Identify database paths.
* Identify file storage paths.
* Identify model paths.
* Identify platform dependencies.
* Identify assumptions about Android storage.
* Map existing services.

Produce an internal migration map.

---

## PHASE 1 — STORAGE ABSTRACTION

Create:

```text
AtlasStorageProvider
```

Move all persistent path logic into it.

Do not change functionality yet.

Ensure existing Android application still works.

---

## PHASE 2 — ATLAS PACKAGE

Implement:

* Package root
* Manifest
* Directory creation
* Package validation
* Relative paths
* Package metadata

Test locally.

---

## PHASE 3 — DATABASE MIGRATION

Move database initialization from fixed application storage to configurable Atlas Storage.

Ensure:

* existing data works
* migrations work
* transactions work
* integrity remains intact

---

## PHASE 4 — FILE MIGRATION

Move attachment architecture.

Ensure all database references become portable.

Use relative paths.

---

## PHASE 5 — EXISTING DATA EXPORT

Create:

```text
Convert Existing Atlas → Portable Atlas Package
```

Validate that:

* entities survive
* events survive
* decisions survive
* relationships survive
* files survive
* embeddings survive
* analytics survive

---

## PHASE 6 — PACKAGE DISCOVERY

Implement:

```text
Create Atlas

Open Atlas

Validate Atlas

Close Atlas
```

---

## PHASE 7 — HOST CAPABILITY SYSTEM

Implement:

```text
HostCapabilityProfile
```

Detect:

* OS
* architecture
* CPU
* RAM
* GPU

---

## PHASE 8 — AI RUNTIME MANAGER

Separate:

```text
Model
```

from:

```text
Runtime
```

Implement runtime selection architecture.

Do not necessarily implement every platform runtime immediately.

---

## PHASE 9 — LINUX PROOF OF CONCEPT

Make ATLAS genuinely portable on Linux first.

Test:

```text
USB

↓

Connect

↓

Launch Atlas

↓

Open existing data

↓

Add event

↓

Run PKI

↓

Run analytics

↓

Close

↓

Move USB

↓

Reconnect

↓

Open same intelligence
```

This is the first major milestone.

---

## PHASE 10 — ANDROID PACKAGE MODE

Adapt the Flutter Android application into an Atlas Host.

Support USB/OTG package selection using Android-supported APIs.

Do not assume unrestricted filesystem execution.

---

## PHASE 11 — SAFE SESSION MANAGEMENT

Implement:

* session state
* locking
* clean shutdown
* recovery
* integrity checks

---

## PHASE 12 — UI UPDATE

Add:

* Atlas Package status
* Connected storage
* Package information
* Host capability information
* Safe disconnect
* Storage growth
* Package validation

Do not overwhelm normal users with technical details.

---

# 55. TESTING REQUIREMENTS

Test the following scenarios.

### Test 1

Create new Atlas.

Add entities.

Add events.

Close.

Reopen.

Verify persistence.

---

### Test 2

Create Atlas.

Move package root.

Open from new location.

Verify everything works.

---

### Test 3

Add:

* image
* audio
* document

Move package.

Verify references still work.

---

### Test 4

Run PKI.

Move package.

Verify:

* embeddings
* relationships
* patterns

remain available.

---

### Test 5

Unexpected shutdown simulation.

Verify database recovery.

---

### Test 6

Create on one host.

Open on another compatible host.

Verify continuity.

---

### Test 7

Large dataset performance.

Test with:

* thousands of entities
* tens of thousands of events

---

# 56. IMPORTANT NON-GOALS FOR THIS UPGRADE

Do NOT:

* introduce cloud storage
* introduce a backend server
* require login
* require internet
* replace SQLite unnecessarily
* convert everything to JSON
* remove existing intelligence features
* rebuild UI from scratch unnecessarily
* implement unsafe arbitrary AI-generated code execution
* copy the entire personal database permanently to every host
* assume one operating system
* hardcode absolute paths

---

# 57. FINAL SUCCESS CRITERIA

The architecture upgrade is successful when:

### 1.

ATLAS data is no longer conceptually owned by one phone.

### 2.

The database location can be configured through an Atlas Storage Provider.

### 3.

ATLAS can create and open a portable Atlas Package.

### 4.

All important paths are relative to the Atlas Package.

### 5.

Existing entities/events/intelligence can migrate into the package.

### 6.

The PKI continues to work.

### 7.

Analytics continues to work.

### 8.

Decision intelligence continues to work.

### 9.

Attachments remain connected after moving the package.

### 10.

The AI model architecture is separated from host runtime architecture.

### 11.

The application can detect host capabilities.

### 12.

The system supports safe shutdown and recovery.

### 13.

The architecture is capable of supporting Android, Linux, and Windows.

### 14.

ATLAS remains completely offline-first.

---

# FINAL DESIGN PHILOSOPHY

Do not think of ATLAS as:

> "A Flutter app that contains a database."

Think of it as:

> **A persistent personal intelligence system that can temporarily inhabit compatible devices.**

The architecture hierarchy should be:

```text
                 ATLAS IDENTITY
                        │
                        ▼
                 ATLAS PACKAGE
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
    MEMORY           KNOWLEDGE         MODELS
        │               │                │
        └───────────────┼────────────────┘
                        │
                        ▼
                 HOST INTERFACE
                        │
          ┌─────────────┼─────────────┐
          │             │             │
          ▼             ▼             ▼
       ANDROID        LINUX        WINDOWS
          │             │             │
          └─────────────┼─────────────┘
                        │
                        ▼
                 HOST RESOURCES

                 CPU • RAM • GPU
```

The persistent ATLAS Package is the **brain**.

The host device is the **temporary body**.

The Flutter application is the **interface**.

The AI runtime is the **reasoning engine**.

The database and knowledge graph are the **memory**.

The PKI is the **continuous learning/indexing system**.

The analytics engine is the **pattern discovery system**.

The decision system is the **reflection mechanism**.

Everything must work together without making ATLAS dependent on a particular device.

---

# FINAL INSTRUCTION TO THE IMPLEMENTING AGENT

Do not perform a destructive rewrite.

Do not delete working systems.

First audit the current project.

Then implement this architecture incrementally.

At every major phase:

1. Preserve backward compatibility where possible.
2. Verify existing functionality.
3. Test with existing user data.
4. Never silently destroy personal data.
5. Keep the persistent Atlas identity independent from host devices.
6. Maintain offline-first operation.
7. Use abstractions rather than platform-specific logic throughout business code.

The final result should not merely be a portable application.

It should be the foundation for:

> **A long-term, device-independent, personal intelligence system capable of carrying years or decades of accumulated personal knowledge.**

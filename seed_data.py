"""
Atlas Seed Data Script
======================
Populates the Atlas SQLite database with realistic test data:
  - 12 entities (people, projects, habits, decisions)
  - 150+ events spread over 120 days
  - Relationships between entities
  - Patterns
  - Entity statistics

Usage
-----
  # Push data to a connected Android device / emulator:
  python seed_data.py push

  # Generate the DB locally only (atlas_seed.db):
  python seed_data.py local

  # Remove ALL seeded rows from the device DB (clean wipe):
  python seed_data.py clean

Requirements: Python 3.8+, adb in PATH (for push/clean)
"""

import json
import math
import os
import random
import re
import sqlite3
import subprocess
import sys
import uuid
from datetime import datetime, timedelta
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────

# The DB lives inside the active Atlas package directory.
# path_provider on Android resolves getApplicationDocumentsDirectory() → app_flutter/
LOCAL_DB = Path("atlas_seed.db")
SEED_TAG = "SEED"          # written into every seeded row's tags so clean() can find them
DAYS = 120
BASE_DATE = datetime.now() - timedelta(days=DAYS)
APP_ID = "com.atlas.atlas"
DEFAULT_DEVICE_PACKAGE_NAME = "MyLife"

random.seed(42)

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# ── Helpers ───────────────────────────────────────────────────────────────────

def uid() -> str:
    return str(uuid.uuid4())

def ts(dt: datetime) -> int:
    """Drift stores DateTimeColumn as Unix epoch milliseconds."""
    return int(dt.timestamp() * 1000)

def jl(lst) -> str:
    return json.dumps(lst)

def jd(d) -> str:
    return json.dumps(d)

def rand_dt(day_offset_min=0, day_offset_max=DAYS) -> datetime:
    offset = random.randint(day_offset_min, day_offset_max)
    hour   = random.randint(7, 22)
    minute = random.choice([0, 15, 30, 45])
    return BASE_DATE + timedelta(days=offset, hours=hour, minutes=minute)

MOODS       = ["happy", "excited", "neutral", "stressed", "sad", "angry", "anxious", "calm"]
MOOD_SCORES = {"excited": 1.0, "happy": 0.8, "calm": 0.6, "neutral": 0.5,
               "anxious": 0.35, "stressed": 0.25, "sad": 0.2, "angry": 0.1}

def mood_score(m): return MOOD_SCORES.get(m, 0.5)

def text_to_vector(text: str, dim=128) -> list:
    words = [w for w in text.lower().split() if len(w) > 2]
    vec = [0.0] * dim
    for w in words:
        vec[hash(w) % dim] += 1.0
    mag = math.sqrt(sum(v * v for v in vec)) or 1.0
    return [v / mag for v in vec]


def fresh_seed_db_path(preferred: Path = LOCAL_DB) -> Path:
    """Return a writable seed DB path, avoiding stale locked files."""
    try:
        preferred.unlink(missing_ok=True)
        return preferred
    except PermissionError:
        return preferred.with_name(f"{preferred.stem}_{uuid.uuid4().hex}{preferred.suffix}")

# ── Entity definitions ────────────────────────────────────────────────────────

ENTITIES = [
    # id-key, name, description, tags, color, icon, is_decision, decision fields
    ("alice",    "Alice Chen",       "Senior colleague and mentor at work. Brilliant at system design.",
     ["colleague","mentor","tech"],   "4284955319",  "👩‍💻", False, {}),
    ("bob",      "Bob Martinez",     "Close friend since university. We meet for coffee every two weeks.",
     ["friend","social"],             "4288423856",  "☕",  False, {}),
    ("project_x","Project X",        "Main product initiative for Q3. High stakes, tight deadline.",
     ["work","project","priority"],   "4294198070",  "🚀",  False, {}),
    ("gym",      "Gym Habit",        "Daily workout routine. Tracking consistency and energy levels.",
     ["health","habit","fitness"],    "4283215696",  "💪",  False, {}),
    ("sleep",    "Sleep Quality",    "Monitoring sleep patterns and their effect on productivity.",
     ["health","habit","sleep"],      "4286611584",  "😴",  False, {}),
    ("career",   "Career Growth",    "Long-term career development and skill building.",
     ["career","growth","learning"],  "4294930432",  "📈",  False, {}),
    ("diet",     "Diet & Nutrition", "Tracking eating habits and their impact on energy and mood.",
     ["health","habit","nutrition"],  "4283780170",  "🥗",  False, {}),
    ("sarah",    "Sarah Kim",        "New team lead. Relationship is still developing.",
     ["colleague","manager"],         "4291543295",  "👔",  False, {}),
    # Decisions
    ("dec_job",  "Job Offer Decision","Evaluating a competing job offer from TechCorp. Higher pay but more travel.",
     ["decision","career","work"],    "4294956800",  "💼",  True,
     {"options": ["Accept offer", "Decline and stay", "Negotiate current role"],
      "reasoning": "The offer pays 30% more but requires 40% travel. Current role has better work-life balance.",
      "confidence": 6,
      "expected": "If I accept, I expect faster career growth but more stress.",
      "review_date": datetime.now() + timedelta(days=30)}),
    ("dec_city", "Relocate to Austin","Considering moving to Austin for lower cost of living and tech scene.",
     ["decision","life","location"],  "4294940928",  "🏙️",  True,
     {"options": ["Move to Austin", "Stay in current city", "Try remote first"],
      "reasoning": "Rent is 40% cheaper. But leaving my social network is a real cost.",
      "confidence": 5,
      "expected": "Better savings rate, new professional network.",
      "review_date": datetime.now() + timedelta(days=60)}),
    ("dec_mba",  "MBA Decision",     "Deciding whether to pursue a part-time MBA program.",
     ["decision","education","career"],"4293984255", "🎓",  True,
     {"options": ["Enroll in MBA", "Self-study instead", "Defer for 2 years"],
      "reasoning": "MBA costs $80k and 2 years of weekends. ROI is unclear in my field.",
      "confidence": 4,
      "expected": "Network expansion and potential salary bump in 3-5 years.",
      "review_date": datetime.now() + timedelta(days=90)}),
    ("dec_invest","Investment Strategy","Choosing between index funds vs active portfolio management.",
     ["decision","finance","investing"],"4284111872","💰", True,
     {"options": ["100% index funds", "70/30 index/active", "Hire financial advisor"],
      "reasoning": "Historical data favours index funds. But I want to learn active investing.",
      "confidence": 7,
      "expected": "Consistent 7-10% annual returns with low effort.",
      "review_date": datetime.now() + timedelta(days=45)}),
]

# ── Event templates ───────────────────────────────────────────────────────────

# (title, note_template, linked_entity_keys, mood_pool, importance_range, tags, is_decision)
EVENT_TEMPLATES = [
    # Work / Project X
    ("Sprint planning",
     "Kicked off the sprint with {entity}. Scope is ambitious but the team is aligned.",
     ["project_x", "alice"], ["excited","neutral","stressed"], (3,5), ["work","planning"], False),
    ("Code review session",
     "Spent 2 hours reviewing PRs with {entity}. Found 3 critical bugs before they hit prod.",
     ["project_x", "alice"], ["neutral","happy","stressed"], (3,4), ["work","code"], False),
    ("Deadline pressure",
     "Project X deadline is looming. Feeling the pressure. Had a tense sync with {entity}.",
     ["project_x", "sarah"], ["stressed","anxious"], (4,5), ["work","stress"], False),
    ("Feature shipped",
     "Shipped the authentication module. {entity} gave great feedback. Feeling accomplished.",
     ["project_x", "alice"], ["happy","excited"], (4,5), ["work","milestone"], False),
    ("1:1 with manager",
     "Weekly 1:1 with {entity}. Discussed career path and Q3 goals. Feeling more clarity.",
     ["sarah", "career"], ["neutral","calm","happy"], (3,4), ["work","career"], False),
    ("Team conflict",
     "Disagreement with {entity} over architecture choices. Need to find common ground.",
     ["sarah", "project_x"], ["stressed","anxious","angry"], (4,5), ["work","conflict"], False),

    # Social / Alice / Bob
    ("Coffee with Bob",
     "Great catch-up with {entity}. Talked about life, career changes, and weekend plans.",
     ["bob"], ["happy","calm","excited"], (2,4), ["social","friend"], False),
    ("Lunch with Alice",
     "Had lunch with {entity}. She shared advice on navigating the promotion process.",
     ["alice","career"], ["happy","neutral"], (3,4), ["social","mentor"], False),
    ("Bob's birthday dinner",
     "Celebrated {entity}'s birthday. Great group of people. Felt genuinely happy.",
     ["bob"], ["happy","excited"], (4,5), ["social","celebration"], False),
    ("Networking event",
     "Attended a tech meetup. Met some interesting people. {entity} introduced me to a recruiter.",
     ["alice","career"], ["neutral","excited"], (3,4), ["social","networking"], False),

    # Health / Gym
    ("Morning workout",
     "Hit the gym early. 45 min strength training. Energy levels high all day.",
     ["gym"], ["happy","excited","calm"], (3,4), ["health","fitness"], False),
    ("Skipped gym",
     "Skipped the gym today. Felt guilty but was exhausted from work.",
     ["gym","sleep"], ["sad","stressed","neutral"], (2,3), ["health","habit"], False),
    ("Personal best",
     "New personal best on deadlift — 120kg. Months of consistency paying off.",
     ["gym"], ["excited","happy"], (5,5), ["health","milestone","fitness"], False),
    ("Rest day",
     "Took a planned rest day. Body needed it. Did some light stretching instead.",
     ["gym","sleep"], ["calm","neutral"], (2,3), ["health","recovery"], False),

    # Sleep
    ("Poor sleep",
     "Only got 5 hours. Woke up multiple times. Productivity tanked today.",
     ["sleep","gym"], ["stressed","sad","anxious"], (3,4), ["health","sleep"], False),
    ("Great sleep",
     "8 solid hours. Woke up naturally before the alarm. Feeling sharp and focused.",
     ["sleep"], ["happy","calm","excited"], (3,4), ["health","sleep"], False),

    # Diet
    ("Meal prepped",
     "Spent Sunday meal prepping for the week. Feeling in control of my nutrition.",
     ["diet"], ["happy","calm"], (3,4), ["health","nutrition"], False),
    ("Junk food binge",
     "Stress-ate today. Pizza and chips. Felt good in the moment, regret after.",
     ["diet","sleep"], ["neutral","sad","stressed"], (2,3), ["health","nutrition"], False),

    # Career / Learning
    ("Completed online course",
     "Finished the system design course. Learned a lot about distributed systems.",
     ["career","project_x"], ["happy","excited"], (4,5), ["learning","career"], False),
    ("Salary negotiation",
     "Had the salary review conversation with {entity}. Outcome was better than expected.",
     ["sarah","career","dec_job"], ["anxious","happy","neutral"], (5,5), ["career","finance"], False),
    ("Read industry article",
     "Read a deep-dive on LLM architectures. Lots of ideas for Project X.",
     ["career","project_x"], ["neutral","excited"], (2,3), ["learning","tech"], False),

    # Decision events
    ("Researched TechCorp offer",
     "Spent the evening researching TechCorp. Glassdoor reviews are mixed. Travel policy is brutal.",
     ["dec_job","career"], ["anxious","neutral"], (4,5), ["decision","research"], True),
    ("Visited Austin",
     "Weekend trip to Austin to scout neighbourhoods. Liked the vibe but missed my friends.",
     ["dec_city"], ["neutral","happy","sad"], (4,5), ["decision","travel"], True),
    ("MBA info session",
     "Attended the MBA info session. Impressive alumni network. Cost is still a concern.",
     ["dec_mba","career"], ["neutral","excited","anxious"], (4,5), ["decision","education"], True),
    ("Reviewed investment returns",
     "Compared my active picks vs S&P 500 over 12 months. Index won by 4%.",
     ["dec_invest"], ["neutral","stressed"], (4,5), ["decision","finance"], True),
]

# ── Build data ────────────────────────────────────────────────────────────────

def build_entities():
    rows = []
    id_map = {}
    for key, name, desc, tags, color, icon, is_dec, dec in ENTITIES:
        eid = uid()
        id_map[key] = eid
        created = ts(BASE_DATE + timedelta(days=random.randint(0, 5)))
        review_ts = ts(dec["review_date"]) if is_dec and "review_date" in dec else None
        rows.append((
            eid, name, None, desc,
            jl(tags + [SEED_TAG]),
            jd({}), color, icon, "active",
            1 if is_dec else 0,
            jl(dec.get("options", [])) if is_dec else None,
            dec.get("reasoning") if is_dec else None,
            dec.get("confidence") if is_dec else None,
            dec.get("expected") if is_dec else None,
            None,  # actual outcome — unknown yet
            review_ts,
            created, created,
        ))
    return rows, id_map


def build_events(id_map):
    rows = []
    event_id_list = []

    # Generate ~150 events over DAYS days
    for _ in range(155):
        tmpl = random.choice(EVENT_TEMPLATES)
        title, note_tmpl, entity_keys, mood_pool, imp_range, tags, is_dec = tmpl

        # Resolve entity IDs
        linked_keys = [k for k in entity_keys if k in id_map]
        linked_ids  = [id_map[k] for k in linked_keys]

        # Fill {entity} placeholder with first entity name if present
        first_name = linked_keys[0].replace("_", " ").title() if linked_keys else "the team"
        note = note_tmpl.replace("{entity}", first_name)

        mood       = random.choice(mood_pool)
        importance = random.randint(*imp_range)
        event_dt   = rand_dt()
        eid        = uid()

        rows.append((
            eid,
            title,
            note,
            jl(linked_ids),
            jl([]),   # attachments
            None,     # voice note
            mood,
            importance,
            None, None, None, None,  # location, lat, lon, duration
            jd({}),
            jl(tags + [SEED_TAG]),
            1 if is_dec else 0,
            jl(["Accept", "Decline"]) if is_dec else None,
            "Evaluated based on available evidence." if is_dec else None,
            random.randint(4, 8) if is_dec else None,
            "Positive outcome expected." if is_dec else None,
            None,
            None,
            ts(event_dt),
            ts(event_dt),
        ))
        event_id_list.append((eid, linked_ids, mood, importance, event_dt))

    return rows, event_id_list


def build_relationships(id_map):
    pairs = [
        ("alice",     "project_x", "collaborates_on",  0.9),
        ("alice",     "career",    "mentors",           0.8),
        ("bob",       "alice",     "friend_of",         0.7),
        ("sarah",     "project_x", "manages",           0.95),
        ("sarah",     "career",    "influences",        0.6),
        ("project_x", "dec_job",   "related_to",        0.5),
        ("gym",       "sleep",     "affects",           0.75),
        ("diet",      "gym",       "supports",          0.7),
        ("sleep",     "career",    "impacts",           0.65),
        ("dec_job",   "career",    "part_of",           0.85),
        ("dec_mba",   "career",    "part_of",           0.8),
        ("dec_city",  "dec_job",   "related_to",        0.6),
        ("dec_invest","career",    "related_to",        0.55),
        ("bob",       "dec_city",  "discussed_with",    0.4),
    ]
    rows = []
    now  = ts(datetime.now())
    for a, b, rel_type, strength in pairs:
        if a in id_map and b in id_map:
            rows.append((uid(), id_map[a], id_map[b], rel_type, None, strength, now, now))
    return rows


def build_patterns(id_map):
    now = ts(datetime.now())
    patterns = [
        (uid(), "Gym → Better Sleep",
         "Workout days consistently correlate with higher sleep quality scores.",
         "association",
         jl([id_map["gym"], id_map["sleep"]]),
         jl([]), 0.82, 34, now, now, now),
        (uid(), "Stress Spikes on Project X Deadlines",
         "Mood drops to stressed/anxious in the 3 days before Project X milestones.",
         "sequential",
         jl([id_map["project_x"], id_map["sarah"]]),
         jl([]), 0.76, 8, now, now, now),
        (uid(), "Monday Morning Productivity Peak",
         "Events logged on Monday mornings have the highest importance ratings.",
         "time_series",
         jl([id_map["career"], id_map["project_x"]]),
         jl([]), 0.68, 16, now, now, now),
        (uid(), "Social Events Improve Mood for 2 Days",
         "After meeting Bob or Alice, mood scores are elevated for ~48 hours.",
         "sequential",
         jl([id_map["bob"], id_map["alice"]]),
         jl([]), 0.71, 12, now, now, now),
        (uid(), "Diet Slip → Gym Skip Cascade",
         "Junk food events are followed by gym skips within 24 hours 60% of the time.",
         "sequential",
         jl([id_map["diet"], id_map["gym"]]),
         jl([]), 0.61, 9, now, now, now),
        (uid(), "Decision Anxiety Pattern",
         "Decision-tagged events cluster with anxious/stressed moods and high importance.",
         "association",
         jl([id_map["dec_job"], id_map["dec_mba"], id_map["dec_city"]]),
         jl([]), 0.79, 21, now, now, now),
    ]
    return patterns


def build_statistics(id_map, event_id_list):
    # Group events by entity
    entity_events: dict[str, list] = {eid: [] for eid in id_map.values()}
    for eid, linked_ids, mood, importance, dt in event_id_list:
        for lid in linked_ids:
            if lid in entity_events:
                entity_events[lid].append((mood, importance, dt))

    rows = []
    now  = ts(datetime.now())
    for key, entity_id in id_map.items():
        evs = entity_events[entity_id]
        if not evs:
            continue
        total   = len(evs)
        is_dec  = any(k == key for k, *_ in [(e[0], e[1]) for e in ENTITIES if e[0] == key and e[6]])
        dec_count = sum(1 for e in evs if e[1] >= 4) if is_dec else 0
        avg_mood  = sum(mood_score(e[0]) for e in evs) / total
        avg_imp   = sum(e[1] for e in evs) / total

        mood_dist: dict[str, int] = {}
        for e in evs:
            mood_dist[e[0]] = mood_dist.get(e[0], 0) + 1

        monthly: dict[str, int] = {}
        for e in evs:
            key_m = e[2].strftime("%Y-%m")
            monthly[key_m] = monthly.get(key_m, 0) + 1

        last_event = ts(max(e[2] for e in evs))

        rows.append((
            entity_id, total, dec_count,
            round(avg_mood, 4), round(avg_imp, 4),
            jd(mood_dist), jd(monthly),
            last_event, now,
        ))
    return rows


def build_embeddings(event_rows):
    rows = []
    now  = ts(datetime.now())
    for row in event_rows:
        eid  = row[0]
        text = f"{row[1] or ''} {row[2]}"
        vec  = text_to_vector(text)
        rows.append((uid(), "event", eid, jd(vec), now))
    return rows

# ── DB write ──────────────────────────────────────────────────────────────────

def create_schema(c):
    c.executescript("""
        CREATE TABLE IF NOT EXISTS entities (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            profile_image_path TEXT,
            description TEXT,
            tags TEXT DEFAULT '[]',
            custom_fields TEXT DEFAULT '{}',
            color TEXT,
            icon TEXT,
            status TEXT DEFAULT 'active',
            is_decision INTEGER DEFAULT 0,
            decision_options TEXT,
            decision_reasoning TEXT,
            decision_confidence INTEGER,
            decision_expected_outcome TEXT,
            decision_actual_outcome TEXT,
            decision_review_date TEXT,
            created_at TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS events (
            id TEXT PRIMARY KEY,
            title TEXT,
            note TEXT NOT NULL,
            linked_entity_ids TEXT DEFAULT '[]',
            attachments TEXT DEFAULT '[]',
            voice_note_path TEXT,
            mood TEXT,
            importance INTEGER DEFAULT 3,
            location TEXT,
            latitude REAL,
            longitude REAL,
            duration_minutes INTEGER,
            custom_fields TEXT DEFAULT '{}',
            tags TEXT DEFAULT '[]',
            is_decision INTEGER DEFAULT 0,
            decision_options TEXT,
            decision_reasoning TEXT,
            decision_confidence INTEGER,
            decision_expected_outcome TEXT,
            decision_actual_outcome TEXT,
            decision_review_date TEXT,
            timestamp TEXT,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS relationships (
            id TEXT PRIMARY KEY,
            from_entity_id TEXT NOT NULL,
            to_entity_id TEXT NOT NULL,
            relationship_type TEXT NOT NULL,
            description TEXT,
            strength REAL DEFAULT 1.0,
            created_at TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS patterns (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            pattern_type TEXT NOT NULL,
            related_entity_ids TEXT DEFAULT '[]',
            evidence TEXT DEFAULT '[]',
            confidence REAL DEFAULT 0.0,
            occurrences INTEGER DEFAULT 0,
            first_seen TEXT,
            last_seen TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS entity_statistics (
            entity_id TEXT PRIMARY KEY,
            total_events INTEGER DEFAULT 0,
            total_decisions INTEGER DEFAULT 0,
            avg_mood_score REAL DEFAULT 0.0,
            avg_importance REAL DEFAULT 0.0,
            mood_distribution TEXT DEFAULT '{}',
            monthly_activity TEXT DEFAULT '{}',
            last_event_at TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS embeddings (
            id TEXT PRIMARY KEY,
            source_type TEXT NOT NULL,
            source_id TEXT NOT NULL,
            embedding_json TEXT NOT NULL,
            created_at TEXT
        );
    """)


def write_db(path: Path):
    conn = sqlite3.connect(path)
    c    = conn.cursor()
    create_schema(c)

    entity_rows, id_map       = build_entities()
    event_rows,  event_id_list = build_events(id_map)
    rel_rows                   = build_relationships(id_map)
    pattern_rows               = build_patterns(id_map)
    stat_rows                  = build_statistics(id_map, event_id_list)
    emb_rows                   = build_embeddings(event_rows)

    c.executemany("""
        INSERT OR REPLACE INTO entities
        (id,name,profile_image_path,description,tags,custom_fields,color,icon,status,
         is_decision,decision_options,decision_reasoning,decision_confidence,
         decision_expected_outcome,decision_actual_outcome,decision_review_date,
         created_at,updated_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, entity_rows)

    c.executemany("""
        INSERT OR REPLACE INTO events
        (id,title,note,linked_entity_ids,attachments,voice_note_path,mood,importance,
         location,latitude,longitude,duration_minutes,custom_fields,tags,is_decision,
         decision_options,decision_reasoning,decision_confidence,
         decision_expected_outcome,decision_actual_outcome,decision_review_date,
         timestamp,created_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, event_rows)

    c.executemany("""
        INSERT OR REPLACE INTO relationships
        (id,from_entity_id,to_entity_id,relationship_type,description,strength,
         created_at,updated_at)
        VALUES (?,?,?,?,?,?,?,?)
    """, rel_rows)

    c.executemany("""
        INSERT OR REPLACE INTO patterns
        (id,title,description,pattern_type,related_entity_ids,evidence,confidence,
         occurrences,first_seen,last_seen,updated_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
    """, pattern_rows)

    c.executemany("""
        INSERT OR REPLACE INTO entity_statistics
        (entity_id,total_events,total_decisions,avg_mood_score,avg_importance,
         mood_distribution,monthly_activity,last_event_at,updated_at)
        VALUES (?,?,?,?,?,?,?,?,?)
    """, stat_rows)

    c.executemany("""
        INSERT OR REPLACE INTO embeddings
        (id,source_type,source_id,embedding_json,created_at)
        VALUES (?,?,?,?,?)
    """, emb_rows)

    conn.commit()
    conn.close()

    print(f"  OK {len(entity_rows)} entities")
    print(f"  OK {len(event_rows)} events")
    print(f"  OK {len(rel_rows)} relationships")
    print(f"  OK {len(pattern_rows)} patterns")
    print(f"  OK {len(stat_rows)} entity statistics")
    print(f"  OK {len(emb_rows)} embeddings")

# ── ADB helpers ───────────────────────────────────────────────────────────────

def find_adb() -> str:
    """Return adb path, checking PATH then common Android SDK locations on Windows."""
    import shutil
    explicit = os.environ.get("ADB_PATH")
    if explicit:
        explicit_path = Path(explicit)
        if explicit_path.exists():
            return str(explicit_path.resolve())

    found = shutil.which("adb")
    if found:
        return found

    sdk_roots = [
        os.environ.get("ANDROID_SDK_ROOT"),
        os.environ.get("ANDROID_HOME"),
        str(Path(os.environ.get("LOCALAPPDATA", "")) / "Android" / "Sdk"),
        str(Path("E:/Android/Sdk")),
        str(Path("C:/Android/Sdk")),
        str(Path("C:/Android")),
    ]

    # Flutter often knows the SDK location even when PATH does not.
    try:
        doctor = subprocess.run(
            ["flutter", "doctor", "-v"],
            capture_output=True,
            text=True,
            check=False,
        )
        match = re.search(r"Android SDK at (.+)", doctor.stdout)
        if match:
            sdk_roots.insert(0, match.group(1).strip())
    except OSError:
        pass

    candidates = []
    for root in sdk_roots:
        if root:
            candidates.append(Path(root) / "platform-tools" / "adb.exe")

    # A few direct fallback paths for common Windows installs.
    candidates.extend([
        Path("C:/Users") / os.environ.get("USERNAME", "") / "AppData/Local/Android/Sdk/platform-tools/adb.exe",
        Path("C:/Android/platform-tools/adb.exe"),
        Path("C:/android-sdk/platform-tools/adb.exe"),
    ])

    for c in candidates:
        if c.exists():
            return str(c.resolve())

    print("ERROR: adb not found.")
    print("  Set ADB_PATH or install Android SDK platform-tools.")
    print("  Flutter reports your SDK at: E:\\Android\\Sdk")
    print("  Example: set ADB_PATH=E:\\Android\\Sdk\\platform-tools\\adb.exe")
    sys.exit(1)

ADB = os.environ.get("ADB_PATH") or find_adb()
print(f"  Using adb: {ADB}")


def device_shell(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run([ADB, "shell", "run-as", APP_ID, *args], capture_output=True, text=True)


def get_device_package_dir() -> str:
    """Return the app's active Atlas package directory on device."""
    pref_key = "flutter.atlas_package_dir"
    prefs = device_shell("cat", "shared_prefs/FlutterSharedPreferences.xml")
    if prefs.returncode == 0:
        match = re.search(rf'name="{re.escape(pref_key)}">([^<]+)</string>', prefs.stdout)
        if match:
            return match.group(1).strip()

    # Fallbacks for fresh installs or missing prefs.
    package_root = "app_flutter/atlas_packages"
    listing = device_shell("ls", "-1", package_root)
    if listing.returncode == 0:
        dirs = [line.strip() for line in listing.stdout.splitlines() if line.strip()]
        if DEFAULT_DEVICE_PACKAGE_NAME in dirs:
            return f"{package_root}/{DEFAULT_DEVICE_PACKAGE_NAME}"
        if dirs:
            return f"{package_root}/{dirs[0]}"

    return f"{package_root}/{DEFAULT_DEVICE_PACKAGE_NAME}"


def get_device_db_path() -> str:
    return f"{get_device_package_dir()}/atlas.db"

def adb(*args):
    result = subprocess.run([ADB, *args], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ADB error: {result.stderr.strip()}")
        sys.exit(1)
    return result.stdout.strip()

def push():
    print("Building seed database locally...")
    seed_db = fresh_seed_db_path()
    write_db(seed_db)

    # Ensure the package directory exists on device
    device_db_path = get_device_db_path()
    device_package_dir = device_db_path.rsplit("/atlas.db", 1)[0]
    adb("shell", "run-as", APP_ID, "mkdir", "-p", device_package_dir)

    print("Pulling app database from device...")
    adb("shell", "run-as", APP_ID, "sh", "-c", f"cp {device_db_path} /data/local/tmp/atlas_live.db 2>/dev/null || true")
    # If no DB exists yet on device, start from the seed directly
    result = subprocess.run([ADB, "shell", "ls /data/local/tmp/atlas_live.db"],
                            capture_output=True, text=True)
    if "No such file" in result.stdout or result.returncode != 0:
        print("  No existing DB on device - using seed as base.")
        adb("push", str(seed_db), "/data/local/tmp/atlas_live.db")
    else:
        adb("pull", "/data/local/tmp/atlas_live.db", "atlas_live.db")
        print("Merging seed data into live database...")
        live = sqlite3.connect("atlas_live.db")
        lc   = live.cursor()
        lc.execute(f"ATTACH '{LOCAL_DB}' AS seed")
        for table in ["entities", "events", "relationships", "patterns",
                      "entity_statistics", "embeddings"]:
            lc.execute(f"INSERT OR REPLACE INTO main.{table} SELECT * FROM seed.{table}")
        lc.execute("DETACH seed")
        live.commit()
        live.close()
        adb("push", "atlas_live.db", "/data/local/tmp/atlas_live.db")
        Path("atlas_live.db").unlink(missing_ok=True)

    print("Pushing database into Atlas package directory on device...")
    adb("shell", "run-as", APP_ID, "cp", "/data/local/tmp/atlas_live.db", device_db_path)

    # Cleanup
    seed_db.unlink(missing_ok=True)
    adb("shell", "rm -f /data/local/tmp/atlas_live.db")

    print("SUCCESS: Seed data pushed to device. Restart the app to see the data.")


def clean():
    print("Pulling app database from device...")
    device_db_path = get_device_db_path()
    adb("shell", "run-as", APP_ID, "cp", device_db_path, "/data/local/tmp/atlas_live.db")
    adb("pull", "/data/local/tmp/atlas_live.db", "atlas_live.db")

    print("Removing seeded rows...")
    live = sqlite3.connect("atlas_live.db")
    lc   = live.cursor()
    lc.executescript(f"""
        DELETE FROM events       WHERE tags LIKE '%{SEED_TAG}%';
        DELETE FROM entities     WHERE tags LIKE '%{SEED_TAG}%';
        DELETE FROM relationships
            WHERE from_entity_id NOT IN (SELECT id FROM entities)
               OR to_entity_id   NOT IN (SELECT id FROM entities);
        DELETE FROM entity_statistics
            WHERE entity_id NOT IN (SELECT id FROM entities);
        DELETE FROM embeddings
            WHERE source_type='event'
              AND source_id NOT IN (SELECT id FROM events);
        DELETE FROM patterns
            WHERE related_entity_ids != '[]'
              AND NOT EXISTS (
                SELECT 1 FROM entities
                WHERE related_entity_ids LIKE '%' || id || '%'
              );
    """)
    live.commit()
    live.close()

    print("Pushing cleaned database back to device...")
    adb("push", "atlas_live.db", "/data/local/tmp/atlas_live.db")
    adb("shell", "run-as", APP_ID, "cp", "/data/local/tmp/atlas_live.db", device_db_path)

    Path("atlas_live.db").unlink(missing_ok=True)
    adb("shell", "rm /data/local/tmp/atlas_live.db")
    print("SUCCESS: All seeded rows removed from device.")


def local():
    print("Building seed database locally...")
    seed_db = fresh_seed_db_path()
    write_db(seed_db)
    print(f"SUCCESS: Written to {seed_db.resolve()}")

# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "help"
    if cmd == "push":
        push()
    elif cmd == "clean":
        clean()
    elif cmd == "local":
        local()
    else:
        print(__doc__)

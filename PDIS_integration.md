Integrate PDIS (Weighted Decision Matrix) into Atlas
Context
You are working on Atlas, a Flutter offline Personal Intelligence Operating System. The app uses:

Drift (SQLite ORM) for the database — lib/core/database/tables.dart + app_database.dart

Riverpod for state management — lib/core/providers/providers.dart

Gemma (local LLM) via GemmaService for AI features

fl_chart for charts

The project already has a decisions/ feature and a _DecisionTab inside EntityDetailScreen (lib/features/entities/entity_detail_screen.dart). That tab currently gates itself behind entity.isDecision — showing an empty state for non-decision entities.

You are integrating a Weighted Decision Matrix (PDIS) feature. The goal is to make this available on every entity, not just ones marked as decisions. The entity is the subject of the evaluation, not the decision itself.

Philosophy (do not violate this)
The matrix is a pre-decision evaluation tool — it helps the user think through a choice about an entity

isDecision flag on an entity still means the user has committed to a decision — keep it as-is, do not remove it

Gemma only suggests criteria based on the entity's past events — it never scores, ranks, or decides

All scoring and ranking is pure deterministic math in Dart — no AI involvement in calculations

Multiple matrices can exist per entity (different questions over time)

The user manually controls everything — no auto-classification

Step 1 — Add DecisionMatrices table to tables.dart
Add this new table:

class DecisionMatrices extends Table {
  TextColumn get id => text()();
  TextColumn get entityId => text()();
  TextColumn get question => text()();
  // JSON: [{"name": "Cost", "weight": 0.4}, ...]
  TextColumn get criteria => text().withDefault(const Constant('[]'))();
  // JSON: [{"name": "Option A", "scores": {"Cost": 4, "Speed": 3}}, ...]
  TextColumn get options => text().withDefault(const Constant('[]'))();
  // JSON: [{"name": "Option A", "weightedScore": 3.7}, ...] sorted desc
  TextColumn get result => text().nullable()();
  RealColumn get confidenceScore => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

Copy

Insert at cursor
dart
Step 2 — Update app_database.dart
Add DecisionMatrices to the @DriftDatabase tables list

Bump schemaVersion to 4

Add migration in onUpgrade for from < 4:

await m.createTable(decisionMatrices);

Copy

Insert at cursor
Add these DAL methods:

Future<List<DecisionMatrix>> getMatricesForEntity(String entityId) =>
    (select(decisionMatrices)
      ..where((m) => m.entityId.equals(entityId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
    .get();

Stream<List<DecisionMatrix>> watchMatricesForEntity(String entityId) =>
    (select(decisionMatrices)
      ..where((m) => m.entityId.equals(entityId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
    .watch();

Future<void> upsertMatrix(DecisionMatricesCompanion matrix) =>
    into(decisionMatrices).insertOnConflictUpdate(matrix);

Future<void> deleteMatrix(String id) =>
    (delete(decisionMatrices)..where((m) => m.id.equals(id))).go();

Copy

Insert at cursor
dart
Run flutter pub run build_runner build --delete-conflicting-outputs to regenerate app_database.g.dart

Step 3 — Add Riverpod providers to providers.dart
final matricesForEntityProvider =
    StreamProvider.family<List<DecisionMatrix>, String>((ref, entityId) {
  return ref.watch(databaseProvider).watchMatricesForEntity(entityId);
});

Copy

Insert at cursor
Step 4 — Create lib/features/decisions/matrix_screen.dart
This is the full matrix builder screen. It receives an entityId and an optional existing DecisionMatrix (for editing).

The screen has 3 phases controlled by a local StatefulWidget with a _phase int (0, 1, 2):

Phase 0 — Setup

TextField for the decision question (e.g. "Should I hire Alvin for Project X?")

List of criteria rows: each has a name TextField and a weight Slider (0.1–1.0, step 0.1)

"Add Criterion" button

"Suggest with AI" button — calls GemmaService with a prompt built from the entity name + last 10 event notes for this entity, asking it to suggest 3–5 relevant criteria as a JSON array. Parse the response and populate the criteria list. Show a loading indicator while waiting. If Gemma is not loaded, show a snackbar saying "AI model not loaded"

"Next" button (disabled if question is empty or fewer than 2 criteria)

Phase 1 — Scoring

For each option (user adds options with a TextField + "Add Option" button at the top)

Show a grid: rows = options, columns = criteria

Each cell is a score selector 1–5 (use a Row of 5 small tappable circles or a Slider)

"Calculate" button at the bottom (disabled if fewer than 2 options or any score is 0)

Phase 2 — Results

Run the weighted sum calculation in Dart:

// Normalize weights so they sum to 1.0
final totalWeight = criteria.fold(0.0, (s, c) => s + c.weight);
for (final option in options) {
  option.weightedScore = criteria.fold(0.0, (s, c) =>
      s + (option.scores[c.name] ?? 0) * (c.weight / totalWeight));
}
options.sort((a, b) => b.weightedScore.compareTo(a.weightedScore));

Copy

Insert at cursor
dart
Compute confidence score (0.0–1.0):

// Score separation: gap between 1st and 2nd / max possible gap
final separation = options.length > 1
    ? (options[0].weightedScore - options[1].weightedScore) / 5.0
    : 1.0;
// Weight balance: penalize if one criterion dominates (>60% of total weight)
final maxWeight = criteria.map((c) => c.weight / totalWeight).reduce(max);
final balance = maxWeight > 0.6 ? 0.5 : 1.0;
final confidence = ((separation * 0.6) + (balance * 0.4)).clamp(0.0, 1.0);

Copy

Insert at cursor
dart
Display ranked options as cards with a horizontal bar showing the weighted score (max 5.0)

Show confidence as a colored label: ≥0.7 = High (green), ≥0.4 = Medium (amber), else Low (red)

Show a sensitivity note: if confidence < 0.4, show "Decision is sensitive to weight changes"

"Save" button — saves to DB via upsertMatrix, then pops back

"Commit as Decision" button — saves the matrix AND updates the entity's isDecision = true, decisionReasoning = question, then pops back

Step 5 — Update entity_detail_screen.dart
5a. Update _TabBarDelegate

Change the tab label from 'Decision' to 'Evaluate':

// before
Tab(text: 'Decision'),
// after
Tab(text: 'Evaluate'),

Copy

Insert at cursor
dart
5b. Replace _DecisionTab with _EvaluateTab

Remove the entire existing _DecisionTab class and replace with this:

class _EvaluateTab extends ConsumerWidget {
  final Entity entity;
  const _EvaluateTab({required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matricesAsync = ref.watch(matricesForEntityProvider(entity.id));
    return matricesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (matrices) => Stack(
        children: [
          matrices.isEmpty
              ? EmptyState(
                  icon: Icons.balance_outlined,
                  title: 'No evaluations yet',
                  subtitle: 'Tap + to evaluate a decision about ${entity.name}',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: matrices.length,
                  itemBuilder: (_, i) => _MatrixSummaryCard(matrix: matrices[i]),
                ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'evaluate_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatrixScreen(entityId: entity.id),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Evaluation'),
            ),
          ),
        ],
      ),
    );
  }
}


Copy

Insert at cursor
dart
Add a _MatrixSummaryCard widget that shows:

The question text

Date created

Top result option name + score (parsed from the result JSON)

Confidence badge (High/Medium/Low)

Tap → navigates to MatrixScreen(entityId: matrix.entityId, existing: matrix) for viewing/editing

5c. Update the TabBarView children — replace _DecisionTab(entity: entity) with _EvaluateTab(entity: entity)

Step 6 — Update decisions_screen.dart
The Decision Journal screen currently lists entities/events with isDecision = true. Keep that behavior but add a 4th tab called "Matrices" that shows all saved matrices across all entities (a global history), using ref.watch(databaseProvider).watchMatricesForEntity — or add a new watchAllMatrices() DB method that returns all rows ordered by createdAt desc.

Each row in the Matrices tab shows: entity name (look up by entityId), question, top result, confidence, date.

Step 7 — Wire navigation
In matrix_screen.dart, import and use:

matricesForEntityProvider from providers

databaseProvider from providers

gemmaServiceProvider from providers (to check if model is loaded before calling AI suggest)

uuid package for generating matrix IDs

Constraints
Do NOT remove or modify the isDecision flag logic anywhere — it still works as the "committed decision" marker

Do NOT auto-mark anything as a decision — only the "Commit as Decision" button in the matrix results phase does that

Do NOT call Gemma for scoring or ranking — only for criteria suggestions

Keep all existing tabs (Timeline, Stats, Graph, Gallery) untouched

The _DecisionTab that showed evidence/risk for isDecision entities is being replaced by _EvaluateTab — the old evidence display (DecisionEvidence, RiskBadge, ConfidenceGauge) is no longer needed in this tab (it can remain in decisions_screen.dart if used there)

Follow the existing code style: Riverpod consumers, AsyncValue.when, shared widgets like EmptyState, StatCard, SectionHeader

That's the full prompt. It covers every file that needs to change, the exact data model, the math, the UI phases, and all the constraints your agent needs to respect. You can hand this directly to your coding agent.



import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:drift/drift.dart' show Value;
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/utils/utils.dart';
import '../../shared/widgets/widgets.dart';

class MatrixScreen extends ConsumerStatefulWidget {
  final String entityId;
  final DecisionMatrix? existing;

  const MatrixScreen({super.key, required this.entityId, this.existing});

  @override
  ConsumerState<MatrixScreen> createState() => _MatrixScreenState();
}

class _MatrixScreenState extends ConsumerState<MatrixScreen> {
  final _questionController = TextEditingController();
  final _optionNameController = TextEditingController();
  final _uuid = const Uuid();

  int _phase = 0;
  bool _loadingSuggestions = false;
  bool _saving = false;
  late final String _matrixId;
  late final Future<Entity?> _entityFuture;

  final List<_CriterionDraft> _criteria = [];
  final List<_OptionDraft> _options = [];
  List<_ResultRow> _results = [];
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _matrixId = existing?.id ?? _uuid.v4();
    _entityFuture = ref.read(databaseProvider).getEntityById(widget.entityId);
    if (existing != null) {
      _questionController.text = existing.question;
      _criteria.addAll(_parseCriteria(existing.criteria));
      _options.addAll(_parseOptions(existing.options));
      if (existing.result != null) {
        _results = _parseResults(existing.result!);
        _confidence = existing.confidenceScore ?? 0.0;
        _phase = 2;
      } else if (_options.isNotEmpty) {
        _phase = 1;
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionNameController.dispose();
    for (final criterion in _criteria) {
      criterion.controller.dispose();
    }
    for (final option in _options) {
      option.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Entity?>(
      future: _entityFuture,
      builder: (context, snap) {
        final entityLabel = snap.data?.name ?? 'this entity';
        return Scaffold(
          appBar: AppBar(
            title: Text(_phase == 2 ? 'Matrix Results' : 'New Evaluation'),
            actions: [
              if (_phase > 0)
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _phase--),
                  child: const Text('Back'),
                ),
            ],
          ),
          body: SafeArea(
            child: _phase == 0
                ? _buildSetupPhase(context, entityLabel)
                : _phase == 1
                    ? _buildScoringPhase(context, entityLabel)
                    : _buildResultsPhase(context, entityLabel),
          ),
        );
      },
    );
  }

  Widget _buildSetupPhase(BuildContext context, String entityLabel) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            children: [
              SectionHeader(title: 'Setup'),
              const SizedBox(height: 12),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Decision question',
                  hintText: 'Should I hire Alvin for Project X?',
                  border: const OutlineInputBorder(),
                  helperText: 'This matrix is about $entityLabel',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Criteria',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addCriterion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Criterion'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_criteria.isEmpty)
                const EmptyState(
                  icon: Icons.rule_outlined,
                  title: 'No criteria yet',
                  subtitle: 'Add at least two criteria to continue',
                )
              else
                ..._criteria
                    .asMap()
                    .entries
                    .map((entry) => _buildCriterionRow(entry.key, entry.value)),
              const SizedBox(height: 8),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _questionController,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed:
                            _loadingSuggestions ? null : _suggestCriteriaWithAi,
                        icon: _loadingSuggestions
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(_loadingSuggestions
                            ? 'Suggesting...'
                            : 'Suggest with AI'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _canGoToScoring
                            ? () => setState(() => _phase = 1)
                            : null,
                        child: const Text('Next'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScoringPhase(BuildContext context, String entityLabel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title: 'Scoring'),
        Text(
          _questionController.text.isEmpty
              ? 'Question'
              : _questionController.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _optionNameController,
          decoration: const InputDecoration(
            labelText: 'Option name',
            hintText: 'Option A',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _addOption(),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _addOption,
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        ),
        const SizedBox(height: 16),
        if (_options.isEmpty)
          const EmptyState(
            icon: Icons.view_week_outlined,
            title: 'No options yet',
            subtitle: 'Add at least two options to score the matrix',
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Option')),
                ..._criteria
                    .map((criterion) => DataColumn(
                        label: Text(criterion.name.isEmpty
                            ? 'Criterion'
                            : criterion.name)))
                    .toList(),
              ],
              rows: _options.asMap().entries.map((entry) {
                final optionIndex = entry.key;
                final option = entry.value;
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(option.controller.text.isEmpty
                            ? 'Option ${optionIndex + 1}'
                            : option.controller.text),
                      ),
                    ),
                    ..._criteria.map((criterion) {
                      final score = option.scores[criterion.liveKey] ?? 0;
                      return DataCell(_ScorePicker(
                        score: score,
                        onChanged: (value) {
                          setState(() {
                            option.scores[criterion.liveKey] = value;
                          });
                        },
                      ));
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _canCalculate ? _calculateResults : null,
          child: const Text('Calculate'),
        ),
      ],
    );
  }

  Widget _buildResultsPhase(BuildContext context, String entityLabel) {
    final confidenceLabel = _confidence >= 0.7
        ? 'High'
        : _confidence >= 0.4
            ? 'Medium'
            : 'Low';
    final confidenceColor = _confidence >= 0.7
        ? Colors.green
        : _confidence >= 0.4
            ? Colors.amber
            : Colors.red;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title: 'Results'),
        Text(
          _questionController.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ConfidenceBadge(label: confidenceLabel, color: confidenceColor),
            if (_confidence < 0.4)
              const _ConfidenceBadge(label: 'Sensitive', color: Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        ..._results.map((result) => _ResultCard(result: result)),
        if (_confidence < 0.4) ...[
          const SizedBox(height: 12),
          const Text(
            'Decision is sensitive to weight changes',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
          ),
        ],
        const SizedBox(height: 24),
        if (_saving) const Center(child: CircularProgressIndicator()),
        if (!_saving)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _saveMatrix(commitAsDecision: false),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _saveMatrix(commitAsDecision: true),
                  child: const Text('Commit as Decision'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCriterionRow(int index, _CriterionDraft criterion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: criterion.controller,
                    decoration: InputDecoration(
                      labelText: 'Criterion ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (newName) {
                      final oldKey = criterion.name.trim();
                      criterion.name = newName;
                      final newKey = newName.trim();
                      if (oldKey == newKey) return;
                      for (final option in _options) {
                        if (option.scores.containsKey(oldKey)) {
                          option.scores[newKey] = option.scores.remove(oldKey)!;
                        }
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    criterion.controller.dispose();
                    _criteria.removeAt(index);
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Weight: ${criterion.weight.toStringAsFixed(1)}'),
            Slider(
              value: criterion.weight,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: criterion.weight.toStringAsFixed(1),
              onChanged: (value) => setState(() => criterion.weight = value),
            ),
          ],
        ),
      ),
    );
  }

  void _addCriterion() {
    setState(() {
      _criteria.add(_CriterionDraft(name: '', weight: 0.5));
    });
  }

  void _addOption() {
    final name = _optionNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      final scores = <String, int>{};
      for (final criterion in _criteria) {
        scores[criterion.liveKey] = 0;
      }
      _options.add(_OptionDraft(name: name, scores: scores));
      _optionNameController.clear();
    });
  }

  bool get _canGoToScoring {
    final question = _questionController.text.trim();
    final hasCriteria =
        _criteria.where((c) => c.controller.text.trim().isNotEmpty).length >= 2;
    return question.isNotEmpty && hasCriteria;
  }

  bool get _canCalculate {
    if (_options.length < 2 || _criteria.length < 2) return false;
    for (final option in _options) {
      for (final criterion in _criteria) {
        if ((option.scores[criterion.liveKey] ?? 0) == 0) return false;
      }
    }
    return true;
  }

  void _calculateResults() {
    final criteria = _activeCriteria;
    final options = _activeOptions;
    final totalWeight = criteria.fold<double>(0.0, (sum, c) => sum + c.weight);

    final results = <_ResultRow>[];
    for (final option in options) {
      final weightedScore = criteria.fold<double>(
        0.0,
        (sum, c) =>
            sum + (option.scores[c.liveKey] ?? 0) * (c.weight / totalWeight),
      );
      results.add(_ResultRow(name: option.name, weightedScore: weightedScore));
    }
    results.sort((a, b) => b.weightedScore.compareTo(a.weightedScore));

    final separation = results.length > 1
        ? (results[0].weightedScore - results[1].weightedScore) / 5.0
        : 1.0;
    final maxWeight =
        criteria.map((c) => c.weight / totalWeight).reduce(math.max);
    final balance = maxWeight > 0.6 ? 0.5 : 1.0;
    final confidence = ((separation * 0.6) + (balance * 0.4)).clamp(0.0, 1.0);

    setState(() {
      _results = results;
      _confidence = confidence;
      _phase = 2;
    });
  }

  List<_CriterionDraft> get _activeCriteria {
    return _criteria.where((c) => c.liveKey.isNotEmpty).toList();
  }

  List<_OptionDraft> get _activeOptions {
    return _options
        .map((option) => option.copyWith(
            name: option.controller.text.trim().isEmpty
                ? option.name
                : option.controller.text.trim()))
        .toList();
  }

  Future<void> _suggestCriteriaWithAi() async {
    final aiMode = ref.read(aiModeProvider);
    final db = ref.read(databaseProvider);
    final entity = await db.getEntityById(widget.entityId);
    final events = await db.getEventsForEntity(widget.entityId);
    final entityName = entity?.name ?? 'this entity';
    final notes = events
        .take(3)
        .map((e) => e.note.length > 60 ? e.note.substring(0, 60) : e.note)
        .join('; ');
    final question = _questionController.text.trim();
    final ctx = notes.isNotEmpty ? 'Context: $notes.' : '';
    final prompt =
        'List 4 short decision criteria for: "$question" about $entityName. $ctx'
        ' Reply with only a JSON array of strings. Example: ["Cost","Speed","Quality","Risk"]';

    // ── API mode (Gemini → OpenRouter fallback) ──────────────────────────────
    if (aiMode == AiMode.api) {
      setState(() => _loadingSuggestions = true);
      try {
        final apiService = await ref.read(aiApiServiceProvider.future);
        if (!apiService.hasAnyKey) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'No API key configured. Add a Gemini or OpenRouter API key in Settings.')),
            );
          }
          return;
        }
        final raw = await apiService.chat(prompt);
        _applySuggestions(raw);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('API suggestion failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loadingSuggestions = false);
      }
      return;
    }

    // ── Local model mode ─────────────────────────────────────────────────────
    final gemmaState = ref.read(gemmaServiceProvider);
    if (!gemmaState.isLoaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No AI active. Enable Local AI or Gemini/OpenRouter API in Settings.'),
          ),
        );
      }
      return;
    }

    setState(() => _loadingSuggestions = true);
    try {
      final service = ref.read(gemmaServiceProvider.notifier).service;
      final raw = await service.generateRaw(prompt);
      _applySuggestions(raw);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI suggestion failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _applySuggestions(String raw) {
    final suggestions = _parseCriteriaSuggestions(raw);
    if (suggestions.isEmpty) {
      setState(() {
        _criteria
          ..clear()
          ..addAll(['Cost', 'Quality', 'Risk', 'Time']
              .map((n) => _CriterionDraft(name: n, weight: 0.5)));
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not parse AI response — using generic criteria')),
        );
      }
      return;
    }
    setState(() {
      _criteria
        ..clear()
        ..addAll(suggestions.map((n) => _CriterionDraft(name: n, weight: 0.5)));
    });
  }

  List<String> _parseCriteriaSuggestions(String response) {
    final trimmed = response.trim();
    final candidates = <String>{};

    String? jsonText;
    if (trimmed.startsWith('```')) {
      final start = trimmed.indexOf('[');
      final end = trimmed.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        jsonText = trimmed.substring(start, end + 1);
      }
    }
    jsonText ??= _extractJsonArray(trimmed);
    if (jsonText == null) return const [];

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is String) {
            final value = item.trim();
            if (value.isNotEmpty) candidates.add(value);
          } else if (item is Map) {
            final value =
                (item['name'] ?? item['criterion'] ?? '').toString().trim();
            if (value.isNotEmpty) candidates.add(value);
          }
        }
      }
    } catch (_) {
      return const [];
    }
    return candidates.toList();
  }

  String? _extractJsonArray(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  Future<void> _saveMatrix({required bool commitAsDecision}) async {
    if (_saving) return;
    final db = ref.read(databaseProvider);
    final criteria = _activeCriteria;
    final options = _activeOptions;
    final totalWeight = criteria.fold<double>(0.0, (sum, c) => sum + c.weight);
    final ranked = <_ResultRow>[];
    for (final option in options) {
      final weightedScore = criteria.fold<double>(
        0.0,
        (sum, c) =>
            sum + (option.scores[c.liveKey] ?? 0) * (c.weight / totalWeight),
      );
      ranked.add(_ResultRow(name: option.name, weightedScore: weightedScore));
    }
    ranked.sort((a, b) => b.weightedScore.compareTo(a.weightedScore));

    final confidence = _confidence;
    final matrix = DecisionMatrix(
      id: _matrixId,
      entityId: widget.entityId,
      question: _questionController.text.trim(),
      criteria: jsonEncode(criteria
          .map((c) => {
                'name': c.liveKey,
                'weight': c.weight,
              })
          .toList()),
      options: jsonEncode(options
          .map((option) => {
                'name': option.name,
                'scores': option.scores,
              })
          .toList()),
      result: jsonEncode(ranked
          .map((result) => {
                'name': result.name,
                'weightedScore': result.weightedScore,
              })
          .toList()),
      confidenceScore: confidence,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    setState(() => _saving = true);
    try {
      await db.upsertMatrix(matrix);
      if (commitAsDecision) {
        final entity = await db.getEntityById(widget.entityId);
        if (entity != null) {
          await db.upsertEntity(
            entity
                .copyWith(
                  isDecision: true,
                  decisionReasoning: Value(_questionController.text.trim()),
                )
                .toCompanion(true),
          );
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<_CriterionDraft> _parseCriteria(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return _CriterionDraft(
            name: (map['name'] ?? '').toString(),
            weight: (map['weight'] as num?)?.toDouble() ?? 0.5,
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }

  List<_OptionDraft> _parseOptions(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final scores = <String, int>{};
          final decodedScores = map['scores'];
          if (decodedScores is Map) {
            decodedScores.forEach((key, value) {
              scores[key.toString()] = (value as num?)?.toInt() ?? 0;
            });
          }
          return _OptionDraft(
              name: (map['name'] ?? '').toString(), scores: scores);
        }).toList();
      }
    } catch (_) {}
    return const [];
  }

  List<_ResultRow> _parseResults(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return _ResultRow(
            name: (map['name'] ?? '').toString(),
            weightedScore: (map['weightedScore'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }
}

class _CriterionDraft {
  final TextEditingController controller;
  String name;
  double weight;

  _CriterionDraft({required this.name, required this.weight})
      : controller = TextEditingController(text: name);

  /// Always use this as the score map key — it is the live controller text.
  String get liveKey => controller.text.trim();
}

class _OptionDraft {
  final TextEditingController controller;
  final String name;
  final Map<String, int> scores;

  _OptionDraft({required this.name, required this.scores})
      : controller = TextEditingController(text: name);

  _OptionDraft copyWith({String? name, Map<String, int>? scores}) {
    return _OptionDraft(
        name: name ?? this.name,
        scores: scores ?? Map<String, int>.from(this.scores));
  }
}

class _ResultRow {
  final String name;
  final double weightedScore;

  const _ResultRow({required this.name, required this.weightedScore});
}

class _ScorePicker extends StatelessWidget {
  final int score;
  final ValueChanged<int> onChanged;

  const _ScorePicker({required this.score, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = score >= value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border:
                    Border.all(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _ResultRow result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = (result.weightedScore / 5.0).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text('${result.weightedScore.toStringAsFixed(2)} / 5.0'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ConfidenceBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

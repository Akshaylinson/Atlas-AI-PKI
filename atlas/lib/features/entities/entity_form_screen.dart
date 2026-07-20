import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/widgets.dart';
import 'package:drift/drift.dart' show Value;

class EntityFormScreen extends ConsumerStatefulWidget {
  final Entity? entity; // null = create, non-null = edit

  const EntityFormScreen({super.key, this.entity});

  @override
  ConsumerState<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends ConsumerState<EntityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  List<String> _tags = [];
  Color _color = const Color(0xFF6750A4);
  String? _icon;
  String _status = 'active';
  bool _isDecision = false;
  List<Map<String, String>> _customFields = [];

  // Decision fields
  final _optionsCtrl = TextEditingController();
  final _reasoningCtrl = TextEditingController();
  final _expectedOutcomeCtrl = TextEditingController();
  int _decisionConfidence = 5;
  DateTime? _reviewDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entity;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description ?? '';
      _tags = List<String>.from(jsonDecode(e.tags));
      if (e.color != null) {
        _color = Color(int.tryParse(e.color!) ?? const Color(0xFF6750A4).toARGB32());
      }
      _icon = e.icon;
      _status = e.status;
      _isDecision = e.isDecision;
      if (e.decisionOptions != null) {
        _optionsCtrl.text =
            (jsonDecode(e.decisionOptions!) as List).join('\n');
      }
      _reasoningCtrl.text = e.decisionReasoning ?? '';
      _expectedOutcomeCtrl.text = e.decisionExpectedOutcome ?? '';
      _decisionConfidence = e.decisionConfidence ?? 5;
      _reviewDate = e.decisionReviewDate;
      final fields = jsonDecode(e.customFields) as Map<String, dynamic>;
      _customFields = fields.entries
          .map((e) => {'key': e.key, 'value': e.value.toString(), 'type': 'text'})
          .toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _optionsCtrl.dispose();
    _reasoningCtrl.dispose();
    _expectedOutcomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final db = ref.read(databaseProvider);
    final id = widget.entity?.id ?? const Uuid().v4();

    final customFieldsMap = {
      for (final f in _customFields) f['key']!: f['value']!
    };

    final options = _optionsCtrl.text.trim().isEmpty
        ? null
        : jsonEncode(_optionsCtrl.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList());

    await db.upsertEntity(EntitiesCompanion(
      id: Value(id),
      name: Value(_nameCtrl.text.trim()),
      description: Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
      tags: Value(jsonEncode(_tags)),
      color: Value(_color.toARGB32().toString()),
      icon: Value(_icon),
      status: Value(_status),
      isDecision: Value(_isDecision),
      customFields: Value(jsonEncode(customFieldsMap)),
      decisionOptions: Value(options),
      decisionReasoning: Value(_reasoningCtrl.text.trim().isEmpty
          ? null
          : _reasoningCtrl.text.trim()),
      decisionConfidence: Value(_isDecision ? _decisionConfidence : null),
      decisionExpectedOutcome: Value(_expectedOutcomeCtrl.text.trim().isEmpty
          ? null
          : _expectedOutcomeCtrl.text.trim()),
      decisionReviewDate: Value(_reviewDate),
      updatedAt: Value(DateTime.now()),
    ));

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  void _addCustomField() {
    setState(() => _customFields.add({'key': '', 'value': '', 'type': 'text'}));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entity != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Entity' : 'New Entity'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Color & Icon row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Color', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickColor,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: _color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Icon / Emoji', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: _icon,
                        decoration: const InputDecoration(
                          hintText: '🚀 or leave blank',
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _icon = v.isEmpty ? null : v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['active', 'inactive', 'archived']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),

            // Tags
            const Text('Tags', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add tag...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _tags
                      .map((t) => TagChip(
                            tag: t,
                            onDelete: () => setState(() => _tags.remove(t)),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),

            // Custom Fields
            Row(
              children: [
                const Text('Custom Fields',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addCustomField,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            ..._customFields.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            hintText: 'Field name', isDense: true),
                        controller:
                            TextEditingController(text: _customFields[i]['key']),
                        onChanged: (v) => _customFields[i]['key'] = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            hintText: 'Value', isDense: true),
                        controller:
                            TextEditingController(text: _customFields[i]['value']),
                        onChanged: (v) => _customFields[i]['value'] = v,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      onPressed: () =>
                          setState(() => _customFields.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            // Decision checkbox
            const Divider(),
            CheckboxListTile(
              value: _isDecision,
              onChanged: (v) => setState(() => _isDecision = v!),
              title: const Text('Mark as Decision',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Manually label this entity as a decision for tracking'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Decision fields (only shown when isDecision = true)
            if (_isDecision) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Decision Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.amber)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _optionsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Options Considered (one per line)',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasoningCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reasoning at the time',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _expectedOutcomeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Expected Outcome'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'Confidence Level: $_decisionConfidence / 10',
                        style: const TextStyle(fontSize: 13)),
                    Slider(
                      value: _decisionConfidence.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_decisionConfidence',
                      onChanged: (v) =>
                          setState(() => _decisionConfidence = v.toInt()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Review Date: ',
                            style: TextStyle(fontSize: 13)),
                        TextButton(
                          onPressed: _pickReviewDate,
                          child: Text(_reviewDate != null
                              ? '${_reviewDate!.day}/${_reviewDate!.month}/${_reviewDate!.year}'
                              : 'Set date'),
                        ),
                        if (_reviewDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () =>
                                setState(() => _reviewDate = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickColor() async {
    Color picked = _color;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _color,
            onColorChanged: (c) => picked = c,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() => _color = picked);
              Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReviewDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reviewDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _reviewDate = picked);
  }
}

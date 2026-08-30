import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/services/atlas_storage.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/utils/utils.dart';
import 'package:drift/drift.dart' show Value;

class _FieldCtrl {
  final TextEditingController key;
  final TextEditingController value;
  _FieldCtrl(String k, String v)
      : key = TextEditingController(text: k),
        value = TextEditingController(text: v);
  void dispose() {
    key.dispose();
    value.dispose();
  }
}

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
  final _iconCtrl = TextEditingController();

  List<String> _tags = [];
  Color _color = const Color(0xFF6750A4);
  String? _icon;
  String? _profileImagePath;
  String _status = 'active';
  bool _isDecision = false;
  final List<Map<String, String>> _customFields = [];
  final List<_FieldCtrl> _customFieldCtrls = [];

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
      _tags = parseStringListJson(e.tags);
      if (e.color != null) {
        _color = Color(int.tryParse(e.color!) ?? const Color(0xFF6750A4).toARGB32());
      }
      _icon = e.icon;
      _iconCtrl.text = e.icon ?? '';
      _profileImagePath = e.profileImagePath;
      _status = e.status;
      _isDecision = e.isDecision;
      if (e.decisionOptions != null) {
        _optionsCtrl.text = parseStringListJson(e.decisionOptions!).join('\n');
      }
      _reasoningCtrl.text = e.decisionReasoning ?? '';
      _expectedOutcomeCtrl.text = e.decisionExpectedOutcome ?? '';
      _decisionConfidence = e.decisionConfidence ?? 5;
      _reviewDate = e.decisionReviewDate;
      final fields = parseStringMapJson(e.customFields);
      for (final entry in fields.entries) {
        _customFields.add({'key': entry.key, 'value': entry.value.toString(), 'type': 'text'});
        _customFieldCtrls.add(_FieldCtrl(entry.key, entry.value.toString()));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _iconCtrl.dispose();
    _optionsCtrl.dispose();
    _reasoningCtrl.dispose();
    _expectedOutcomeCtrl.dispose();
    for (final c in _customFieldCtrls) {
      c.dispose();
    }
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
      profileImagePath: Value(_profileImagePath),
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
    setState(() {
      _customFields.add({'key': '', 'value': '', 'type': 'text'});
      _customFieldCtrls.add(_FieldCtrl('', ''));
    });
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
            // Profile Image
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: _color.withOpacity(0.2),
                      backgroundImage: _profileImagePath != null &&
                          File(AtlasStorage.resolvePathSync(_profileImagePath!)).existsSync()
                          ? FileImage(File(AtlasStorage.resolvePathSync(_profileImagePath!)))
                          : null,
                      child: _profileImagePath == null
                          ? Text(
                              _nameCtrl.text.isNotEmpty
                                  ? _nameCtrl.text[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _color),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                    if (_profileImagePath != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _profileImagePath = null),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                        controller: _iconCtrl,
                        decoration: const InputDecoration(
                          hintText: '🚀 or leave blank',
                          isDense: true,
                        ),
                        onChanged: (v) => _icon = v.isEmpty ? null : v,
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
            ...List.generate(_customFields.length, (i) {
              final ctrl = _customFieldCtrls[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            hintText: 'Field name', isDense: true),
                        controller: ctrl.key,
                        onChanged: (v) => _customFields[i]['key'] = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            hintText: 'Value', isDense: true),
                        controller: ctrl.value,
                        onChanged: (v) => _customFields[i]['value'] = v,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      onPressed: () => setState(() {
                        _customFieldCtrls[i].dispose();
                        _customFieldCtrls.removeAt(i);
                        _customFields.removeAt(i);
                      }),
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

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImagePath = AtlasStorage.relativePathOfSync(picked.path));
    }
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

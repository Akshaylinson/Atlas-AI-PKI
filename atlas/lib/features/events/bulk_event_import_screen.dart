import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/services/bulk_event_import_service.dart';
import '../../shared/widgets/widgets.dart';

class BulkEventImportScreen extends ConsumerStatefulWidget {
  const BulkEventImportScreen({super.key});

  @override
  ConsumerState<BulkEventImportScreen> createState() => _BulkEventImportScreenState();
}

class _BulkEventImportScreenState extends ConsumerState<BulkEventImportScreen> {
  final _inputCtrl = TextEditingController();
  final _service = BulkEventImportService();

  Timer? _debounce;
  List<BulkEventImportRow> _previewRows = const [];
  bool _parsing = false;
  bool _importing = false;
  bool _createMissingEntities = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(_scheduleParse);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _scheduleParse() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _parsePreview);
  }

  void _parsePreview() {
    if (!mounted) return;
    setState(() {
      _parsing = true;
      _statusMessage = null;
    });

    try {
      final rows = _service.preview(_inputCtrl.text);
      if (!mounted) return;
      setState(() {
        _previewRows = rows;
        _parsing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewRows = const [];
        _parsing = false;
        _statusMessage = 'Could not parse the input: $e';
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt', 'tsv'],
      allowMultiple: false,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    final bytes = await File(path).readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);
    _inputCtrl.text = content;
    _parsePreview();
  }

  Future<void> _importRows() async {
    final validRows = _previewRows.where((row) => row.isValid).toList();
    if (validRows.isEmpty || _importing) return;

    setState(() {
      _importing = true;
      _statusMessage = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final summary = await _service.importRows(
        db,
        validRows,
        createMissingEntities: _createMissingEntities,
      );

      final pki = ref.read(pkiPipelineProvider);
      for (final eventId in summary.importedEventIds) {
        unawaited(pki.process(eventId));
      }

      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Imported ${summary.importedEvents} events, created ${summary.createdEntities} entities, skipped ${summary.skippedRows} rows.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${summary.importedEvents} events',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Import failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validRows = _previewRows.where((row) => row.isValid).toList();
    final invalidRows = _previewRows.where((row) => !row.isValid).toList();
    final canImport = validRows.isNotEmpty && !_importing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Event Import'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paste or upload historical data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expected columns: date, note, entity. CSV, TSV, or simple text lines are supported. '
                      'If no header is present, Atlas assumes date | note | entity order.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('Upload file'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _inputCtrl.text.isEmpty
                              ? null
                              : () {
                                  _inputCtrl.clear();
                                  setState(() {
                                    _previewRows = const [];
                                    _statusMessage = null;
                                  });
                                },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _inputCtrl,
                      minLines: 10,
                      maxLines: 18,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'CSV or text input',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        hintText: 'date,note,entity',
                      ),
                      onChanged: (_) => _scheduleParse(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _createMissingEntities,
              onChanged: (v) => setState(() => _createMissingEntities = v),
              title: const Text('Create missing entities'),
              subtitle: const Text('If a row references a new name, Atlas will create the entity automatically.'),
            ),
            const SizedBox(height: 8),
            if (_parsing) const LinearProgressIndicator(),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.startsWith('Import failed')
                      ? Colors.red
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _ImportSummary(
              total: _previewRows.length,
              valid: validRows.length,
              invalid: invalidRows.length,
            ),
            const SizedBox(height: 16),
            if (_previewRows.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: canImport ? _importRows : null,
                    icon: _importing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.playlist_add_check),
                    label: Text(_importing ? 'Importing...' : 'Import'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._previewRows.take(20).map((row) => _PreviewRowCard(row: row)),
              if (_previewRows.length > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Showing first 20 rows of ${_previewRows.length}.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
            ] else
              EmptyState(
                icon: Icons.upload_file_outlined,
                title: 'No rows yet',
                subtitle: 'Paste CSV/text or upload a file to preview rows before importing.',
              ),
          ],
        ),
      ),
    );
  }
}

class _ImportSummary extends StatelessWidget {
  final int total;
  final int valid;
  final int invalid;

  const _ImportSummary({
    required this.total,
    required this.valid,
    required this.invalid,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(label: 'Rows: $total', color: scheme.primary),
        _SummaryChip(label: 'Valid: $valid', color: Colors.green),
        _SummaryChip(label: 'Invalid: $invalid', color: Colors.red),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreviewRowCard extends StatelessWidget {
  final BulkEventImportRow row;

  const _PreviewRowCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = row.isValid ? scheme.outlineVariant : Colors.red.withOpacity(0.4);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Line ${row.lineNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (row.isValid)
                    const Icon(Icons.check_circle, size: 16, color: Colors.green)
                  else
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                row.note.isEmpty ? '(no note)' : row.note,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    icon: Icons.event,
                    label: row.date != null
                        ? '${row.date!.year}-${row.date!.month.toString().padLeft(2, '0')}-${row.date!.day.toString().padLeft(2, '0')}'
                        : row.rawDate,
                  ),
                  _MetaChip(
                    icon: Icons.person_outline,
                    label: row.entityNames.isEmpty ? 'No entity' : row.entityNames.join(', '),
                  ),
                ],
              ),
              if (!row.isValid) ...[
                const SizedBox(height: 8),
                Text(
                  row.error ?? 'Invalid row',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

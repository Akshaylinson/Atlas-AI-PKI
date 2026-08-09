import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/models.dart';

class BulkEventImportRow {
  final int lineNumber;
  final DateTime? date;
  final String note;
  final List<String> entityNames;
  final String rawDate;
  final String rawEntities;
  final String? error;

  const BulkEventImportRow({
    required this.lineNumber,
    required this.date,
    required this.note,
    required this.entityNames,
    required this.rawDate,
    required this.rawEntities,
    this.error,
  });

  bool get isValid => error == null;
}

class BulkEventImportSummary {
  final int importedEvents;
  final int createdEntities;
  final int skippedRows;
  final List<String> importedEventIds;

  const BulkEventImportSummary({
    required this.importedEvents,
    required this.createdEntities,
    required this.skippedRows,
    required this.importedEventIds,
  });
}

class BulkEventImportService {
  static const _headerAliases = <String, Set<String>>{
    'date': {'date', 'datetime', 'time', 'timestamp', 'when', 'day', 'eventdate', 'event_date'},
    'note': {'note', 'notes', 'entry', 'text', 'body', 'content', 'description', 'journal'},
    'entity': {'entity', 'entities', 'person', 'people', 'contact', 'contacts', 'subject'},
  };

  static const _dateFormats = <String>[
    'yyyy-MM-dd',
    'yyyy-MM-dd HH:mm',
    'yyyy-MM-dd HH:mm:ss',
    'M/d/yyyy',
    'M/d/yyyy H:mm',
    'M/d/yyyy h:mm a',
    'MM/dd/yyyy',
    'MM/dd/yyyy H:mm',
    'MM/dd/yyyy h:mm a',
    'd/M/yyyy',
    'd/M/yyyy H:mm',
    'd/M/yyyy h:mm a',
    'dd/MM/yyyy',
    'dd/MM/yyyy H:mm',
    'dd/MM/yyyy h:mm a',
    'MMM d, yyyy',
    'MMM d, yyyy h:mm a',
    'd MMM yyyy',
    'd MMM yyyy h:mm a',
  ];

  List<BulkEventImportRow> preview(String input) {
    final normalized = _normalizeInput(input);
    if (normalized.trim().isEmpty) return const [];

    final rows = _parseRows(normalized);
    if (rows.isEmpty) return const [];

    final firstDataRowIndex = _isHeaderRow(rows.first) ? 1 : 0;
    final header = firstDataRowIndex == 1 ? rows.first : const <String>[];
    final dataRows = rows.skip(firstDataRowIndex).toList();
    final delimiter = _detectDelimiter(normalized);

    final dateIndex = _columnIndex(header, 'date', fallback: 0);
    final noteIndex = _columnIndex(header, 'note', fallback: 1);
    final entityIndex = _columnIndex(header, 'entity', fallback: 2);

    return [
      for (var i = 0; i < dataRows.length; i++)
        _parseRow(
          dataRows[i],
          lineNumber: i + firstDataRowIndex + 1,
          delimiter: delimiter,
          dateIndex: dateIndex,
          noteIndex: noteIndex,
          entityIndex: entityIndex,
          useHeaderMapping: firstDataRowIndex == 1,
        ),
    ];
  }

  Future<BulkEventImportSummary> importRows(
    AppDatabase db,
    List<BulkEventImportRow> rows, {
    bool createMissingEntities = true,
  }) async {
    var importedEvents = 0;
    var createdEntities = 0;
    var skippedRows = 0;
    final importedEventIds = <String>[];

    final existingEntities = await db.getAllEntities();
    final entityLookup = <String, Entity>{
      for (final entity in existingEntities) _normalizeName(entity.name): entity,
    };

    await db.transaction(() async {
      for (final row in rows) {
        if (!row.isValid || row.date == null || row.note.trim().isEmpty) {
          skippedRows++;
          continue;
        }

        final linkedEntityIds = <String>[];
        for (final entityName in row.entityNames) {
          final normalized = _normalizeName(entityName);
          if (normalized.isEmpty) continue;

          final existing = entityLookup[normalized];
          if (existing != null) {
            linkedEntityIds.add(existing.id);
            continue;
          }

          if (!createMissingEntities) continue;

          final newEntity = Entity(
            id: const Uuid().v4(),
            name: entityName.trim(),
            profileImagePath: null,
            description: null,
            tags: '[]',
            customFields: '{}',
            color: null,
            icon: null,
            status: 'active',
            isDecision: false,
            decisionOptions: null,
            decisionReasoning: null,
            decisionConfidence: null,
            decisionExpectedOutcome: null,
            decisionActualOutcome: null,
            decisionReviewDate: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await db.upsertEntity(newEntity.toCompanion(true));
          entityLookup[normalized] = newEntity;
          linkedEntityIds.add(newEntity.id);
          createdEntities++;
        }

        final eventId = const Uuid().v4();
        await db.upsertEvent(EventsCompanion.insert(
          id: eventId,
          note: row.note.trim(),
          linkedEntityIds: Value(jsonEncode(linkedEntityIds)),
          timestamp: Value(row.date!),
        ));
        importedEvents++;
        importedEventIds.add(eventId);
      }
    });

    return BulkEventImportSummary(
      importedEvents: importedEvents,
      createdEntities: createdEntities,
      skippedRows: skippedRows,
      importedEventIds: importedEventIds,
    );
  }

  String _normalizeInput(String input) {
    var text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    final lines = text.split('\n');
    if (lines.isNotEmpty && lines.first.trimLeft().toLowerCase().startsWith('sep=')) {
      lines.removeAt(0);
      text = lines.join('\n');
    }
    return text.trim();
  }

  String _detectDelimiter(String input) {
    final lines = input.split('\n').where((line) => line.trim().isNotEmpty).take(4).toList();
    if (lines.isNotEmpty) {
      final first = lines.first.trimLeft();
      if (first.toLowerCase().startsWith('sep=') && first.length >= 5) {
        return first.substring(4, 5);
      }
    }

    final candidates = <String>[',', ';', '\t', '|'];
    var bestDelimiter = ',';
    var bestScore = -1;

    for (final delimiter in candidates) {
      final parsed = _parseRows(input, delimiter: delimiter);
      final lengths = parsed.where((row) => row.any((cell) => cell.trim().isNotEmpty)).map((row) => row.length).toList();
      if (lengths.isEmpty) continue;

      final freq = <int, int>{};
      for (final len in lengths) {
        freq[len] = (freq[len] ?? 0) + 1;
      }
      final bestLen = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final mostCommon = bestLen.first;
      final consistency = lengths.fold<int>(0, (sum, len) => sum + (len == mostCommon.key ? 1 : 0));
      final score = consistency * 100 - lengths.fold<int>(0, (sum, len) => sum + (len - mostCommon.key).abs());

      if (score > bestScore) {
        bestScore = score;
        bestDelimiter = delimiter;
      }
    }

    return bestDelimiter;
  }

  List<List<String>> _parseRows(String input, {String? delimiter}) {
    final delim = delimiter ?? _detectDelimiter(input);
    final text = input.trim();
    final rows = <List<String>>[];
    final row = <String>[];
    var cell = StringBuffer();
    var inQuotes = false;

    var i = 0;
    while (i < text.length) {
      final ch = text[i];

      if (inQuotes) {
        if (ch == '"') {
          final nextIsQuote = i + 1 < text.length && text[i + 1] == '"';
          if (nextIsQuote) {
            cell.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
        } else {
          cell.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == delim) {
          row.add(cell.toString().trim());
          cell = StringBuffer();
        } else if (ch == '\n') {
          row.add(cell.toString().trim());
          cell = StringBuffer();
          if (row.any((value) => value.isNotEmpty)) {
            rows.add(List<String>.from(row));
          }
          row.clear();
        } else {
          cell.write(ch);
        }
      }
      i++;
    }

    row.add(cell.toString().trim());
    if (row.any((value) => value.isNotEmpty)) {
      rows.add(List<String>.from(row));
    }

    return rows;
  }

  bool _isHeaderRow(List<String> row) {
    final normalized = row.map(_normalizeHeader).toSet();
    return normalized.any((cell) =>
        _headerAliases['date']!.contains(cell) ||
        _headerAliases['note']!.contains(cell) ||
        _headerAliases['entity']!.contains(cell));
  }

  int _columnIndex(List<String> header, String kind, {required int fallback}) {
    if (header.isEmpty) return fallback;
    for (var i = 0; i < header.length; i++) {
      if (_headerAliases[kind]!.contains(_normalizeHeader(header[i]))) {
        return i;
      }
    }
    return fallback;
  }

  BulkEventImportRow _parseRow(
    List<String> row, {
    required int lineNumber,
    required String delimiter,
    required int dateIndex,
    required int noteIndex,
    required int entityIndex,
    required bool useHeaderMapping,
  }) {
    if (row.every((cell) => cell.trim().isEmpty)) {
      return BulkEventImportRow(
        lineNumber: lineNumber,
        date: null,
        note: '',
        entityNames: const [],
        rawDate: '',
        rawEntities: '',
        error: 'Empty row',
      );
    }

    final maxIndex = row.length - 1;
    final dateRaw = _getCell(row, useHeaderMapping ? dateIndex : 0);
    final noteRaw = useHeaderMapping
        ? _headerNoteValue(row, noteIndex, entityIndex, delimiter)
        : _plainNoteValue(row, delimiter);
    final entityRaw = useHeaderMapping
        ? _headerEntityValue(row, entityIndex)
        : (row.length >= 3 ? _getCell(row, maxIndex) : '');

    final parsedDate = _parseDate(dateRaw);
    if (parsedDate == null) {
      return BulkEventImportRow(
        lineNumber: lineNumber,
        date: null,
        note: noteRaw.trim(),
        entityNames: _splitEntities(entityRaw),
        rawDate: dateRaw,
        rawEntities: entityRaw,
        error: 'Could not parse date: ${dateRaw.trim()}',
      );
    }

    if (noteRaw.trim().isEmpty) {
      return BulkEventImportRow(
        lineNumber: lineNumber,
        date: parsedDate,
        note: '',
        entityNames: _splitEntities(entityRaw),
        rawDate: dateRaw,
        rawEntities: entityRaw,
        error: 'Missing note text',
      );
    }

    return BulkEventImportRow(
      lineNumber: lineNumber,
      date: parsedDate,
      note: noteRaw.trim(),
      entityNames: _splitEntities(entityRaw),
      rawDate: dateRaw,
      rawEntities: entityRaw,
    );
  }

  String _getCell(List<String> row, int index, {String fallback = ''}) {
    if (index < 0 || index >= row.length) return fallback;
    return row[index];
  }

  String _plainNoteValue(List<String> row, String delimiter) {
    if (row.length <= 2) {
      return row.length >= 2 ? row[1] : '';
    }
    return row.sublist(1, row.length - 1).join(delimiter);
  }

  String _joinRange(List<String> row, int start, int endInclusive, String delimiter) {
    if (row.isEmpty) return '';
    final startIndex = start.clamp(0, row.length - 1);
    final endIndex = endInclusive.clamp(startIndex, row.length - 1);
    return row.sublist(startIndex, endIndex + 1).join(delimiter);
  }

  String _headerNoteValue(List<String> row, int noteIndex, int entityIndex, String delimiter) {
    if (noteIndex < 0 || noteIndex >= row.length) return '';
    if (entityIndex < 0 || entityIndex >= row.length) return row[noteIndex];
    if (entityIndex - noteIndex <= 1) return row[noteIndex];

    if (row.length > entityIndex + 1) {
      return row.sublist(noteIndex, row.length - 1).join(delimiter);
    }

    return row.sublist(noteIndex, entityIndex).join(delimiter);
  }

  String _headerEntityValue(List<String> row, int entityIndex) {
    if (entityIndex < 0 || row.isEmpty) return '';
    if (row.length > entityIndex + 1) {
      return row.last;
    }
    if (entityIndex < row.length) {
      return row[entityIndex];
    }
    return '';
  }

  DateTime? _parseDate(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    for (final pattern in _dateFormats) {
      try {
        return DateFormat(pattern).parseStrict(text);
      } catch (_) {
        // Try next format.
      }
    }
    return null;
  }

  List<String> _splitEntities(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];
    return text
        .split(RegExp(r'[;|/]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  String _normalizeHeader(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String _normalizeName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

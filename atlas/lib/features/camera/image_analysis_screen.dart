import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _LabelBox {
  Rect rect; // normalised 0..1
  String label;
  _LabelBox({required this.rect, required this.label});

  Map<String, dynamic> toJson() => {
        'l': rect.left,
        't': rect.top,
        'r': rect.right,
        'b': rect.bottom,
        'label': label,
      };

  factory _LabelBox.fromJson(Map<String, dynamic> j) => _LabelBox(
        rect: Rect.fromLTRB(
            (j['l'] as num).toDouble(),
            (j['t'] as num).toDouble(),
            (j['r'] as num).toDouble(),
            (j['b'] as num).toDouble()),
        label: j['label'] as String,
      );
}

class _FaceTag {
  Rect rect; // normalised 0..1
  String? entityName;
  _FaceTag({required this.rect, this.entityName});

  Map<String, dynamic> toJson() => {
        'l': rect.left,
        't': rect.top,
        'r': rect.right,
        'b': rect.bottom,
        'name': entityName,
      };

  factory _FaceTag.fromJson(Map<String, dynamic> j) => _FaceTag(
        rect: Rect.fromLTRB(
            (j['l'] as num).toDouble(),
            (j['t'] as num).toDouble(),
            (j['r'] as num).toDouble(),
            (j['b'] as num).toDouble()),
        entityName: j['name'] as String?,
      );
}

// ── Entry point ───────────────────────────────────────────────────────────────

class ImageAnalysisScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const ImageAnalysisScreen({super.key, required this.imagePath});

  @override
  ConsumerState<ImageAnalysisScreen> createState() =>
      _ImageAnalysisScreenState();
}

class _ImageAnalysisScreenState extends ConsumerState<ImageAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // shared image size (resolved after first frame)
  ui.Image? _uiImage;

  // ── label state
  final List<_LabelBox> _labels = [];
  Offset? _dragStart;
  Offset? _dragCurrent;

  // ── OCR state
  String _ocrText = '';
  bool _ocrRunning = false;

  // ── face state
  final List<_FaceTag> _faces = [];
  bool _faceRunning = false;

  static const _settingsPrefix = 'annotation:';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadImage();
    _loadSaved();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _uiImage = frame.image);
  }

  String get _settingsKey => '$_settingsPrefix${widget.imagePath}';

  Future<void> _loadSaved() async {
    final db = ref.read(databaseProvider);
    final raw = await db.getSetting(_settingsKey);
    if (raw == null || !mounted) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _labels.addAll((json['labels'] as List? ?? [])
          .map((e) => _LabelBox.fromJson(e as Map<String, dynamic>)));
      _faces.addAll((json['faces'] as List? ?? [])
          .map((e) => _FaceTag.fromJson(e as Map<String, dynamic>)));
      _ocrText = json['ocr'] as String? ?? '';
    });
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    await db.setSetting(
      _settingsKey,
      jsonEncode({
        'labels': _labels.map((e) => e.toJson()).toList(),
        'faces': _faces.map((e) => e.toJson()).toList(),
        'ocr': _ocrText,
      }),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annotations saved'), duration: Duration(seconds: 1)),
      );
    }
  }

  // ── OCR ───────────────────────────────────────────────────────────────────

  Future<void> _runOcr() async {
    setState(() => _ocrRunning = true);
    try {
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      if (mounted) setState(() => _ocrText = result.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  // ── Face detection ────────────────────────────────────────────────────────

  Future<void> _runFaceDetection() async {
    final img = _uiImage;
    if (img == null) return;
    setState(() => _faceRunning = true);
    try {
      final detector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
      );
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final detected = await detector.processImage(inputImage);
      await detector.close();

      final w = img.width.toDouble();
      final h = img.height.toDouble();

      final newFaces = detected.map((f) {
        final b = f.boundingBox;
        return _FaceTag(
          rect: Rect.fromLTRB(b.left / w, b.top / h, b.right / w, b.bottom / h),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _faces
            ..clear()
            ..addAll(newFaces);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face detection failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _faceRunning = false);
    }
  }

  // ── Label drawing helpers ─────────────────────────────────────────────────

  Rect _normalise(Offset a, Offset b, Size canvas) {
    final l = (a.dx < b.dx ? a.dx : b.dx) / canvas.width;
    final t = (a.dy < b.dy ? a.dy : b.dy) / canvas.height;
    final r = (a.dx > b.dx ? a.dx : b.dx) / canvas.width;
    final bo = (a.dy > b.dy ? a.dy : b.dy) / canvas.height;
    return Rect.fromLTRB(l.clamp(0, 1), t.clamp(0, 1), r.clamp(0, 1), bo.clamp(0, 1));
  }

  Future<void> _promptLabel(Rect normRect) async {
    final ctrl = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Label this region'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. John, laptop, contract'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (label != null && label.isNotEmpty) {
      setState(() => _labels.add(_LabelBox(rect: normRect, label: label)));
    }
  }

  Future<void> _promptFaceName(_FaceTag face) async {
    final ctrl = TextEditingController(text: face.entityName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Name this person'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Entity name or person name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null) {
      setState(() => face.entityName = name.isEmpty ? null : name);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save annotations',
            onPressed: _save,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.label_outline), text: 'Label'),
            Tab(icon: Icon(Icons.text_fields), text: 'OCR'),
            Tab(icon: Icon(Icons.face_outlined), text: 'Faces'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _LabelTab(
            imagePath: widget.imagePath,
            labels: _labels,
            dragStart: _dragStart,
            dragCurrent: _dragCurrent,
            onDragStart: (o) => setState(() => _dragStart = o),
            onDragUpdate: (o) => setState(() => _dragCurrent = o),
            onDragEnd: (size) async {
              if (_dragStart != null && _dragCurrent != null) {
                final rect = _normalise(_dragStart!, _dragCurrent!, size);
                setState(() {
                  _dragStart = null;
                  _dragCurrent = null;
                });
                if (rect.width > 0.02 && rect.height > 0.02) {
                  await _promptLabel(rect);
                }
              }
            },
            onDeleteLabel: (i) => setState(() => _labels.removeAt(i)),
          ),
          _OcrTab(
            imagePath: widget.imagePath,
            ocrText: _ocrText,
            running: _ocrRunning,
            onRun: _runOcr,
            onSaveNote: _ocrText.isNotEmpty ? () => _saveOcrAsNote() : null,
          ),
          _FaceTab(
            imagePath: widget.imagePath,
            faces: _faces,
            running: _faceRunning,
            onRun: _runFaceDetection,
            onTapFace: _promptFaceName,
          ),
        ],
      ),
    );
  }

  Future<void> _saveOcrAsNote() async {
    await Clipboard.setData(ClipboardData(text: _ocrText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR text copied to clipboard')),
      );
    }
  }
}

// ── Label Tab ─────────────────────────────────────────────────────────────────

class _LabelTab extends StatelessWidget {
  final String imagePath;
  final List<_LabelBox> labels;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final void Function(Offset) onDragStart;
  final void Function(Offset) onDragUpdate;
  final void Function(Size) onDragEnd;
  final void Function(int) onDeleteLabel;

  const _LabelTab({
    required this.imagePath,
    required this.labels,
    required this.dragStart,
    required this.dragCurrent,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDeleteLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            'Drag to draw a box, then type a label. Tap a label to delete it.',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onPanStart: (d) => onDragStart(d.localPosition),
              onPanUpdate: (d) => onDragUpdate(d.localPosition),
              onPanEnd: (_) => onDragEnd(size),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath), fit: BoxFit.contain),
                  CustomPaint(
                    painter: _BoxPainter(
                      labels: labels,
                      dragStart: dragStart,
                      dragCurrent: dragCurrent,
                      canvasSize: size,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // Tap targets for existing labels
                  ...labels.asMap().entries.map((e) {
                    final box = e.value;
                    return Positioned(
                      left: box.rect.left * size.width,
                      top: box.rect.top * size.height,
                      child: GestureDetector(
                        onTap: () => onDeleteLabel(e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: Colors.black54,
                          child: Text(
                            '${box.label} ✕',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<_LabelBox> labels;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Size canvasSize;
  final Color color;

  const _BoxPainter({
    required this.labels,
    required this.dragStart,
    required this.dragCurrent,
    required this.canvasSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final box in labels) {
      canvas.drawRect(
        Rect.fromLTRB(
          box.rect.left * size.width,
          box.rect.top * size.height,
          box.rect.right * size.width,
          box.rect.bottom * size.height,
        ),
        paint,
      );
    }

    if (dragStart != null && dragCurrent != null) {
      canvas.drawRect(
        Rect.fromPoints(dragStart!, dragCurrent!),
        paint..color = color.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => true;
}

// ── OCR Tab ───────────────────────────────────────────────────────────────────

class _OcrTab extends StatelessWidget {
  final String imagePath;
  final String ocrText;
  final bool running;
  final VoidCallback onRun;
  final VoidCallback? onSaveNote;

  const _OcrTab({
    required this.imagePath,
    required this.ocrText,
    required this.running,
    required this.onRun,
    required this.onSaveNote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PhotoView(
            imageProvider: FileImage(File(imagePath)),
            minScale: PhotoViewComputedScale.contained,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: running ? null : onRun,
                  icon: running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.text_fields),
                  label: Text(running ? 'Extracting…' : 'Extract Text'),
                ),
              ),
              if (onSaveNote != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onSaveNote,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy'),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ocrText.isEmpty
              ? Center(
                  child: Text(
                    'Tap "Extract Text" to run OCR',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SelectableText(
                    ocrText,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Face Tab ──────────────────────────────────────────────────────────────────

class _FaceTab extends StatelessWidget {
  final String imagePath;
  final List<_FaceTag> faces;
  final bool running;
  final VoidCallback onRun;
  final void Function(_FaceTag) onTapFace;

  const _FaceTab({
    required this.imagePath,
    required this.faces,
    required this.running,
    required this.onRun,
    required this.onTapFace,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (_, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(imagePath), fit: BoxFit.contain),
                CustomPaint(
                  painter: _FacePainter(faces: faces, color: Colors.greenAccent),
                ),
                ...faces.map((f) => Positioned(
                      left: f.rect.left * size.width,
                      top: f.rect.top * size.height,
                      child: GestureDetector(
                        onTap: () => onTapFace(f),
                        child: Container(
                          width: (f.rect.right - f.rect.left) * size.width,
                          height: (f.rect.bottom - f.rect.top) * size.height,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.greenAccent, width: 2),
                          ),
                          alignment: Alignment.bottomLeft,
                          child: f.entityName != null
                              ? Container(
                                  color: Colors.black54,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: Text(
                                    f.entityName!,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                )
                              : Container(
                                  color: Colors.black38,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: const Text('tap to name',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 9)),
                                ),
                        ),
                      ),
                    )),
              ],
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: running ? null : onRun,
            icon: running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.face_outlined),
            label: Text(running
                ? 'Detecting…'
                : faces.isEmpty
                    ? 'Detect Faces'
                    : 'Re-detect Faces'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: Colors.green.shade700,
            ),
          ),
        ),
        if (faces.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: faces.map((f) {
                final label = f.entityName ?? '?';
                return ActionChip(
                  avatar: const Icon(Icons.face, size: 16),
                  label: Text(label),
                  onPressed: () => onTapFace(f),
                  backgroundColor: scheme.secondaryContainer,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _FacePainter extends CustomPainter {
  final List<_FaceTag> faces;
  final Color color;

  const _FacePainter({required this.faces, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final f in faces) {
      canvas.drawRect(
        Rect.fromLTRB(
          f.rect.left * size.width,
          f.rect.top * size.height,
          f.rect.right * size.width,
          f.rect.bottom * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) => true;
}

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

/// Opens the camera. After capture shows a preview where the user can
/// save to gallery and/or return the path to the caller.
Future<String?> openCameraCapture(BuildContext context) {
  return Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const CameraScreen()),
  );
}

// ---------------------------------------------------------------------------
// Camera viewfinder
// ---------------------------------------------------------------------------

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found';
          _loading = false;
        });
        return;
      }
      await _startCamera(0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startCamera(int index) async {
    await _controller?.dispose();
    final ctrl = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _selectedIndex = index;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null ||
        !ctrl.value.isInitialized ||
        ctrl.value.isTakingPicture) return;
    try {
      final file = await ctrl.takePicture();
      if (!mounted) return;
      // Pause preview while showing the result
      await ctrl.pausePreview();
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => _PreviewScreen(imagePath: file.path),
        ),
      );
      if (!mounted) return;
      if (result != null) {
        // User tapped "Use" — return path all the way back to the caller
        Navigator.pop(context, result);
      } else {
        // User discarded — resume viewfinder
        await ctrl.resumePreview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Capture failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_selectedIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  String _cameraLabel(CameraLensDirection dir, int index) => switch (dir) {
        CameraLensDirection.front => 'Front Camera',
        CameraLensDirection.back => 'Back Camera',
        CameraLensDirection.external => 'External Camera $index',
      };

  IconData _lensIcon(CameraLensDirection dir) => switch (dir) {
        CameraLensDirection.front => Icons.face_outlined,
        CameraLensDirection.back => Icons.camera_rear_outlined,
        CameraLensDirection.external => Icons.usb_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Camera'),
        actions: [
          if (_cameras.length > 1)
            PopupMenuButton<int>(
              icon: const Icon(Icons.switch_camera_outlined,
                  color: Colors.white),
              tooltip: 'Switch camera',
              onSelected: _startCamera,
              itemBuilder: (_) => _cameras.asMap().entries.map((e) {
                final cam = e.value;
                return PopupMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(_lensIcon(cam.lensDirection), size: 18),
                      const SizedBox(width: 8),
                      Text(_cameraLabel(cam.lensDirection, e.key)),
                      if (e.key == _selectedIndex) ...[
                        const Spacer(),
                        const Icon(Icons.check, size: 16),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (_loading || _error != null)
          ? null
          : GestureDetector(
              onTap: _capture,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white24,
                ),
                child:
                    const Icon(Icons.camera, color: Colors.white, size: 36),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
          child:
              Text(_error!, style: const TextStyle(color: Colors.white)));
    }
    final ctrl = _controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(ctrl),
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _cameraLabel(
                    _cameras[_selectedIndex].lensDirection, _selectedIndex),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Post-capture preview
// ---------------------------------------------------------------------------

class _PreviewScreen extends StatefulWidget {
  final String imagePath;
  const _PreviewScreen({required this.imagePath});

  @override
  State<_PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<_PreviewScreen> {
  bool _saving = false;
  bool _savedToGallery = false;

  Future<void> _saveToGallery() async {
    setState(() => _saving = true);
    try {
      await Gal.putImage(widget.imagePath, album: 'Atlas');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savedToGallery = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to gallery'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retake',
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: InteractiveViewer(
        child: Center(
          child: Image.file(File(widget.imagePath)),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Save to gallery
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving || _savedToGallery ? null : _saveToGallery,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _savedToGallery
                              ? Icons.check_circle_outline
                              : Icons.save_alt_outlined,
                          color: Colors.white,
                        ),
                  label: Text(
                    _savedToGallery ? 'Saved' : 'Save to Gallery',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _savedToGallery ? Colors.green : Colors.white54,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Use / attach
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, widget.imagePath),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Use'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

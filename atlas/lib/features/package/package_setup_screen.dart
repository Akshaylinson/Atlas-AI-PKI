import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/atlas_package_service.dart';
import '../shell/main_shell.dart';

class PackageSetupScreen extends StatefulWidget {
  const PackageSetupScreen({super.key});

  @override
  State<PackageSetupScreen> createState() => _PackageSetupScreenState();
}

class _PackageSetupScreenState extends State<PackageSetupScreen> {
  final _nameCtrl = TextEditingController(text: 'MyLife');
  bool _loading = false;
  String _status = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createNew() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() { _loading = true; _status = 'Creating package…'; });
    try {
      await AtlasPackageService.createNewPackage(name);
      _launch();
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _importPackage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    setState(() { _loading = true; _status = 'Importing package…'; });
    try {
      await AtlasPackageService.importPackage(path);
      _launch();
    } catch (e) {
      _showError('$e');
    }
  }

  void _launch() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _showError(String msg) {
    setState(() { _loading = false; _status = ''; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_status, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.psychology, size: 72, color: scheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to Atlas',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your data lives in a portable Atlas Package.\nCreate a new one or import an existing package.',
                    style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Create new
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.add_circle_outline, color: scheme.primary),
                          const SizedBox(width: 8),
                          const Text('Create New Package',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                        ]),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Package name',
                            hintText: 'e.g. MyLife',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _createNew,
                            child: const Text('Create & Start'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.4))),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),

                  // Import existing
                  OutlinedButton.icon(
                    onPressed: _importPackage,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Import Existing Package (.atlas)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select a .atlas file or a previously created package folder.',
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.4)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

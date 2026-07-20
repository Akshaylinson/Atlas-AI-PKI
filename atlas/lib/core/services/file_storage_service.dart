import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import '../models/models.dart';

class FileStorageService {
  static const _uuid = Uuid();

  Future<String> get _baseDir async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'atlas_files');
  }

  Future<Attachment> saveFile(File sourceFile, {String? customName}) async {
    final base = await _baseDir;
    final mimeType = lookupMimeType(sourceFile.path) ?? 'application/octet-stream';
    final type = _typeFromMime(mimeType);
    final ext = p.extension(sourceFile.path);
    final id = _uuid.v4();
    final fileName = customName ?? '$id$ext';

    final subDir = Directory(p.join(base, type.name));
    await subDir.create(recursive: true);

    final destPath = p.join(subDir.path, fileName);
    await sourceFile.copy(destPath);

    return Attachment(
      id: id,
      path: destPath,
      type: type,
      name: customName ?? p.basename(sourceFile.path),
      sizeBytes: await sourceFile.length(),
    );
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  Future<bool> fileExists(String filePath) => File(filePath).exists();

  AttachmentType _typeFromMime(String mime) {
    if (mime.startsWith('image/')) return AttachmentType.image;
    if (mime.startsWith('video/')) return AttachmentType.video;
    if (mime.startsWith('audio/')) return AttachmentType.audio;
    if (mime == 'application/pdf') return AttachmentType.pdf;
    return AttachmentType.document;
  }
}

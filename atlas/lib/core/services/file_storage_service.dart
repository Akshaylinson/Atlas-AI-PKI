import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import '../models/models.dart';
import '../services/atlas_package_service.dart';

class FileStorageService {
  static const _uuid = Uuid();

  Future<Attachment> saveFile(File sourceFile, {String? customName}) async {
    final mimeType =
        lookupMimeType(sourceFile.path) ?? 'application/octet-stream';
    final type = _typeFromMime(mimeType);
    final ext = p.extension(sourceFile.path);
    final id = _uuid.v4();
    final fileName = customName ?? '$id$ext';

    final String baseDir;
    if (type == AttachmentType.audio) {
      baseDir = await AtlasPackageService.getAudioDir();
    } else {
      final attachDir = await AtlasPackageService.getAttachmentsDir();
      final subFolder = type == AttachmentType.image
          ? 'images'
          : type == AttachmentType.pdf || type == AttachmentType.document
              ? 'documents'
              : 'others';
      baseDir = p.join(attachDir, subFolder);
    }

    await Directory(baseDir).create(recursive: true);
    final destPath = p.join(baseDir, fileName);
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

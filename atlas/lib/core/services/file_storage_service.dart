import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import '../models/models.dart';
import 'atlas_package_service.dart';

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
      baseDir = await AtlasPackageService.getAudioPath();
    } else if (type == AttachmentType.video) {
      baseDir = await AtlasPackageService.getVideoPath();
    } else {
      baseDir = type == AttachmentType.image
          ? await AtlasPackageService.getImagesPath()
          : await AtlasPackageService.getDocumentsPath();
    }

    await Directory(baseDir).create(recursive: true);
    final destPath = p.join(baseDir, fileName);
    await sourceFile.copy(destPath);
    final relativePath = await AtlasPackageService.relativePathOf(destPath);

    return Attachment(
      id: id,
      path: relativePath,
      type: type,
      name: customName ?? p.basename(sourceFile.path),
      sizeBytes: await sourceFile.length(),
    );
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(await AtlasPackageService.resolvePath(filePath));
    if (await file.exists()) await file.delete();
  }

  Future<bool> fileExists(String filePath) async {
    return File(await AtlasPackageService.resolvePath(filePath)).exists();
  }

  AttachmentType _typeFromMime(String mime) {
    if (mime.startsWith('image/')) return AttachmentType.image;
    if (mime.startsWith('video/')) return AttachmentType.video;
    if (mime.startsWith('audio/')) return AttachmentType.audio;
    if (mime == 'application/pdf') return AttachmentType.pdf;
    return AttachmentType.document;
  }
}

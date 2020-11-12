import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'platform_custom.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../common/data.dart';
import 'package:mime/mime.dart' as mime;
import 'common.dart';

bool isDirectory(String path) {
  final dir = io.Directory(path);
  if (dir.existsSync()) {
    return true;
  }
  return false;
}

String lookupMimeType(String path) {
  if (isDirectory(path)) {
    return 'directory';
  }
  return mime.lookupMimeType(path);
}

int lastModified(String path) {
  if (isDirectory(path)) {
    return 0;
  }
  return io.File(path).lastModifiedSync().millisecondsSinceEpoch ~/ 1000;
}

int length(String path) {
  if (isDirectory(path)) {
    return 0;
  }
  return io.File(path).lengthSync();
}

Future<String> getTargetPath(String relativePath) async {
  final appDocDir = await getExternalStorageDirectory();
  return path.join(appDocDir.path, relativePath);
}

Future<bool> checkFileExists(String relativePath) async {
  return await io.File(await getTargetPath(relativePath)).exists();
}

Future<File> createFileByFileResult(FileResult fileResult) async {
  final f = io.File(fileResult.uri);
  final targetPath = await getTargetPath(fileResult.fileName);
  if (await io.File(targetPath).exists()) {
    return null;
  }
  final newFile = await f.copy(targetPath);
  return File(
    fileResult.fileName,
    newFile.path,
    lookupMimeType(newFile.path),
    json.encode(FileExtra(
      newFile.lastModifiedSync().millisecondsSinceEpoch ~/ 1000,
      newFile.lengthSync(),
    ).toMap()),
    null,
  );
}

Future<List<File>> listFile(String relativePath) async {
  final targetPath = await getTargetPath(relativePath);
  final targetFile = io.Directory(targetPath);
  if (!targetFile.existsSync()) {
    return List<File>();
  }
  try {
    return (await targetFile.list().toList()).map((value) {
      final f = io.File(value.path);
      return File(
        CommonUtils.getFileNameByUri(f.path),
        f.path,
        lookupMimeType(f.path),
        json.encode(FileExtra(
          lastModified(value.path),
          length(value.path),
        ).toMap()),
        null,
      );
    }).toList();
  } catch (e) {
    return null;
  }
}
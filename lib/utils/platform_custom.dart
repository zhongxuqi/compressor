import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

const platform = const MethodChannel('com.musketeer.compressor');

class FileResult {
  String archiveType;
  String fileName;
  String uri;

  FileResult(this.archiveType, this.fileName, this.uri);

  Map toMap() {
    return {
      'archive_type': archiveType,
      'file_name': fileName,
      'uri': uri,
    };
  }

  static FileResult fromMap(Map m) {
    return FileResult(m['archive_type'], m['file_name'], m['uri']);
  }
}

Future<List<FileResult>> pickFile({@required String mimeType}) async {
  try {
    var result = await platform.invokeMethod('pick_file', {
      'mime_type': mimeType,
    });
    final rawResultList = json.decode(result.toString());
    final fileResultList = List<FileResult>();
    for (var item in rawResultList) {
      fileResultList.add(FileResult.fromMap(item));
    }
    return fileResultList;
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return List<FileResult>();
}

Future<FileResult> createArchiveFile(params) async {
  try {
    var result = await platform.invokeMethod('create_archive', params);
    final fileResult = json.decode(result.toString());
    return FileResult(fileResult['archive_type'], fileResult['file_name'], fileResult['uri']);
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return FileResult("", "", "");
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

const platform = const MethodChannel('com.musketeer.compressor');

class FileResult {
  String fileName;
  String uri;

  FileResult(this.fileName, this.uri);

  Map toMap() {
    return {
      'file_name': fileName,
      'uri': uri,
    };
  }

  static FileResult fromMap(Map m) {
    return FileResult(m['file_name'], m['uri']);
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
}
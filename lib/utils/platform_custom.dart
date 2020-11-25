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

class FileHeader {
  final String fileName;
  final bool isDirectory;
  final String contentType;
  final int lastModified;
  final int fileSize;

  FileHeader({@required this.fileName, @required this.isDirectory, @required this.contentType, @required this.lastModified, @required this.fileSize});
}

Future<List<FileHeader>> getFileHeaders(String uri, String password) async {
  try {
    var result = await platform.invokeMethod('get_file_headers', {
      'uri': uri,
      'password': password,
    });
    final rawFileHeaders = json.decode(result.toString()) as List<dynamic>;
    return rawFileHeaders.map((e) {
      return FileHeader(
        fileName: e['fileName'],
        isDirectory: e['isDirectory'],
        contentType: e['contentType'],
        lastModified: e['lastModified'],
        fileSize: e['fileSize'],
      );
    }).toList();
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return List<FileHeader>();
}

class ExtractRes {
  final String errCode;
  final String targetUri;

  ExtractRes({@required this.errCode, @required this. targetUri});
}

Future<ExtractRes> extractFile(String uri, String password, String fileName) async {
  try {
    var result = await platform.invokeMethod('extract_file', {
      'uri': uri,
      'password': password,
      'file_name': fileName,
    });
    final resJson = json.decode(result.toString()) as Map<String, dynamic>;
    return ExtractRes(errCode: resJson['err_code'], targetUri: resJson['target_uri']);
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return ExtractRes(errCode: 'unzip_error', targetUri: '');
}

Future<ExtractRes> extractAll(String uri, String password, String targetDir) async {
  try {
    var result = await platform.invokeMethod('extract_all', {
      'uri': uri,
      'password': password,
      'target_dir': targetDir,
    });
    final resJson = json.decode(result.toString()) as Map<String, dynamic>;
    return ExtractRes(errCode: resJson['err_code'], targetUri: resJson['target_uri']);
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return ExtractRes(errCode: 'unzip_error', targetUri: '');
}

void feedback() async {
  try {
    var result = await platform.invokeMethod('feedback', {});
    result.toString();
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
}
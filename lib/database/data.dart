import 'package:flutter/material.dart';
import 'dart:convert';

enum FileType {
  none,
  file,
  directory,
}

int fileType2Int(FileType fileType) {
  switch (fileType) {
    case FileType.file:
      return 1;
    case FileType.directory:
      return 2;
    default:
      return 0;
  }
}

class File {
  int id;
  FileType type;
  String name;
  String uri;
  int parentID;
  String contentType;
  String extra;
  int createTime;
  int updateTime;

  File(this.id, this.type, this.name, this.uri, this.parentID, this.contentType,
      this.extra, this.createTime, this.updateTime);

  FileExtra _extraObj;

  FileExtra get extraObj {
    if (_extraObj == null) {
      _extraObj = FileExtra.fromMap(json.decode(extra));
    }
    return _extraObj;
  }
}

class FileExtra {
  int lastModified;
  int fileSize;
  String mimeType;

  FileExtra(this.lastModified, this.fileSize, this.mimeType);

  Map toMap() {
    return {
      'last_modified': lastModified,
      'file_size': fileSize,
      'mime_type': mimeType,
    };
  }

  static FileExtra fromMap(Map m) {
    return FileExtra(m['last_modified'], m['file_size'], m['mime_type']);
  }
}
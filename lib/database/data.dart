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

FileType int2FileType(int fileType) {
  switch (fileType) {
    case 1:
      return FileType.file;
    case 2:
      return FileType.directory;
    default:
      return FileType.none;
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

  Map toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'uri': uri,
      'parent_id': parentID,
      'content_type': contentType,
      'extra': extra,
      'create_time': createTime,
      'update_time': updateTime,
    };
  }
}

class FileExtra {
  int lastModified;
  int fileSize;

  FileExtra(this.lastModified, this.fileSize);

  Map toMap() {
    return {
      'last_modified': lastModified,
      'file_size': fileSize,
    };
  }

  static FileExtra fromMap(Map m) {
    return FileExtra(m['last_modified'], m['file_size']);
  }
}
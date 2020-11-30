import 'package:flutter/material.dart';
import 'dart:convert';

enum SortBy { name, time }

enum SortType { asc, desc }

class File {
  String name;
  String uri;
  String contentType;
  String extra;
  Map<String, File> files;
  File parent;

  File(this.name, this.uri, this.contentType, this.extra, this.parent) {
    files = Map<String, File>();
  }

  FileExtra _extraObj;

  FileExtra get extraObj {
    if (_extraObj == null) {
      _extraObj = FileExtra.fromMap(json.decode(extra));
    }
    return _extraObj;
  }

  Map toMap() {
    return {
      'name': name,
      'uri': uri,
      'content_type': contentType,
      'extra': extra,
      'files': files.map((key, value) {
        return MapEntry(key, value.toMap());
      }),
    };
  }

  File clone() {
    return File(name, uri, contentType, extra, parent);
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
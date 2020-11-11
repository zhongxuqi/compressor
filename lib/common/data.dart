import 'package:flutter/material.dart';
import 'dart:convert';

class File {
  String name;
  String uri;
  String contentType;
  String extra;

  File(this.name, this.uri, this.contentType, this.extra);

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
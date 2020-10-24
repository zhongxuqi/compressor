import 'package:flutter/material.dart';

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
  int parentID;
  String contentType;
  String extra;
  int createTime;
  int updateTime;

  File(this.id, this.type, this.name, this.parentID, this.contentType,
      this.extra, this.createTime, this.updateTime);
}

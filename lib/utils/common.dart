import 'package:flutter/material.dart';
import 'package:path/path.dart';

class CommonUtils {
  static int getTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  static String getFileNameByUri(String uri) {
    return basename(Uri.decodeFull(uri));
  }

  static String formatTimestamp(int timestamp) {
    if (timestamp <= 0) return '';
    final lastModifiedDatetime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${lastModifiedDatetime.year.toString()}-"
        "${lastModifiedDatetime.month.toString().padLeft(2,'0')}-"
        "${lastModifiedDatetime.day.toString().padLeft(2,'0')} "
        "${lastModifiedDatetime.hour.toString().padLeft(2, '0')}:"
        "${lastModifiedDatetime.minute.toString().padLeft(2, '0')}:"
        "${lastModifiedDatetime.second.toString().padLeft(2, '0')}";
  }

  static String formatFileSize(int fileSize) {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) {
      return "${fileSize.toStringAsFixed(1)}B";
    } else if (fileSize < 1024 * 1024) {
      return "${(fileSize / 1024).toStringAsFixed(1)}KB";
    } else if (fileSize < 1024 * 1024 * 1024) {
      return "${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB";
    }
    return "${(fileSize / 1024 / 1024 / 1024).toStringAsFixed(1)}GB";
  }
}
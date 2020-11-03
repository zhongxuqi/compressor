import 'package:flutter/material.dart';

class MimeUtils {
  static final _mime2IconMap = {
    'text': 'images/file_txt.png',
    'image': 'images/file_pic.png',
    'video': 'images/file_video.png',
  };

  static String getIconByMime(String mimeType) {
    for (var key in _mime2IconMap.keys) {
      if (mimeType.startsWith(key)) {
        return _mime2IconMap[key];
      }
    }
    return 'images/file_unknow.png';
  }
}
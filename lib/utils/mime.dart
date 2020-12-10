import 'package:flutter/material.dart';

class _MimeItem {
  final String mimeType;
  final String mimeIcon;

  _MimeItem({this.mimeType, this.mimeIcon});
}

class MimeUtils {
  static final _mimeList = <_MimeItem>[
    _MimeItem(mimeType: 'text', mimeIcon: 'images/file_txt.png'),
    _MimeItem(mimeType: 'image', mimeIcon: 'images/file_pic.png'),
    _MimeItem(mimeType: 'video', mimeIcon: 'images/file_video.png'),
    _MimeItem(mimeType: 'application/pdf', mimeIcon: 'images/file_pdf.png'),
    _MimeItem(mimeType: 'application/zip', mimeIcon: 'images/file_zip.png'),
    _MimeItem(mimeType: 'application/x-rar-compressed', mimeIcon: 'images/file_zip.png'),
    _MimeItem(mimeType: 'application/x-7z-compressed', mimeIcon: 'images/file_zip.png'),
    _MimeItem(mimeType: 'directory', mimeIcon: 'images/directory.png'),
  ];

  static String getIconByMime(String mimeType) {
    for (var mimeItem in _mimeList) {
      if (mimeType.startsWith(mimeItem.mimeType)) {
        return mimeItem.mimeIcon;
      }
    }
    return 'images/file_unknown.png';
  }
}
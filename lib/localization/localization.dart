import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Map<String, Map<String, String>> _languageTextMap = {
    "main_title": {
      "en": "File Manager",
      "zh": "文件管理",
    },
    "compress_title": {
      "en": "File Compression",
      "zh": "文件压缩",
    },
    "file": {
      "en": "File",
      "zh": "文件",
    },
    "image": {
      "en": "Image",
      "zh": "图片",
    },
    "video": {
      "en": "Video",
      "zh": "视频",
    },
    "unknown_file_type": {
      "en": "Unknown File Type",
      "zh": "未知文件类型",
    },
    'zip_file_info': {
      'en': 'Archive File Info',
      'zh': '压缩文件信息',
    },
    'file_name': {
      'en': 'File Name',
      'zh': '文件名',
    },
    'input_file_name_hint': {
      'en': 'Please input file name.',
      'zh': '请输入文件名',
    },
    'archive_password': {
      'en': 'Archive File Password (Optional)',
      'zh': '压缩文件密码（选填）',
    },
    'input_password_hint': {
      'en': 'Please input archive password.',
      'zh': '请输入压缩密码',
    },
    'cancel': {
      'en': 'Cancel',
      'zh': '取消',
    },
    'confirm': {
      'en': 'Confirm',
      'zh': '确认',
    },
  };

  String getLanguageText(String textID) {
    return _languageTextMap[textID][locale.languageCode];
  }

  String getLanguage() {
    return locale.languageCode;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

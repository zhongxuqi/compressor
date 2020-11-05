import 'package:flutter/material.dart';
import 'utils/iconfonts.dart';
import './utils/colors.dart';
import './localization/localization.dart';
import './utils/platfomr_custom.dart';
import './utils/permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'database/data.dart' as data;
import 'utils/common.dart';
import 'dart:convert';
import 'components/file_item.dart';
import './file_detail.dart';
import 'components/form_text_input.dart';
import 'localization/localization.dart';

class CompressorPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CompressorPageState();
  }
}

class _CompressorPageState extends State<CompressorPage> {
  final fileTypes = <FilePicker>[
    FilePicker(FileType.file, 'images/file_txt.png', 'file'),
    FilePicker(FileType.image, 'images/file_pic.png', 'image'),
    FilePicker(FileType.video, 'images/file_video.png', 'video'),
  ];
  var files = List<data.File>();

  void pick(FileType fileType) async {
    if (!await checkPermission(<Permission>[Permission.storage])) {
      return;
    }
    switch (fileType) {
      case FileType.file:
        _pickFileByMimeType(mimeType: '*/*');
        break;
      case FileType.image:
        _pickFileByMimeType(mimeType: 'image/*');
        break;
      case FileType.video:
        _pickFileByMimeType(mimeType: 'video/*');
        break;
      default:
        break;
    }
  }

  void _pickFileByMimeType({@required String mimeType}) async {
    final fileResultList = await pickFile(mimeType: mimeType);
    Navigator.of(context).pop();
    for (var fileResult in fileResultList) {
      final f = File.fromUri(Uri.parse(fileResult.uri));
      files.add(data.File(
        0,
        data.FileType.file,
        fileResult.fileName,
        fileResult.uri,
        0,
        lookupMimeType(fileResult.uri),
        json.encode(data.FileExtra(f.lastModifiedSync().millisecondsSinceEpoch, f.lengthSync(), lookupMimeType(fileResult.uri)).toMap()),
        CommonUtils.getTimestamp(),
        CommonUtils.getTimestamp(),
      ));
    }
    setState(() {

    });
  }

  void compressFiles() async {
    showDialog(context: context, builder: (BuildContext context) {
      return SimpleDialog(
        contentPadding: EdgeInsets.only(bottom: 10),
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Text(AppLocalizations.of(context).getLanguageText('zip_file_info'),
                      style: TextStyle(
                        fontSize: 18,
                        color: ColorUtils.textColor,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  child: Container(
                    height: 40,
                    width: 50,
                    child: Icon(
                      IconFonts.close,
                      color: ColorUtils.textColor,
                      size: 22,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: ColorUtils.deepGrey,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.only(top: 0, left: 15, right: 15),
            child: FormTextInput(
              keyName: AppLocalizations.of(context).getLanguageText('file_name'),
              value: '',
              hintText: AppLocalizations.of(context).getLanguageText('input_file_name_hint'),
              maxLines: 1,
              onChange: (value) {

              },
            ),
          ),Container(
            padding: EdgeInsets.only(top: 0, left: 15, right: 15),
            child: FormTextInput(
              keyName: AppLocalizations.of(context).getLanguageText('archive_password'),
              value: '',
              hintText: AppLocalizations.of(context).getLanguageText('input_password_hint'),
              maxLines: 1,
              onChange: (value) {

              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: <Widget>[
            Container(
              height: 46.0,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        child: Container(
                          width: 45,
                          height: 45,
                          child: Icon(
                            IconFonts.back,
                            color: ColorUtils.themeColor,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        child: Icon(
                          IconFonts.zip,
                          color: ColorUtils.textColor,
                          size: 25.0,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context).getLanguageText('compress_title'),
                            style: TextStyle(
                              color: ColorUtils.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        child: Container(
                          width: 45,
                          height: 45,
                          child: Icon(
                            IconFonts.right,
                            color: ColorUtils.themeColor,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          compressFiles();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 1,
                          color: ColorUtils.divider,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                child: Column(
                  children: files.map((e) => FileItem(
                    fileData: e,
                    onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FileDetailPage(fileData: e)),
                      );
                    },
                  )).toList(),
                ),
              ),
            ),
            InkWell(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      color: ColorUtils.themeColor,
                      child: Icon(
                        IconFonts.add,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () async {
                showModalBottomSheet(context: context, builder: (context) {
                  return Container(
                    color: Colors.white,
                    height: 120,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: fileTypes.map((e) => Expanded(
                        flex: 1,
                        child: InkWell(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(e.icon, height: 50.0, width: 50.0,),
                              Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                  AppLocalizations.of(context).getLanguageText(e.name),
                                  style: TextStyle(
                                      fontSize: 15
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            pick(e.fileType);
                          },
                        ),
                      )).toList(),
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum FileType {
  file, image, video
}

class FilePicker {
  final FileType fileType;
  final String icon;
  final String name;

  FilePicker(this.fileType, this.icon, this.name);
}
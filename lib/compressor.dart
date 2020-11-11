import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/iconfonts.dart';
import './utils/colors.dart';
import './utils/platform_custom.dart';
import './utils/permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'common/data.dart' as data;
import 'utils/common.dart';
import 'dart:convert';
import 'components/file_item.dart';
import './file_detail.dart';
import 'components/form_text_input.dart';
import 'localization/localization.dart';
import 'components/loading_dialog.dart';
import 'utils/file.dart' as fileUtils;
import 'utils/toast.dart' as toastUtils;

class CompressorPage extends StatefulWidget {
  final ValueChanged<data.File> callback;

  CompressorPage({Key key, @required this.callback}): super(key: key);

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
  final GlobalKey<FormTextInputState> _fileNameInputKey = GlobalKey<FormTextInputState>();

  var files = List<data.File>();
  var fileName = '';
  var fileNameError = '';
  var password = '';
  var inSubmit = false;

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
      final contentType = lookupMimeType(fileResult.uri);
      files.add(data.File(
        fileResult.fileName,
        fileResult.uri,
        contentType,
        json.encode(data.FileExtra(f.lastModifiedSync().millisecondsSinceEpoch, f.lengthSync()).toMap()),
      ));
    }
    setState(() {

    });
  }

  void createArchive() async {
    if (inSubmit) return;
    inSubmit = true;
    var hasErr = false;
    if (fileName == "") {
      _fileNameInputKey.currentState.setTextError(AppLocalizations.of(context).getLanguageText('required'));
      hasErr = true;
    }
    if (await fileUtils.checkFileExists("$fileName.zip")) {
      _fileNameInputKey.currentState.setTextError(AppLocalizations.of(context).getLanguageText('file_exists'));
      hasErr = true;
    }
    if (hasErr) {
      setState(() {});
      inSubmit = false;
      return;
    }
    final Map<String, String> params = {
      'archive_type': 'zip',
      'file_name': "$fileName.zip",
      'password': password,
      'files': json.encode(files.map((e) {
        return {
          'file_name': e.name,
          'uri': e.uri,
        };
      }).toList()),
    };
    Navigator.of(context).pop();
    showLoadingDialog(context, AppLocalizations.of(context).getLanguageText('compressing'), barrierDismissible: true);
    final fileResult = await createArchiveFile(params);
    if (fileResult.archiveType.isNotEmpty) {
      final fileObj = await fileUtils.createFileByFileResult(fileResult);
      if (fileObj == null) {
        toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('save_failure'));
        return;
      }
      widget.callback(fileObj);
    }
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    inSubmit = false;
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
              key: _fileNameInputKey,
              keyName: AppLocalizations.of(context).getLanguageText('file_name'),
              value: fileName,
              hintText: AppLocalizations.of(context).getLanguageText('input_file_name_hint'),
              maxLines: 1,
              onChange: (value) {
                fileName = value;
                _fileNameInputKey.currentState.setTextError('');
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 0, left: 15, right: 15),
            child: FormTextInput(
              keyName: AppLocalizations.of(context).getLanguageText('archive_password'),
              value: password,
              hintText: AppLocalizations.of(context).getLanguageText('input_password_hint'),
              maxLines: 1,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]|[0-9]")),
                LengthLimitingTextInputFormatter(16),//最大长度
              ],
              onChange: (value) {
                password = value;
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 15, left: 10, right: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    child: Container(
                      margin: EdgeInsets.only(right: 10.0),
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      ),
                      child: Text(
                        AppLocalizations.of(context).getLanguageText('cancel'),
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    child: Container(
                      padding: EdgeInsets.all(5.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ColorUtils.themeColor,
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      ),
                      child: Text(
                        AppLocalizations.of(context).getLanguageText('confirm'),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onTap: () {
                      createArchive();
                    },
                  ),
                ),
              ],
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/iconfonts.dart';
import './utils/colors.dart';
import './utils/platform_custom.dart';
import './utils/permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'common/data.dart' as data;
import 'dart:convert';
import 'components/file_item.dart';
import './file_detail.dart';
import 'components/form_text_input.dart';
import 'localization/localization.dart';
import 'components/loading_dialog.dart';
import 'utils/file.dart' as fileUtils;
import 'utils/toast.dart' as toastUtils;
import 'components/location.dart';
import 'components/directory_dialog.dart' as directory_dialog;
import 'package:path/path.dart' as path;
import './file_select.dart';
import 'components/action_dialog.dart';
import 'components/action_bar.dart';
import 'components/alert_dialog.dart';

class CompressorPage extends StatefulWidget {
  final VoidCallback callback;
  final Directory dir;

  CompressorPage({Key key, @required this.callback, @required this.dir})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CompressorPageState();
  }
}

class _CompressorPageState extends State<CompressorPage> {
  final fileTypes = <FilePicker>[
    FilePicker(FileType.file, 'images/file_open.png', 'file'),
    FilePicker(FileType.image, 'images/file_pic.png', 'image'),
    FilePicker(FileType.video, 'images/file_video.png', 'video'),
    FilePicker(FileType.directory, 'images/directory.png', 'directory'),
    FilePicker(FileType.local, 'images/file_Installation_pa.png', 'local'),
  ];
  final GlobalKey<FormTextInputState> _fileNameInputKey =
      GlobalKey<FormTextInputState>();

  var files = Map<String, data.File>();
  var fileName = '';
  var fileNameError = '';
  var password = '';
  var inSubmit = false;
  data.File currentFile;
  final Set<data.File> checkedFiles = Set<data.File>();

  Map<String, data.File> getFiles() {
    return currentFile != null ? currentFile.files : files;
  }

  List<String> getDirectories() {
    final directories = List<String>();
    var indexFile = currentFile;
    while (indexFile != null) {
      directories.insert(0, indexFile.name);
      indexFile = indexFile.parent;
    }
    return directories;
  }

  void pick(FileType fileType) async {
    if (!await checkPermission(<Permission>[Permission.storage])) {
      return;
    }
    switch (fileType) {
      case FileType.directory:
        createDirectory();
        break;
      case FileType.file:
        _pickFileByMimeType(mimeType: '*/*');
        break;
      case FileType.image:
        _pickFileByMimeType(mimeType: 'image/*');
        break;
      case FileType.video:
        _pickFileByMimeType(mimeType: 'video/*');
        break;
      case FileType.local:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FileSelectPage(
            callback: (value) {
              var validFiles = value.map((e) => fileUtils.path2File(e)).toList();
              showActionDialog(
                context: context,
                actionType: ActionDialogType.rename,
                checkedFiles: validFiles,
                relativePath: null,
                excludeFileNames: getFiles().keys.toList(),
                callback: (String targetPath, Map<String, String> fileNameMap) async {
                  await addFiles(getFiles(), validFiles, fileNameMap);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  setState(() {});
                },
              );
            },
          )),
        );
        break;
      default:
        break;
    }
  }

  void _pickFileByMimeType({@required String mimeType}) async {
    Navigator.of(context).pop();
    final fileResultList = await pickFile(mimeType: mimeType);
    var validFiles = fileResultList.map((e) => fileUtils.path2File(e.uri)).toList();
    showActionDialog(
      context: context,
      actionType: ActionDialogType.rename,
      checkedFiles: validFiles,
      relativePath: null,
      excludeFileNames: getFiles().keys.toList(),
      callback: (String targetPath, Map<String, String> fileNameMap) async {
        await addFiles(getFiles(), validFiles, fileNameMap);
        Navigator.of(context).pop();
        setState(() {});
      },
    );
  }

  Future<void> addFiles(Map<String, data.File> rootNode, List<data.File> validFiles, Map<String, String> fileNameMap) async {
    validFiles.forEach((element) async {
      final contentType = fileUtils.lookupMimeType(element.uri);
      final fileName = fileNameMap!=null&&fileNameMap.containsKey(element.uri)?fileNameMap[element.uri]:element.name;
      final fileData = data.File(
        fileName,
        element.uri,
        contentType,
        element.extra,
        currentFile,
      );
      rootNode[fileName] = fileData;

      if (contentType == 'directory') {
        final filePaths = await fileUtils.listFileByAbsolute(element.uri);
        final subValidFiles = filePaths.map((e) => fileUtils.path2File(e.uri)).toList();
        await addFiles(fileData.files, subValidFiles, null);
      }
    });
  }

  void doCreateDirectory(String directoryName) async {
    getFiles()[directoryName] = data.File(
      directoryName,
      '',
      'directory',
      json.encode(data.FileExtra(0, 0).toMap()),
      currentFile,
    );
    setState(() {});
    Navigator.of(context).pop();
  }

  void createDirectory() async {
    Navigator.of(context).pop();
    directory_dialog.createDirectory(
        context: context,
        callback: doCreateDirectory,
        excludedNames: getFiles().entries.map((e) => e.value.name).toList());
  }

  Future<bool> checkFileExists(String fileName) async {
    return await File(path.join(widget.dir.path, fileName)).exists();
  }

  void createArchive() async {
    if (inSubmit) return;
    inSubmit = true;
    var hasErr = false;
    if (fileName == "") {
      _fileNameInputKey.currentState.setTextError(AppLocalizations.of(context).getLanguageText('required'));
      toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('file_name_empty'));
      hasErr = true;
    }
    if (await checkFileExists("$fileName.zip")) {
      _fileNameInputKey.currentState.setTextError(AppLocalizations.of(context).getLanguageText('file_exists'));
      toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('file_name_conflict'));
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
      'files': json.encode(files.map((key, value) {
        return MapEntry(key, value.toMap());
      })),
    };
    Navigator.of(context).pop();
    showLoadingDialog(
        context, AppLocalizations.of(context).getLanguageText('compressing'),
        barrierDismissible: true);
    final fileResult = await createArchiveFile(params);
    if (fileResult.archiveType.isNotEmpty) {
      final fileObj =
          await fileUtils.createFileByFileResult(widget.dir, fileResult);
      if (fileObj == null) {
        toastUtils.showErrorToast(
            AppLocalizations.of(context).getLanguageText('save_failure'));
        return;
      }
      widget.callback();
    }
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    inSubmit = false;
  }

  void compressFiles() async {
    fileName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                      child: Text(
                        AppLocalizations.of(context)
                            .getLanguageText('zip_file_info'),
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
                keyName:
                    AppLocalizations.of(context).getLanguageText('file_name'),
                value: fileName,
                hintText: AppLocalizations.of(context)
                    .getLanguageText('input_file_name_hint'),
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
                keyName: AppLocalizations.of(context)
                    .getLanguageText('archive_password'),
                value: password,
                hintText: AppLocalizations.of(context)
                    .getLanguageText('input_password_hint'),
                maxLines: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]|[0-9]")),
                  LengthLimitingTextInputFormatter(16), //最大长度
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
                          AppLocalizations.of(context)
                              .getLanguageText('cancel'),
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
                          AppLocalizations.of(context)
                              .getLanguageText('confirm'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionItems = <ActionItem>[];
    if (checkedFiles.length > 0) {
      actionItems.addAll(<ActionItem>[
        ActionItem(iconData: IconFonts.edit, textCode: 'rename', callback: () {
          showActionDialog(
            context: context,
            actionType: ActionDialogType.rename,
            checkedFiles: checkedFiles.toList(),
            relativePath: null,
            excludeFileNames: getFiles().keys.toList(),
            callback: (String targetPath, Map<String, String> fileNameMap) {
              checkedFiles.forEach((e) {
                e.name = fileNameMap[e.uri];
              });
              Navigator.of(context).pop();
              checkedFiles.clear();
              setState(() {});
            },
          );
        }),
        ActionItem(iconData: IconFonts.delete, textCode: 'delete', callback: () {
          showAlertDialog(context, text: AppLocalizations.of(context).getLanguageText('delete_alert'), callback: () {
            checkedFiles.forEach((e) {
              files.remove(e.name);
            });
            Navigator.of(context).pop();
            checkedFiles.clear();
            setState(() {});
          });
        }),
      ]);
    }
    actionItems.add(ActionItem(iconData: IconFonts.add, textCode: 'add', callback: () {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            color: Colors.white,
            height: 180,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: fileTypes.sublist(0, 3).map((e) => Expanded(
                    flex: 1,
                    child: InkWell(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            e.icon,
                            height: 50.0,
                            width: 50.0,
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 5),
                            child: Text(
                              AppLocalizations.of(context)
                                  .getLanguageText(e.name),
                              style: TextStyle(fontSize: 15),
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
                Container(height: 10, width: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: fileTypes.sublist(3).map((e) => Expanded(
                    flex: 1,
                    child: InkWell(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            e.icon,
                            height: 50.0,
                            width: 50.0,
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 5),
                            child: Text(
                              AppLocalizations.of(context)
                                  .getLanguageText(e.name),
                              style: TextStyle(fontSize: 15),
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
              ],
            ),
          );
        },
      );
    }));
    return WillPopScope(
      onWillPop: () async {
        if (currentFile != null) {
          setState(() {
            currentFile = currentFile.parent;
          });
        } else {
          showAlertDialog(context, text: AppLocalizations.of(context).getLanguageText('exit_edit_alert'), callback: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          });
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            children: <Widget>[
              Container(
                height: 45.0,
                child: Row(
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
                          AppLocalizations.of(context)
                              .getLanguageText('compress_title'),
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
              Location(
                directories: getDirectories(),
                goBack: () {
                  if (currentFile == null) return;
                  setState(() {
                    currentFile = currentFile.parent;
                  });
                },
              ),
              Expanded(
                flex: 1,
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverList(
                      delegate: SliverChildListDelegate(
                        getFiles().values.map((e) => FileItem(
                          fileData: e,
                          onClick: () {
                            if (e.contentType == 'directory') {
                              setState(() {
                                currentFile = e;
                              });
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FileDetailPage(fileData: e, callback: () {})),
                            );
                          },
                          checkStatus: checkedFiles.contains(e)?CheckStatus.checked:CheckStatus.unchecked,
                          onCheck: () {
                            setState(() {
                              if (checkedFiles.contains(e)) {
                                checkedFiles.remove(e);
                              } else {
                                checkedFiles.add(e);
                              }
                            });
                          },
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              ActionBar(actionItems: actionItems),
            ],
          ),
        ),
      ),
    );
  }
}

enum FileType { file, image, video, directory, local }

class FilePicker {
  final FileType fileType;
  final String icon;
  final String name;

  FilePicker(this.fileType, this.icon, this.name);
}

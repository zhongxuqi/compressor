import 'package:compressor/utils/platform_custom.dart';
import 'package:compressor/utils/toast.dart';
import 'package:flutter/material.dart';
import '../common/data.dart' as data;
import 'file_item.dart';
import '../file_detail.dart';
import 'location.dart';
import '../utils/platform_custom.dart';
import 'dart:convert';
import 'loading_dialog.dart';
import '../localization/localization.dart';
import '../utils/file.dart' as fileUtils;
import '../utils/colors.dart';
import 'path_select_dialog.dart';
import 'form_text_input.dart';

class FileDetailArchive extends StatefulWidget {
  final String archiveType;
  final data.File fileData;
  final VoidCallback callback;

  FileDetailArchive({Key key, @required this.archiveType, @required this.fileData, @required this.callback}):super(key: key);

  @override
  State createState() {
    return _FileDetailArchiveState();
  }
}

class _FileDetailArchiveState extends State<FileDetailArchive> {
  var files = Map<String, data.File>();
  data.File currentFile;
  var showPasswordInput = false;
  var password = '';

  Map<String, data.File> getFiles() {
    return currentFile != null ? currentFile.files : files;
  }


  @override
  void initState() {
    super.initState();
    initFiles();
  }

  void initFiles() async {
    final fileHeaders = await getFileHeaders(widget.archiveType, widget.fileData.uri, '');
    fileHeaders.forEach((e) {
      if (e.isDirectory) return;
      final paths = e.fileName.split("/");
      data.File currentDir;
      for (var i in Iterable<int>.generate(paths.length).toList()) {
        if (i + 1 < paths.length) {
          if (currentDir == null) {
            if (!files.containsKey(paths[i])) {
              files[paths[i]] = data.File(
                paths[i],
                paths.sublist(0, i + 1).join("/"),
                "directory",
                json.encode(data.FileExtra(e.lastModified, e.fileSize).toMap()),
                currentDir,
              );
            }
            currentDir = files[paths[i]];
          } else if (currentDir != null) {
            if (!currentDir.files.containsKey(paths[i])) {
              currentDir.files[paths[i]] = data.File(
                paths[i],
                paths.sublist(0, i + 1).join("/"),
                "directory",
                json.encode(data.FileExtra(e.lastModified, e.fileSize).toMap()),
                currentDir,
              );
            }
            currentDir = currentDir.files[paths[i]];
          }
        } else {
          if (currentDir == null) {
            files[paths[i]] = data.File(
              paths[i],
              e.fileName,
              e.contentType,
              json.encode(data.FileExtra(e.lastModified, e.fileSize).toMap()),
              currentDir,
            );
          } else if (currentDir != null) {
            currentDir.files[paths[i]] = data.File(
              paths[i],
              e.fileName,
              e.contentType,
              json.encode(data.FileExtra(e.lastModified, e.fileSize).toMap()),
              currentDir,
            );
          }
        }
      }
    });
    setState(() {

    });
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          child: Column(
            children: [
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
                          onClick: () async {
                            if (e.contentType == 'directory') {
                              setState(() {
                                currentFile = e;
                              });
                              return;
                            }
                            showLoadingDialog(context, AppLocalizations.of(context).getLanguageText('extracting'), barrierDismissible: true);
                            final extractRes = await extractFile(widget.archiveType, widget.fileData.uri, password, e.uri);
                            Navigator.of(context).pop();
                            if (extractRes.errCode.isNotEmpty) {
                              if (extractRes.errCode == 'wrong_password') {
                                showErrorToast(AppLocalizations.of(context).getLanguageText('wrong_password'));
                                setState(() {
                                  showPasswordInput = true;
                                });
                                return;
                              }
                              showErrorToast(AppLocalizations.of(context).getLanguageText('uncompress_failure'));
                              return;
                            }
                            if (extractRes.targetUri.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FileDetailPage(fileData: fileUtils.path2File(extractRes.targetUri), callback: widget.callback)),
                              );
                            }
                          },
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        color: ColorUtils.themeColor,
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context).getLanguageText('uncompress'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  final endIndex = widget.fileData.name.lastIndexOf('.');
                  String defaultDirName = '';
                  if (endIndex >= 0) {
                    defaultDirName = widget.fileData.name.substring(0, endIndex);
                  } else {
                    defaultDirName = widget.fileData.name;
                  }
                  selectPath(context: context, callback: (p) async {
                    final extractRes = await extractAll(widget.archiveType, widget.fileData.uri, password, await fileUtils.getTargetPath(p));
                    if (extractRes.errCode.isNotEmpty) {
                      if (extractRes.errCode == 'wrong_password') {
                        Navigator.of(context).pop();
                        showErrorToast(AppLocalizations.of(context).getLanguageText('wrong_password'));
                        setState(() {
                          showPasswordInput = true;
                        });
                        return;
                      }
                      showErrorToast(AppLocalizations.of(context).getLanguageText('uncompress_failure'));
                      return;
                    }
                    widget.callback();
                    Navigator.of(context).pop();
                    showSuccessToast(AppLocalizations.of(context).getLanguageText('uncompress_success'));
                  }, defaultDirName: defaultDirName);
                },
              ),
            ],
          ),
        ),
        showPasswordInput?Container(
          color: ColorUtils.semiTransparent,
          child: SimpleDialog(
            children: [
              Container(
                padding: EdgeInsets.only(top: 0, left: 15, right: 15),
                child: FormTextInput(
                  keyName: AppLocalizations.of(context)
                      .getLanguageText('archive_password'),
                  value: password,
                  hintText: AppLocalizations.of(context)
                      .getLanguageText('input_password_hint'),
                  maxLines: 1,
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
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ColorUtils.themeColor,
                            borderRadius:
                            BorderRadius.all(Radius.circular(5.0)),
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
                          setState(() {
                            showPasswordInput = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ):Container(),
      ],
    );
  }
}
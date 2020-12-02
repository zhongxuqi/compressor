import 'package:flutter/material.dart';
import '../common/data.dart';
import '../localization/localization.dart';
import '../utils/colors.dart';
import '../utils/iconfonts.dart';
import '../utils/file.dart' as fileUtils;
import '../utils/toast.dart' as toastUtils;
import 'location.dart';
import 'file_item.dart';
import 'form_file_item.dart';
import 'dart:io' as io;
import 'package:path/path.dart' as path;

enum ActionDialogType {
  copy, move, rename, add
}

typedef ActionCallback = void Function(String targetPath, Map<String, String> fileNameMap);

void showActionDialog({@required BuildContext context, @required ActionDialogType actionType, @required List<File> checkedFiles, @required String relativePath, @required ActionCallback callback}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ActionDialog(actionType: actionType, checkedFiles: checkedFiles, relativePath: relativePath, callback: callback);
    },
  );
}

class ActionDialog extends StatefulWidget {
  final ActionDialogType actionType;
  final List<File> checkedFiles;
  final String relativePath;
  final ActionCallback callback;

  ActionDialog({Key key, @required this.actionType, @required this.checkedFiles, @required this.relativePath, @required this.callback}):super(key: key);

  @override
  State createState() {
    return _ActionDialogState();
  }
}

class _ActionDialogState extends State<ActionDialog> {
  final Set<String> fileUris = Set<String>();
  final List<String> pathFragments = [];
  final List<File> files = List<File>();

  final fileNameMap = Map<String, String>();
  final formFileItemKeyMap = Map<String, GlobalKey<FormFileItemState>>();

  var step = 0;

  @override
  void initState() {
    super.initState();
    widget.checkedFiles.forEach((element) {
      fileUris.add(element.uri);
      formFileItemKeyMap[element.uri] = GlobalKey<FormFileItemState>();
      fileNameMap[element.uri] = element.name;
    });
    initData();
  }

  void initData() async {
    final files = await fileUtils.listFile(path.join(widget.relativePath, pathFragments.join("/")));
    if (files == null) {
      toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('list_file_failure'));
      return;
    }
    setState(() {
      this.files.clear();
      this.files.addAll(files);
    });
  }

  void submit() async {
    final targetPath = await fileUtils.getTargetPath(path.join(widget.relativePath, pathFragments.join("/")));
    final targetFile = io.Directory(targetPath);
    if (!targetFile.existsSync()) {
      toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('unknown_error'));
      return;
    }
    try {
      final currFiles = (await targetFile.list().toList()).map((value) {
        return fileUtils.path2File(value.path);
      }).toList();
      final fileNameSet = Set<String>();
      currFiles.forEach((element) {
        fileNameSet.add(element.name);
      });
      var hasError = false;
      final selfFileNameSet = Set<String>();
      widget.checkedFiles.forEach((element) {
        if (selfFileNameSet.contains(fileNameMap[element.uri])) {
          formFileItemKeyMap[element.uri].currentState.fileNameInputKey.currentState.setTextError(AppLocalizations.of(context).getLanguageText('file_exists'));
          hasError = true;
        } else {
          selfFileNameSet.add(fileNameMap[element.uri]);
        }
      });
      widget.checkedFiles.forEach((element) {
        if (fileNameSet.contains(fileNameMap[element.uri])) {
          formFileItemKeyMap[element.uri].currentState.fileNameInputKey.currentState.setTextError(AppLocalizations.of(context).getLanguageText('file_exists'));
          hasError = true;
        }
      });
      if (hasError) {
        return;
      }
      widget.callback(targetPath, fileNameMap);
    } catch (e) {
      toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('unknown_error'));
      return;
    }
  }

  String getTitle() {
    switch (widget.actionType) {
      case ActionDialogType.copy:
        return AppLocalizations.of(context).getLanguageText('files_copy');
      case ActionDialogType.move:
        return AppLocalizations.of(context).getLanguageText('files_move');
      case ActionDialogType.rename:
        return AppLocalizations.of(context).getLanguageText('files_rename');
      case ActionDialogType.add:
        return AppLocalizations.of(context).getLanguageText('files_add');
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      Container(
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 10),
                child: Text(
                  getTitle(),
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
              color: ColorUtils.divider,
            ),
          ),
        ],
      ),
    ];
    if (widget.actionType == ActionDialogType.rename) {
      children.addAll(<Widget>[
        Container(
          height: MediaQuery
              .of(context)
              .size
              .height / 2,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate(
                    widget.checkedFiles.map((e) =>
                        FormFileItem(
                          key: formFileItemKeyMap[e.uri],
                          fileData: e,
                          fileNameListener: (fileName) {
                            fileNameMap[e.uri] = fileName;
                            formFileItemKeyMap[e.uri].currentState
                                .fileNameInputKey.currentState.setTextError(
                                '');
                          },
                        )).toList()
                ),
              ),
            ],
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
                      borderRadius:
                      BorderRadius.all(Radius.circular(5.0)),
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
                      borderRadius:
                      BorderRadius.all(Radius.circular(5.0)),
                    ),
                    child: Text(
                      AppLocalizations.of(context).getLanguageText(
                          'submit'),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: submit,
                ),
              ),
            ],
          ),
        ),
      ]);
    } else {
      switch (step) {
        case 0:
          children.addAll(<Widget>[
            Location(
              directories: pathFragments,
              goBack: () {
                if (pathFragments.length <= 0) return;
                pathFragments.removeLast();
                initData();
              },
            ),
            Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 5 / 12,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                        files.where((element) =>
                        element.contentType == 'directory' &&
                            !fileUris.contains(element.uri))
                            .map((e) =>
                            FileItem(
                              fileData: e,
                              onClick: () {
                                if (e.contentType == 'directory') {
                                  pathFragments.add(e.name);
                                  initData();
                                  return;
                                }
                              },
                            )).toList()
                    ),
                  ),
                ],
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
                          borderRadius:
                          BorderRadius.all(Radius.circular(5.0)),
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
                          borderRadius:
                          BorderRadius.all(Radius.circular(5.0)),
                        ),
                        child: Text(
                          AppLocalizations.of(context)
                              .getLanguageText('choose_the_directory'),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          step = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ]);
          break;
        case 1:
          children.addAll(<Widget>[
            Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height / 2,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                        widget.checkedFiles.map((e) =>
                            FormFileItem(
                              key: formFileItemKeyMap[e.uri],
                              fileData: e,
                              fileNameListener: (fileName) {
                                fileNameMap[e.uri] = fileName;
                                formFileItemKeyMap[e.uri].currentState
                                    .fileNameInputKey.currentState.setTextError(
                                    '');
                              },
                            )).toList()
                    ),
                  ),
                ],
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
                          borderRadius:
                          BorderRadius.all(Radius.circular(5.0)),
                        ),
                        child: Text(
                          AppLocalizations.of(context).getLanguageText(
                              'prev_step'),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          step = 0;
                        });
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
                          borderRadius:
                          BorderRadius.all(Radius.circular(5.0)),
                        ),
                        child: Text(
                          AppLocalizations.of(context).getLanguageText(
                              'submit'),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onTap: submit,
                    ),
                  ),
                ],
              ),
            ),
          ]);
          break;
      }
    }
    return SimpleDialog(
      contentPadding: EdgeInsets.only(bottom: 10),
      children: children,
    );
  }
}
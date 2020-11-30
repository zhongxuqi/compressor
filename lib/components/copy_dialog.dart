import 'package:flutter/material.dart';
import '../common/data.dart';
import '../localization/localization.dart';
import '../utils/colors.dart';
import '../utils/iconfonts.dart';
import '../utils/file.dart' as fileUtils;
import '../utils/toast.dart' as toastUtils;
import 'location.dart';
import 'file_item.dart';

void showCopyDialog({@required BuildContext context, @required List<File> checkedFiles}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return CopyDialog(checkedFiles: checkedFiles);
    },
  );
}

class CopyDialog extends StatefulWidget {
  final List<File> checkedFiles;

  CopyDialog({Key key, @required this.checkedFiles}):super(key: key);

  @override
  State createState() {
    return _CopyDialogState();
  }
}

class _CopyDialogState extends State<CopyDialog> {
  final Set<String> fileUris = Set<String>();
  final List<String> paths = [];
  final List<File> files = List<File>();

  var step = 0;

  @override
  void initState() {
    super.initState();
    widget.checkedFiles.forEach((element) {
      fileUris.add(element.uri);
    });
    initData();
  }

  void initData() async {
    final files = await fileUtils.listFile(paths.join("/"));
    if (files == null) {
      toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('list_file_failure'));
      return;
    }
    setState(() {
      this.files.clear();
      this.files.addAll(files);
    });
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    switch (step) {
      case 0:
        children.addAll(<Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Text(
                      AppLocalizations.of(context)
                          .getLanguageText('select_target_directory'),
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
          Location(
            directories: paths,
            goBack: () {
              if (paths.length <= 0) return;
              paths.removeLast();
              initData();
            },
          ),
          Container(
            height: MediaQuery.of(context).size.height * 5 / 12,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    files.where((element) => element.contentType == 'directory' && !fileUris.contains(element.uri)).map((e) => FileItem(
                      fileData: e,
                      onClick: () {
                        if (e.contentType == 'directory') {
                          paths.add(e.name);
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
                            .getLanguageText('next_step'),
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
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Text(
                      AppLocalizations.of(context)
                          .getLanguageText('confirm_file_name'),
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
          Container(
            height: MediaQuery.of(context).size.height / 2,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    widget.checkedFiles.map((e) => FileItem(
                      fileData: e,
                      editFileName: true,
                      fileNameListener: (fileName) {

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
                        AppLocalizations.of(context).getLanguageText('prev_step'),
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
                        AppLocalizations.of(context)
                            .getLanguageText('submit'),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onTap: () {

                    },
                  ),
                ),
              ],
            ),
          ),
        ]);
        break;
    }
    return SimpleDialog(
      contentPadding: EdgeInsets.only(bottom: 10),
      children: children,
    );
  }
}
import 'package:flutter/material.dart';
import 'common/data.dart';
import 'utils/file.dart' as FileUtils;
import 'utils/colors.dart';
import 'localization/localization.dart';
import 'utils/iconfonts.dart';
import 'components/file_item.dart';
import 'file_detail.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'components/action_bar.dart';
import 'components/action_dialog.dart';
import 'utils/file.dart' as fileUtils;
import 'package:path/path.dart' as path;
import 'dart:io' as io;
import 'utils/toast.dart' as toastUtils;

StreamSubscription _intentDataStreamSubscription;

void checkReceiveFiles({@required BuildContext context, @required VoidCallback callback}) {
  // For sharing images coming from outside the app while the app is in the memory
  _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
    if (value == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReceiveFilePage(filePaths: value.map((e) => e.path).toList(), callback: callback)),
    );
  }, onError: (err) {
    print("getIntentDataStream error: $err");
  });

  // For sharing images coming from outside the app while the app is closed
  ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
    if (value == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReceiveFilePage(filePaths: value.map((e) => e.path).toList(), callback: callback)),
    );
  }, onError: (err) {
    print("getIntentDataStream error: $err");
  });
}

class ReceiveFilePage extends StatefulWidget {
  final List<String> filePaths;
  final VoidCallback callback;

  ReceiveFilePage({Key key, @required this.filePaths, @required this.callback}):super(key: key);

  @override
  State createState() {
    return _ReceiveFilePageState();
  }
}

class _ReceiveFilePageState extends State<ReceiveFilePage> {
  final List<File> files = List<File>();
  final Set<String> checkedFiles = Set<String>();

  @override
  void initState() {
    super.initState();
    initData();
  }

  void initData() async {
    setState(() {
      this.files.clear();
      this.files.addAll(widget.filePaths.map((e) => FileUtils.path2File(e)));
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
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
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.only(left: 10),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)
                            .getLanguageText('add_sharing_files'),
                        style: TextStyle(
                          color: ColorUtils.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
            Expanded(
              flex: 1,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                      files.map((e) => FileItem(
                        fileData: e,
                        onClick: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FileDetailPage(fileData: e, callback: () {
                              widget.callback();
                            })),
                          );
                        },
                        checkStatus: checkedFiles.contains(e.uri)?CheckStatus.checked:CheckStatus.unchecked,
                        onCheck: () {
                          setState(() {
                            if (checkedFiles.contains(e.uri)) {
                              checkedFiles.remove(e.uri);
                            } else {
                              checkedFiles.add(e.uri);
                            }
                          });
                        },
                      )).toList()
                    ),
                  ),
                ],
              ),
            ),
            checkedFiles.length>0?ActionBar(actionItems: <ActionItem>[
              ActionItem(iconData: IconFonts.save, textCode: 'save', callback: () {
                var validFiles = files.where((e) => checkedFiles.contains(e.uri)).map((e) => e.clone()).toList();
                showActionDialog(
                  context: context,
                  actionType: ActionDialogType.copy,
                  checkedFiles: validFiles,
                  relativePath: '',
                  callback: (String targetPath, Map<String, String> fileNameMap) {
                    validFiles.forEach((element) async {
                      if (fileUtils.isDirectory(element.uri)) {
                        fileUtils.copyDirectory(io.Directory(element.uri), io.Directory(path.join(targetPath, fileNameMap[element.uri])));
                      } else {
                        await io.File(element.uri).copy(path.join(targetPath, fileNameMap[element.uri]));
                      }
                    });
                    Navigator.of(context).pop();
                    toastUtils.showSuccessToast(AppLocalizations.of(context).getLanguageText('add_success'));
                    widget.callback();
                    setState(() {
                      final addedUris = validFiles.map((e) => e.uri).toList();
                      final remainFiles = this.files.where((element) => !addedUris.contains(element.uri)).toList();
                      this.files.clear();
                      this.files.addAll(remainFiles);
                    });
                  },
                );
              }),
              ActionItem(iconData: IconFonts.close, textCode: 'unselect', callback: () {
                checkedFiles.clear();
                setState(() {});
              }),
            ]):Container(),
          ],
        ),
      ),
    );
  }
}
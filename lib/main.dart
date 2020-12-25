import 'package:compressor/components/action_bar.dart';
import 'package:compressor/utils/platform_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import './localization/localization.dart';
import 'package:flutter/services.dart';
import './utils/colors.dart';
import 'utils/iconfonts.dart';
import 'compressor.dart';
import './common/data.dart';
import './file_detail.dart';
import 'components/file_item.dart';
import 'utils/file.dart' as fileUtils;
import 'utils/toast.dart' as toastUtils;
import 'components/directory_dialog.dart' as directory_dialog;
import 'components/location.dart';
import 'dart:io' as io;
import 'dart:convert';
import 'package:path/path.dart' as path;
import './utils/file.dart' as FileUtils;
import 'package:lpinyin/lpinyin.dart';
import 'components/file_sort_dialog.dart';
import 'utils/store.dart';
import 'components/agreement_dialog.dart';
import 'receive_file.dart';
import 'components/action_dialog.dart';
import 'components/alert_dialog.dart';
import 'components/privacy_dialog.dart';
import 'components/feedback_dialog.dart';
import 'utils/server.dart' as ServerUtils;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: ColorUtils.primaryColor,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('zh', 'CH'),
      ],
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final actions = <Action>[
    Action(ActionType.file, 'images/file_open.png', 'add_file'),
    Action(ActionType.image, 'images/file_pic.png', 'add_image'),
    Action(ActionType.video, 'images/file_video.png', 'add_video'),
    Action(ActionType.directory, 'images/directory.png', 'create_directory'),
    Action(ActionType.archive, 'images/file_zip.png', 'create_archive'),
  ];
  final List<String> paths = [];
  final List<File> files = List<File>();
  final Set<String> checkedFiles = Set<String>();
  var sortBy = SortBy.name;
  var sortType = SortType.asc;

  @override
  void initState() {
    super.initState();
    initData().then((value) async {
      checkReceiveFiles(context: context, callback: () {
        initData();
      });

      Future.delayed(Duration(milliseconds: 500), () async {
        if (!await StoreUtils.hasOpened()) {
          showAgreementDialog(context);
          StoreUtils.setHasOpened(true);
        }
      });
    });
  }

  String preprocessFileName(String fileName) {
    return PinyinHelper.getPinyin(fileName, format: PinyinFormat.WITHOUT_TONE).replaceAll(' ', '').toLowerCase();
  }

  Future<void> initData() async {
    sortBy = await StoreUtils.getSortByKey();
    sortType = await StoreUtils.getSortTypeKey();
    final files = await fileUtils.listFileByRelative(paths.join("/"));
    if (files == null) {
      toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('list_file_failure'));
      return;
    }
    files.sort((a, b) {
      switch (sortBy) {
        case SortBy.name:
          var factor = 1;
          if (sortType == SortType.desc) {
            factor = -1;
          }
          return factor * preprocessFileName(a.name).compareTo(preprocessFileName(b.name));
          break;
        case SortBy.time:
          var factor = 1;
          if (sortType == SortType.desc) {
            factor = -1;
          }
          return factor * (a.extraObj.lastModified - b.extraObj.lastModified);
          break;
      }
      return 0;
    });
    setState(() {
      this.files.clear();
      this.files.addAll(files);
    });
    return;
  }

  void doAction(ActionType t) async {
    switch (t) {
      case ActionType.file:
        _pickFileByMimeType(mimeType: '*/*');
        break;
      case ActionType.image:
        _pickFileByMimeType(mimeType: 'image/*');
        break;
      case ActionType.video:
        _pickFileByMimeType(mimeType: 'video/*');
        break;
      case ActionType.directory:
        createDirectory();
        break;
      case ActionType.archive:
        final dir = await FileUtils.getTargetPath(paths.join("/"));
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>
            CompressorPage(callback: () {
              initData();
            }, dir: io.Directory(dir)),
          ),
        );
        break;
    }
  }

  void _pickFileByMimeType({@required String mimeType}) async {
    Navigator.of(context).pop();
    final fileResultList = await pickFile(mimeType: mimeType);
    var validFiles = fileResultList.map((e) => fileUtils.path2File(e.uri)).toList();
    showActionDialog(
      context: context,
      actionType: ActionDialogType.add,
      checkedFiles: validFiles,
      relativePath: '',
      callback: (String targetPath, Map<String, String> fileNameMap) async {
        validFiles.forEach((element) async {
          if (fileUtils.isDirectory(element.uri)) {
            fileUtils.copyDirectory(io.Directory(element.uri), io.Directory(path.join(targetPath, fileNameMap[element.uri])));
          } else {
            await io.File(element.uri).copy(path.join(targetPath, fileNameMap[element.uri]));
          }
        });
        Navigator.of(context).pop();
        toastUtils.showSuccessToast(AppLocalizations.of(context).getLanguageText('add_success'));
        checkedFiles.clear();
        initData();
      },
    );
  }

  void doCreateDirectory(String directoryName) async {
    if (directoryName.isEmpty) return;
    final currentFile = io.Directory(path.join(await FileUtils.getTargetPath(paths.join("/")), directoryName));
    if (currentFile.existsSync()) return;
    currentFile.createSync();
    initData();
    Navigator.of(context).pop();
  }

  void createDirectory() async {
    Navigator.of(context).pop();
    directory_dialog.createDirectory(context: context, callback: doCreateDirectory, excludedNames: files.map((e) => e.name).toList());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (paths.length > 0) {
          paths.remove(paths.last);
          initData();
        } else {
          showAlertDialog(context, text: AppLocalizations.of(context).getLanguageText('exit_app_alert'), callback: () {
            SystemNavigator.pop();
          });
        }
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(children: <Widget>[
            Container(
              height: 46.0,
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        child: Container(
                          width: 45,
                          height: 45,
                          child: Icon(
                            IconFonts.menu,
                            color: ColorUtils.themeColor,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          _scaffoldKey.currentState.openDrawer();
                        },
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            AppLocalizations.of(context).getLanguageText('main_title'),
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
                            IconFonts.sort,
                            color: ColorUtils.themeColor,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          showFileSortDialog(context: context, sortBy: this.sortBy, sortType: this.sortType, callback: (sortBy, sortType) {
                            this.sortBy = sortBy;
                            this.sortType = sortType;
                            StoreUtils.setSortByKey(sortBy);
                            StoreUtils.setSortTypeKey(sortType);
                            initData();
                            Navigator.of(context).pop();
                          });
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
            Location(
              directories: paths,
              goBack: () {
                if (paths.length <= 0) return;
                paths.removeLast();
                initData();
              },
            ),
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: <Widget>[
                      SliverList(
                        delegate: SliverChildListDelegate(
                            files.map<Widget>((e) => FileItem(
                              fileData: e,
                              onClick: () {
                                if (e.contentType == 'directory') {
                                  paths.add(e.name);
                                  initData();
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => FileDetailPage(fileData: e, callback: () {
                                    initData();
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
                            )).toList()..add(Container(height: 80, width: 1))
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                child: Container(
                                  padding: EdgeInsets.all(15.0),
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(blurRadius: 5.0, spreadRadius: 1.0, color: Colors.grey.shade400)
                                    ],
                                    shape: BoxShape.circle,
                                    color: ColorUtils.lightGrey,
                                  ),
                                  child: Icon(
                                    IconFonts.add,
                                    color: ColorUtils.themeColor,
                                    size: 20.0,
                                  ),
                                ),
                                onTap: () {
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
                                              children: actions.sublist(0, 3).map((e) => Expanded(
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
                                                          AppLocalizations.of(context).getLanguageText(e.name),
                                                          style: TextStyle(fontSize: 15),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onTap: () {
                                                    doAction(e.actionType);
                                                  },
                                                ),
                                              )).toList(),
                                            ),
                                            Container(height: 10, width: 1),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: actions.sublist(3).map((e) => Expanded(
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
                                                          AppLocalizations.of(context).getLanguageText(e.name),
                                                          style: TextStyle(fontSize: 15),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onTap: () {
                                                    doAction(e.actionType);
                                                  },
                                                ),
                                              )).toList(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            checkedFiles.length>0?ActionBar(actionItems: <ActionItem>[
              ActionItem(iconData: IconFonts.copy, textCode: 'copy', callback: () {
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
                    toastUtils.showSuccessToast(AppLocalizations.of(context).getLanguageText('copy_success'));
                    checkedFiles.clear();
                    initData();
                  },
                );
              }),
              ActionItem(iconData: IconFonts.move, textCode: 'move', callback: () {
                var validFiles = files.where((e) => checkedFiles.contains(e.uri)).map((e) => e.clone()).toList();
                showActionDialog(
                  context: context,
                  actionType: ActionDialogType.move,
                  checkedFiles: validFiles,
                  relativePath: '',
                  callback: (String targetPath, Map<String, String> fileNameMap) {
                    validFiles.forEach((element) async {
                      if (fileUtils.isDirectory(element.uri)) {
                        io.Directory(element.uri).rename(path.join(targetPath, fileNameMap[element.uri]));
                      } else {
                        io.File(element.uri).rename(path.join(targetPath, fileNameMap[element.uri]));
                      }
                    });
                    Navigator.of(context).pop();
                    toastUtils.showSuccessToast(AppLocalizations.of(context).getLanguageText('copy_success'));
                    checkedFiles.clear();
                    initData();
                  },
                );
              }),
              ActionItem(iconData: IconFonts.edit, textCode: 'rename', callback: () {
                var validFiles = files.where((e) => checkedFiles.contains(e.uri)).map((e) => e.clone()).toList();
                showActionDialog(
                  context: context,
                  actionType: ActionDialogType.rename,
                  checkedFiles: validFiles,
                  relativePath: paths.join(''),
                  callback: (String targetPath, Map<String, String> fileNameMap) {
                    validFiles.forEach((element) async {
                      if (fileUtils.isDirectory(element.uri)) {
                        io.Directory(element.uri).rename(path.join(targetPath, fileNameMap[element.uri]));
                      } else {
                        io.File(element.uri).rename(path.join(targetPath, fileNameMap[element.uri]));
                      }
                    });
                    Navigator.of(context).pop();
                    toastUtils.showSuccessToast(AppLocalizations.of(context).getLanguageText('copy_success'));
                    checkedFiles.clear();
                    initData();
                  },
                );
              }),
              ActionItem(iconData: IconFonts.delete, textCode: 'delete', callback: () {
                showAlertDialog(context, text: AppLocalizations.of(context).getLanguageText('delete_alert'), callback: () {
                  var validFiles = files.where((e) => checkedFiles.contains(e.uri)).map((e) => e.clone()).toList();
                  validFiles.forEach((element) async {
                    await io.File(element.uri).delete(recursive: true);
                  });
                  Navigator.of(context).pop();
                  toastUtils.showSuccessToast(AppLocalizations.of(context).getLanguageText('delete_success'));
                  checkedFiles.clear();
                  initData();
                });
              }),
              ActionItem(iconData: IconFonts.close, textCode: 'unselect', callback: () {
                checkedFiles.clear();
                initData();
              }),
            ]):Container(),
          ]),
        ),
        drawer: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          color: ColorUtils.white,
          width: 200,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: 5, left: 5, right: 5),
                child: SideMenuBtn(iconData: IconFonts.feedback,text: AppLocalizations.of(context).getLanguageText('feedback'), callback: () {
                  showFeedbackDialog(context, callback: (msg) {
                    if (msg == '') return;
                    ServerUtils.feedback(msg).then((resp) {
                      Map<String, dynamic> respObj = json.decode(utf8.decode(resp.bodyBytes));
                      if (respObj['errno'] != 0) {
                        return;
                      }
                      toastUtils.showSuccessToast(AppLocalizations.of(context).getLanguageText('thank_feedback'));
                    });
                  });
                }),
              ),
              Container(
                padding: EdgeInsets.only(top: 5, left: 5, right: 5),
                child: SideMenuBtn(iconData: IconFonts.star,text: AppLocalizations.of(context).getLanguageText('star_rating'), callback: () {
                  feedback();
                }),
              ),
              AppLocalizations.of(context).getLanguage()=='zh'?Container(
                padding: EdgeInsets.only(top: 5, left: 5, right: 5),
                child: SideMenuBtn(iconData: IconFonts.agreement,text: AppLocalizations.of(context).getLanguageText('agreement'), callback: () {
                  showAgreementDialog(context);
                }),
              ):Container(),
              AppLocalizations.of(context).getLanguage()=='zh'?Container(
                padding: EdgeInsets.only(top: 5, left: 5, right: 5),
                child: SideMenuBtn(iconData: IconFonts.lock,text: AppLocalizations.of(context).getLanguageText('privacy'), callback: () {
                  showPrivacyDialog(context);
                }),
              ):Container(),
            ],
          ),
        ),
      ),
    );
  }
}

enum ActionType { file, image, video, directory, archive }

class Action {
  final ActionType actionType;
  final String icon;
  final String name;

  Action(this.actionType, this.icon, this.name);
}

class SideMenuBtn extends StatelessWidget {
  final IconData iconData;
  final String text;
  final VoidCallback callback;

  SideMenuBtn({Key key, @required this.iconData, @required this.text, @required this.callback}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.only(right: 10),
              child: Icon(iconData, size: 22, color: ColorUtils.textColor),
            ),
            Text(text, style: TextStyle(
              fontSize: 15,
              color: ColorUtils.textColor,
            )),
          ],
        ),
      ),
      onPressed: () {
        callback();
      },
    );
  }
}
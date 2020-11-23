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
import 'package:path/path.dart' as path;
import './utils/file.dart' as FileUtils;
import 'package:lpinyin/lpinyin.dart';
import 'components/file_sort_dialog.dart';
import 'utils/store.dart';

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
  final actions = <Action>[
    Action(ActionType.directory, 'images/directory.png', 'create_directory'),
    Action(ActionType.archive, 'images/file_zip.png', 'create_archive'),
  ];
  final List<String> paths = [];
  final List<File> files = List<File>();
  var sortBy = SortBy.name;
  var sortType = SortType.asc;

  @override
  void initState() {
    super.initState();
    initData();
  }

  String preprocessFileName(String fileName) {
    return PinyinHelper.getPinyin(fileName, format: PinyinFormat.WITHOUT_TONE).replaceAll(' ', '').toLowerCase();
  }

  void initData() async {
    sortBy = await StoreUtils.getSortByKey();
    sortType = await StoreUtils.getSortTypeKey();
    final files = await fileUtils.listFile(paths.join("/"));
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
  }

  void doAction(ActionType t) async {
    switch (t) {
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
    return Scaffold(
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
                    Container(
                      width: 45,
                      height: 45,
                      child: Icon(
                        IconFonts.search,
                        color: ColorUtils.themeColor,
                        size: 20.0,
                      ),
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
                        files.map((e) => FileItem(
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
                        )).toList()
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
                                      height: 120,
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: actions.map((e) => Expanded(
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
        ]),
      ),
    );
  }
}

enum ActionType { directory, archive }

class Action {
  final ActionType actionType;
  final String icon;
  final String name;

  Action(this.actionType, this.icon, this.name);
}
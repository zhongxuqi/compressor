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
  final List<File> files = List<File>();

  @override
  void initState() {
    super.initState();
    initData();
  }

  void initData() async {
    final files = await fileUtils.listFile('');
    if (files == null) {
      toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('list_file_failure'));
      return;
    }
    setState(() {
      this.files.clear();
      this.files.addAll(files);
    });
  }

  void doAction(ActionType t) {
    switch (t) {
      case ActionType.directory:
        break;
      case ActionType.archive:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>
              CompressorPage(callback: (fileObj) {
                setState(() {
                  this.files.add(fileObj);
                });
              }),
          ),
        );
        break;
    }
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
                    Container(
                      width: 45,
                      height: 45,
                      child: Icon(
                        IconFonts.sort,
                        color: ColorUtils.themeColor,
                        size: 20.0,
                      ),
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
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: <Widget>[
                    SliverList(
                      delegate: SliverChildListDelegate(
                          files.map((e) => FileItem(
                            fileData: e,
                            onClick: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FileDetailPage(fileData: e)),
                              );
                            },
                          )).toList()
                      ),
                    ),
                  ],
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  padding: EdgeInsets.all(10.0),
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
                                              AppLocalizations.of(context)
                                                  .getLanguageText(e.name),
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
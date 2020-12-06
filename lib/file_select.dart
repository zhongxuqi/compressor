import 'package:flutter/material.dart';
import 'utils/iconfonts.dart';
import './utils/colors.dart';
import 'localization/localization.dart';
import 'components/location.dart';
import './common/data.dart';
import 'utils/store.dart';
import './utils/file.dart' as fileUtils;
import 'package:lpinyin/lpinyin.dart';
import 'utils/toast.dart' as toastUtils;
import 'components/file_item.dart';
import './file_detail.dart';

typedef FileSelectCallback = void Function(List<String> value);

class FileSelectPage extends StatefulWidget {
  final FileSelectCallback callback;

  FileSelectPage({Key key, @required this.callback}):super(key: key);

  @override
  State createState() {
    return _FileSelectPageState();
  }
}

class _FileSelectPageState extends State<FileSelectPage> {
  var sortBy = SortBy.name;
  var sortType = SortType.asc;

  final List<File> files = List<File>();
  final List<String> paths = [];
  final Set<String> checkedFiles = Set<String>();

  @override
  void initState() {
    super.initState();
    initData();
  }

  String preprocessFileName(String fileName) {
    return PinyinHelper.getPinyin(fileName, format: PinyinFormat.WITHOUT_TONE).replaceAll(' ', '').toLowerCase();
  }

  Future<void> initData() async {
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
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(children: <Widget>[
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
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context).getLanguageText('files_select'),
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
                      widget.callback(checkedFiles.toList());
                    },
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
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                      files.map<Widget>((e) => FileItem(
                        fileData: e,
                        onClick: () {
                          if (e.contentType == 'directory') {
                            if (checkedFiles.contains(e.uri)) {
                              toastUtils.showErrorToast(AppLocalizations.of(context).getLanguageText('directory_selected'));
                              return;
                            }

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
                              return;
                            }

                            // 检查内容
                            for (var key in checkedFiles.toList()) {

                              // 父目录已经添加，直接跳过
                              if (e.uri.startsWith(key)) {
                                return;
                              }

                              // 删除子目录内容
                              if (key.startsWith(e.uri)) {
                                checkedFiles.remove(key);
                              }
                            }

                            checkedFiles.add(e.uri);
                          });
                        },
                      )).toList()..add(Container(height: 80, width: 1))
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

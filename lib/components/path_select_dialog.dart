import 'package:flutter/material.dart';
import 'location.dart';
import '../common/data.dart';
import '../utils/file.dart' as fileUtils;
import '../utils/toast.dart' as toastUtils;
import '../localization/localization.dart';
import 'file_item.dart';
import '../utils/colors.dart';
import '../utils/iconfonts.dart';
import 'form_text_input.dart';
import 'package:path/path.dart' as pathLib;

void selectPath({@required BuildContext context, @required ValueChanged<String> callback, @required String defaultDirName}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PathSelectDialog(callback: callback, defaultDirName: defaultDirName);
    },
  );
}

class PathSelectDialog extends StatefulWidget {
  final ValueChanged<String> callback;
  final String defaultDirName;

  PathSelectDialog({Key key, @required this.callback, @required this.defaultDirName}):super(key: key);

  @override
  State createState() {
    return _PathSelectDialogState();
  }
}

class _PathSelectDialogState extends State<PathSelectDialog> {
  final GlobalKey<FormTextInputState> _directoryNameInputKey = GlobalKey<FormTextInputState>();
  var directoryName = '';
  final List<String> paths = [];
  final List<File> files = List<File>();

  @override
  void initState() {
    super.initState();
    initData();
    directoryName = widget.defaultDirName;
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
        Container(
          padding: EdgeInsets.only(top: 0, left: 15, right: 15, bottom: 15),
          child: FormTextInput(
            key: _directoryNameInputKey,
            keyName: AppLocalizations.of(context).getLanguageText('unzip_dir_name'),
            value: directoryName,
            hintText: AppLocalizations.of(context)
                .getLanguageText('input_file_name_hint'),
            maxLines: 1,
            onChange: (value) {
              directoryName = value;
              _directoryNameInputKey.currentState.setTextError('');
            },
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
        Container(
          height: MediaQuery.of(context).size.height * 5 / 12,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate(
                  files.where((element) => element.contentType == 'directory').map((e) => FileItem(
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
                          .getLanguageText('confirm'),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: () {
                    if (files.map((e) => e.name).toList().contains(directoryName)) {
                      _directoryNameInputKey.currentState.setTextError(AppLocalizations.of(context).getLanguageText('file_exists'));
                      return;
                    }
                    widget.callback(pathLib.join(paths.join("/"), directoryName));
                    initData();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
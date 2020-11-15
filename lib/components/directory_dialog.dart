import 'package:flutter/material.dart';
import 'form_text_input.dart';
import '../localization/localization.dart';
import '../utils/colors.dart';
import '../utils/iconfonts.dart';

void createDirectory({@required BuildContext context, @required ValueChanged<String> callback, @required List<String> excludedNames}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CreateDirectoryDialog(callback: callback, excludedNames: excludedNames);
    },
  );
}

class CreateDirectoryDialog extends StatefulWidget {
  final ValueChanged<String> callback;
  final List<String> excludedNames;

  CreateDirectoryDialog({Key key, @required this.callback, @required this.excludedNames}):super(key: key);

  @override
  State createState() {
    return _CreateDirectoryDialogState();
  }
}

class _CreateDirectoryDialogState extends State<CreateDirectoryDialog> {
  final GlobalKey<FormTextInputState> _directoryNameInputKey = GlobalKey<FormTextInputState>();
  var directoryName = '';

  void doCreateDirectory() async {
    var hasErr = false;
    if (directoryName == "") {
      _directoryNameInputKey.currentState.setTextError(
          AppLocalizations.of(context).getLanguageText('required'));
      hasErr = true;
    }
    if (widget.excludedNames.contains(directoryName)) {
      _directoryNameInputKey.currentState.setTextError(
          AppLocalizations.of(context).getLanguageText('file_exists'));
      hasErr = true;
    }
    if (hasErr) {
      setState(() {});
      return;
    }
    widget.callback(directoryName);
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
                        .getLanguageText('create_directory'),
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
            key: _directoryNameInputKey,
            keyName:
            AppLocalizations.of(context).getLanguageText('file_name'),
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
                    doCreateDirectory();
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
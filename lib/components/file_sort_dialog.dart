import 'package:flutter/material.dart';
import '../localization/localization.dart';
import '../utils/colors.dart';

enum SortBy { name, time }

enum SortType { asc, desc }

typedef SortCallback = void Function(SortBy sortBy, SortType sortType);

void showFileSortDialog({@required BuildContext context, @required SortBy sortBy, @required SortType sortType, @required SortCallback callback}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FileSortDialog(sortBy: sortBy, sortType: sortType, callback: callback);
    },
  );
}

class FileSortDialog extends StatefulWidget {
  final SortBy sortBy;
  final SortType sortType;
  final SortCallback callback;

  FileSortDialog({Key key, @required this.sortBy, @required this.sortType, @required this.callback}):super(key: key);

  @override
  State createState() {
    return _FileSortDialogState(sortBy: sortBy, sortType: sortType);
  }
}

class _FileSortDialogState extends State<FileSortDialog> {
  SortBy sortBy;
  SortType sortType;

  _FileSortDialogState({@required this.sortBy, @required this.sortType});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.only(bottom: 10),
      children: [
        Container(
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 5),
          child: Text(AppLocalizations.of(context).getLanguageText('sort_by'), style: TextStyle(
            color: ColorUtils.deepGrey,
            fontSize: 14,
          )),
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
        FileSortMenuBtn(
          text: AppLocalizations.of(context).getLanguageText('sort_by_file_name'),
          active: sortBy == SortBy.name,
          onClick: () {
            setState(() {
              sortBy = SortBy.name;
            });
          },
        ),
        FileSortMenuBtn(
          text: AppLocalizations.of(context).getLanguageText('sort_by_time'),
          active: sortBy == SortBy.time,
          onClick: () {
            setState(() {
              sortBy = SortBy.time;
            });
          },
        ),
        Container(
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 5),
          child: Text(AppLocalizations.of(context).getLanguageText('sort_type'), style: TextStyle(
            color: ColorUtils.deepGrey,
            fontSize: 14,
          )),
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
        FileSortMenuBtn(
          text: AppLocalizations.of(context).getLanguageText('sort_type_asc'),
          active: sortType == SortType.asc,
          onClick: () {
            setState(() {
              sortType = SortType.asc;
            });
          },
        ),
        FileSortMenuBtn(
          text: AppLocalizations.of(context).getLanguageText('sort_type_desc'),
          active: sortType == SortType.desc,
          onClick: () {
            setState(() {
              sortType = SortType.desc;
            });
          },
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
                    widget.callback(sortBy, sortType);
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

class FileSortMenuBtn extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onClick;

  FileSortMenuBtn({Key key, @required this.text, @required this.active, @required this.onClick}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        color: active?ColorUtils.themeColor:ColorUtils.white,
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(top: 5),
        child: Text(text, style: TextStyle(
          fontSize: 15,
          color: active?ColorUtils.white:ColorUtils.themeColor,
        )),
      ),
      onTap: onClick,
    );
  }
}
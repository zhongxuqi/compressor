import 'package:compressor/localization/localization.dart';
import 'package:compressor/utils/colors.dart';
import 'package:flutter/material.dart';

class ActionItem {
  final IconData iconData;
  final String textCode;
  final VoidCallback callback;

  ActionItem({@required this.iconData, @required this.textCode, @required this.callback});
}

class ActionBar extends StatelessWidget {
  final List<ActionItem> actionItems;

  ActionBar({Key key, @required this.actionItems}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorUtils.themeColor,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        children: actionItems.map((e) {
          return Expanded(
            flex: 1,
            child: RawMaterialButton(
              elevation: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 3),
                      child: Icon(e.iconData, color: ColorUtils.white, size: 22),
                    ),
                    Container(
                      child: Text(
                        AppLocalizations.of(context).getLanguageText(e.textCode),
                        style: TextStyle(
                          color: ColorUtils.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onPressed: () {
                e.callback();
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
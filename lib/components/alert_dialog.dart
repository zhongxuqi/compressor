import 'package:compressor/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../localization/localization.dart';

void showAlertDialog(BuildContext context, {@required String text, @required VoidCallback callback}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        contentPadding: EdgeInsets.only(bottom: 10),
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: 5, left: 10, right: 10),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                color: ColorUtils.red,
              ),
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
                        AppLocalizations.of(context).getLanguageText('cancel'),
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
                        color: ColorUtils.red,
                        borderRadius:
                        BorderRadius.all(Radius.circular(5.0)),
                      ),
                      child: Text(
                        AppLocalizations.of(context).getLanguageText('confirm'),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onTap: callback,
                  ),
                ),
              ],
            ),
          ),
        ],
      );;
    },
  );
}
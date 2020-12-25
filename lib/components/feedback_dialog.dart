import 'package:flutter/material.dart';
import '../localization/localization.dart';
import '../utils/colors.dart';

void showFeedbackDialog(BuildContext context, {@required ValueChanged<String> callback}) {
  var textCtl = TextEditingController();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: ColorUtils.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: ColorUtils.white,
              borderRadius: BorderRadius.all(Radius.circular(10.0))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 10, left: 10),
                  child: Text(
                    AppLocalizations.of(context).getLanguageText('feedback'),
                    style: TextStyle(
                      fontSize: 18,
                      color: ColorUtils.themeColor,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorUtils.themeColor),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        gapPadding: 0,
                        borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 0,
                            style: BorderStyle.none
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        gapPadding: 0,
                        borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 0,
                            style: BorderStyle.none
                        ),
                      ),
                      fillColor: Colors.transparent,
                      hintText: AppLocalizations.of(context).getLanguageText('input_text_hint'),
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 15.0,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                    ),
                    controller: textCtl,
                    minLines: 4,
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 15,
                      color: ColorUtils.themeColor,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(top: 0, left: 10, right: 10),
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
                            Navigator.of(context).pop();
                            callback(textCtl.text);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
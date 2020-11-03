import 'package:flutter/material.dart';
import '../localization/localization.dart';
import '../utils/colors.dart';

class FileDetailUnknown extends StatefulWidget {

  @override
  State createState() {
    return _FileDetailUnknownState();
  }
}

class _FileDetailUnknownState extends State<FileDetailUnknown> {

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('images/file_unknown.png', height: 80.0, width: 80.0,),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: Text(
              AppLocalizations.of(context).getLanguageText('unknown_file_type'),
              style: TextStyle(
                fontSize: 16,
                color: ColorUtils.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../database/data.dart' as data;
import 'dart:io';
import '../utils/colors.dart';

class FileDetailText extends StatefulWidget {
  final data.File fileData;

  FileDetailText({Key key, @required this.fileData}):super(key: key);

  @override
  State createState() {
    return _FileDetailTextState();
  }
}

class _FileDetailTextState extends State<FileDetailText> {
  var fileContent = "";

  @override
  void initState() {
    super.initState();
    readFileContent();
  }

  void readFileContent() async {
    final f = File(widget.fileData.uri);
    setState(() {
      fileContent = f.readAsStringSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
      color: Colors.white,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                Container(height: 10.0),
                Text(fileContent, style: TextStyle(
                  color: ColorUtils.textColor,
                  fontSize: 15,
                )),
                Container(height: 10.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
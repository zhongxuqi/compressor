import 'package:flutter/material.dart';

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
      child: Image.asset('images/file_unknown.png', height: 80.0, width: 80.0,),
    );
  }
}
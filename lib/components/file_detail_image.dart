import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../database/data.dart' as data;

class FileDetailImage extends StatefulWidget {
  final data.File fileData;

  FileDetailImage({Key key, @required this.fileData}):super(key: key);

  @override
  State createState() {
    return _FileDetailImageState();
  }
}

class _FileDetailImageState extends State<FileDetailImage> {

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: PhotoView(
        imageProvider: AssetImage(widget.fileData.uri),
      ),
    );
  }
}
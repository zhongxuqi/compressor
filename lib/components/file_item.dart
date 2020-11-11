import 'package:flutter/material.dart';
import '../common/data.dart' as data;
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/mime.dart';

class FileItem extends StatefulWidget {
  final data.File fileData;
  final VoidCallback onClick;

  FileItem({Key key, @required this.fileData, @required this.onClick}):super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FileItemState();
  }
}

class _FileItemState extends State<FileItem> {

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        height: 60,
        alignment: Alignment.center,
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 8, top: 8, bottom: 8, left: 10),
              child: Image.asset(MimeUtils.getIconByMime(widget.fileData.contentType), height: 40.0, width: 40.0,),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fileData.name,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 16,
                              color: ColorUtils.textColor,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(),
                          ),
                          Row(
                            children: [
                              Text(
                                CommonUtils.formatMilliseconds(widget.fileData.extraObj.lastModified),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorUtils.deepGrey,
                                ),
                              ),
                              Container(width: 10,),
                              Text(
                                CommonUtils.formatFileSize(widget.fileData.extraObj.fileSize),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorUtils.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 1,
                          color: ColorUtils.divider,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        widget.onClick();
      },
    );
  }
}
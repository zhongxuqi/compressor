import 'package:flutter/material.dart';
import '../common/data.dart' as data;
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/mime.dart';
import '../utils/iconfonts.dart';

enum CheckStatus {
  none, unchecked, checked
}

class FileItem extends StatefulWidget {
  final data.File fileData;
  final VoidCallback onClick;
  final CheckStatus checkStatus;
  final VoidCallback onCheck;

  FileItem({Key key,
    @required this.fileData,
    this.onClick,
    this.checkStatus = CheckStatus.none,
    this.onCheck,
  }) :super(key: key);

  @override
  State createState() {
    return _FileItemState();
  }
}

class _FileItemState extends State<FileItem> {
  final fileNameCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fileNameCtl.text = widget.fileData.name;
  }

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
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(top: 8, bottom: 8, right: 8),
                      child: widget.fileData.contentType=='directory'?Text(
                        widget.fileData.name,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorUtils.textColor,
                        ),
                      ):Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fileData.name,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                CommonUtils.formatTimestamp(widget.fileData.extraObj.lastModified),
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
            widget.checkStatus!=CheckStatus.none?GestureDetector(
              child: Container(
                color: ColorUtils.white,
                height: 60,
                padding: EdgeInsets.all(10),
                child: Icon(
                  widget.checkStatus==CheckStatus.checked?IconFonts.checked:IconFonts.unchecked,
                  size: 18,
                  color: widget.checkStatus==CheckStatus.checked?ColorUtils.themeColor:ColorUtils.deepGrey,
                ),
              ),
              onTap: () {
                if (widget.onCheck != null) widget.onCheck();
              },
            ):Container(),
          ],
        ),
      ),
      onTap: widget.onClick,
    );
  }
}
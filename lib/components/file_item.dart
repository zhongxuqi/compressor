import 'package:flutter/material.dart';
import '../common/data.dart' as data;
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/mime.dart';
import '../utils/iconfonts.dart';

enum CheckStatus {
  none, unchecked, checked
}

class FileItem extends StatelessWidget {
  final data.File fileData;
  final VoidCallback onClick;
  final CheckStatus checkStatus;
  final VoidCallback onCheck;

  FileItem({Key key, @required this.fileData, @required this.onClick, this.checkStatus = CheckStatus.none, this.onCheck}):super(key: key);

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
              child: Image.asset(MimeUtils.getIconByMime(fileData.contentType), height: 40.0, width: 40.0,),
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
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: fileData.contentType=='directory'?Text(
                        fileData.name,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorUtils.textColor,
                        ),
                      ):Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileData.name,
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
                                CommonUtils.formatTimestamp(fileData.extraObj.lastModified),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorUtils.deepGrey,
                                ),
                              ),
                              Container(width: 10,),
                              Text(
                                CommonUtils.formatFileSize(fileData.extraObj.fileSize),
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
            checkStatus!=CheckStatus.none?GestureDetector(
              child: Container(
                color: ColorUtils.white,
                height: 60,
                padding: EdgeInsets.all(10),
                child: Icon(
                  checkStatus==CheckStatus.checked?IconFonts.checked:IconFonts.unchecked,
                  size: 18,
                  color: checkStatus==CheckStatus.checked?ColorUtils.themeColor:ColorUtils.deepGrey,
                ),
              ),
              onTap: () {
                if (onCheck != null) onCheck();
              },
            ):Container(),
          ],
        ),
      ),
      onTap: () {
        onClick();
      },
    );
  }
}
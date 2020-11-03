import 'package:flutter/material.dart';
import 'database/data.dart' as data;
import 'utils/colors.dart';
import 'utils/iconfonts.dart';
import 'utils/mime.dart';
import 'components/file_detail_unknow.dart';

class FileDetailPage extends StatefulWidget {
  final data.File fileData;

  FileDetailPage({Key key, @required this.fileData}):super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FileDetailPageState();
  }
}

class _FileDetailPageState extends State<FileDetailPage> {
  Widget getWidgetByFile() {
    return FileDetailUnknown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            Container(
              height: 46,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        child: Container(
                          width: 45,
                          height: 45,
                          child: Icon(
                            IconFonts.back,
                            color: ColorUtils.themeColor,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 5),
                        child: Image.asset(
                          MimeUtils.getIconByMime(widget.fileData.extraObj.mimeType),
                          height: 30.0,
                          width: 30.0,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.fileData.name,
                            style: TextStyle(
                              color: ColorUtils.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
            Expanded(
              flex: 1,
              child: getWidgetByFile(),
            ),
          ],
        ),
      ),
    );
  }
}
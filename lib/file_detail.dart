import 'package:flutter/material.dart';
import 'common/data.dart' as data;
import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'utils/toast.dart' as toastUtils;
import 'utils/colors.dart';
import 'utils/iconfonts.dart';
import 'utils/mime.dart';
import 'utils/file.dart' as fileUtils;
import 'components/file_detail_unknown.dart';
import 'components/file_detail_image.dart';
import 'components/file_detail_video.dart';
import 'components/file_detail_text.dart';
import 'components/file_detail_pdf.dart';
import 'components/file_detail_archive.dart';
import 'package:share/share.dart';
import 'components/action_dialog.dart';
import 'localization/localization.dart';

class FileDetailPage extends StatefulWidget {
  final VoidCallback callback;
  final data.File fileData;

  FileDetailPage({Key key, @required this.fileData, @required this.callback}):super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FileDetailPageState();
  }
}

class _FileDetailPageState extends State<FileDetailPage> {
  data.File fileData;
  String documentPath = '';

  @override
  void initState() {
    super.initState();
    fileData = widget.fileData;
    initData();
  }

  void initData() async {
    documentPath = await fileUtils.getTargetPath('');
    setState(() {});
  }

  Widget getWidgetByFile() {
    if (fileData.contentType.startsWith("image")) {
      return FileDetailImage(fileData: fileData);
    } else if (fileData.contentType.startsWith("video")) {
      return FileDetailVideo(fileData: fileData);
    } else if (fileData.contentType.startsWith("text")) {
      return FileDetailText(fileData: fileData);
    } else if (fileData.contentType.startsWith("application/pdf")) {
      return FileDetailPDF(fileData: fileData);
    } else if (fileData.contentType.startsWith("application/zip")) {
      return FileDetailArchive(archiveType: 'zip', fileData: fileData, callback: widget.callback);
    } else if (fileData.contentType.startsWith("application/x-rar-compressed")) {
      return FileDetailArchive(archiveType: 'rar', fileData: fileData, callback: widget.callback);
    }
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
                          MimeUtils.getIconByMime(fileData.contentType),
                          height: 30.0,
                          width: 30.0,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fileData.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorUtils.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      documentPath.isEmpty||fileData.uri.startsWith(documentPath)?Container():InkWell(
                        child: Container(
                          width: 45,
                          height: 45,
                          child: Icon(
                            IconFonts.add,
                            color: ColorUtils.themeColor,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          showActionDialog(
                            context: context,
                            actionType: ActionDialogType.copy,
                            checkedFiles: <data.File>[fileData],
                            relativePath: '',
                            callback: (String targetPath, Map<String, String> fileNameMap) async {
                              final toPath = path.join(targetPath, fileNameMap[fileData.uri]);
                              if (fileUtils.isDirectory(fileData.uri)) {
                                fileUtils.copyDirectory(io.Directory(fileData.uri), io.Directory(toPath));
                              } else {
                                await io.File(fileData.uri).copy(toPath);
                              }
                              Navigator.of(context).pop();
                              toastUtils.showSuccessToast(AppLocalizations.of(context).getLanguageText('add_success'));
                              widget.callback();
                              setState(() {
                                fileData = fileUtils.path2File(toPath);
                              });
                            },
                          );
                        },
                      ),
                      InkWell(
                        child: Container(
                          width: 45,
                          height: 45,
                          child: Icon(
                            IconFonts.share,
                            color: ColorUtils.themeColor,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          Share.shareFiles([fileData.uri]);
                        },
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
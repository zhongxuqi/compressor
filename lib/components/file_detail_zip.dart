import 'package:compressor/utils/platform_custom.dart';
import 'package:flutter/material.dart';
import '../common/data.dart' as data;
import 'file_item.dart';
import '../file_detail.dart';
import 'location.dart';
import '../utils/platform_custom.dart';
import 'dart:convert';
import 'loading_dialog.dart';
import '../localization/localization.dart';
import '../utils/file.dart' as fileUtils;

class FileDetailZip extends StatefulWidget {
  final data.File fileData;

  FileDetailZip({Key key, @required this.fileData}):super(key: key);

  @override
  State createState() {
    return _FileDetailZipState();
  }
}

class _FileDetailZipState extends State<FileDetailZip> {
  var files = Map<String, data.File>();
  data.File currentFile;

  Map<String, data.File> getFiles() {
    return currentFile != null ? currentFile.files : files;
  }


  @override
  void initState() {
    super.initState();
    initFiles();
  }

  void initFiles() async {
    final fileHeaders = await getFileHeaders(widget.fileData.uri, '');
    fileHeaders.forEach((e) {
      if (e.isDirectory) return;
      final paths = e.fileName.split("/");
      data.File currentDir;
      for (var i in Iterable<int>.generate(paths.length).toList()) {
        if (i + 1 < paths.length) {
          if (currentDir == null) {
            if (!files.containsKey(paths[i])) {
              files[paths[i]] = data.File(
                paths[i],
                paths.sublist(0, i + 1).join("/"),
                "directory",
                json.encode(data.FileExtra(e.lastModified, e.fileSize).toMap()),
                currentDir,
              );
            }
            currentDir = files[paths[i]];
          } else if (currentDir != null) {
            if (!currentDir.files.containsKey(paths[i])) {
              currentDir.files[paths[i]] = data.File(
                paths[i],
                paths.sublist(0, i + 1).join("/"),
                "directory",
                json.encode(data.FileExtra(e.lastModified, e.fileSize).toMap()),
                currentDir,
              );
            }
            currentDir = currentDir.files[paths[i]];
          }
        } else {
          if (currentDir == null) {
            files[paths[i]] = data.File(
              paths[i],
              e.fileName,
              e.contentType,
              json.encode(data.FileExtra(e.lastModified, e.fileSize).toMap()),
              currentDir,
            );
          } else if (currentDir != null) {
            currentDir.files[paths[i]] = data.File(
              paths[i],
              e.fileName,
              e.contentType,
              json.encode(data.FileExtra(e.lastModified, e.fileSize).toMap()),
              currentDir,
            );
          }
        }
      }
    });
    setState(() {

    });
  }

  List<String> getDirectories() {
    final directories = List<String>();
    var indexFile = currentFile;
    while (indexFile != null) {
      directories.insert(0, indexFile.name);
      indexFile = indexFile.parent;
    }
    return directories;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Location(
            directories: getDirectories(),
            goBack: () {
              if (currentFile == null) return;
              setState(() {
                currentFile = currentFile.parent;
              });
            },
          ),
          Expanded(
            flex: 1,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    getFiles().values.map((e) => FileItem(
                      fileData: e,
                      onClick: () async {
                        if (e.contentType == 'directory') {
                          setState(() {
                            currentFile = e;
                          });
                          return;
                        }
                        showLoadingDialog(context, AppLocalizations.of(context).getLanguageText('extracting'), barrierDismissible: true);
                        final destPath = await extractFile(widget.fileData.uri, '', e.uri);
                        Navigator.of(context).pop();
                        if (destPath.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FileDetailPage(fileData: fileUtils.path2File(destPath))),
                          );
                        }
                      },
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
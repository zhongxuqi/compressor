import 'dart:io' as io;
import 'package:mime/mime.dart';
import 'package:sqflite/sqflite.dart';
import 'data.dart';
import 'database.dart';
import '../utils/platform_custom.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/time.dart';
import 'dart:convert';

class FileModel {
  Database _database;

  Future<Database> getDataBase() async {
    if (_database == null) {
      _database = await getDatabase();
    }
    return _database;
  }

  insertFile(File fileObj) async {
    (await getDataBase()).transaction((txn) async {
      int id = await txn.rawInsert(
          'insert into file(`type`, `name`, `uri`, `parent_id`,`content_type`,`extra`,`create_time`,`update_time`) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
          [
            fileType2Int(fileObj.type),
            fileObj.name,
            fileObj.uri,
            fileObj.parentID,
            fileObj.contentType,
            fileObj.extra,
            fileObj.createTime,
            fileObj.updateTime,
          ]);
      print("inserted: $id");
    });
  }

  updateFile(File fileObj) async {
    (await getDataBase()).transaction((txn) async {
      int count = await txn.rawUpdate(
          'update file set `name` = ?, `uri` = ?, `parent_id` = ?, `content_type` = ?, `extra` = ? WHERE `id` = ?',
          [fileObj.name, fileObj.uri, fileObj.parentID, fileObj.contentType, fileObj.extra, fileObj.id]);
      print("updated: $count");
    });
  }

  Future<File> getFileByID(int id) async {
    List<Map> list = await (await getDataBase()).rawQuery('SELECT * FROM file WHERE `id` = ?', [id]);
    if (list.length == 0) {
      return null;
    }
    return File(
        list[0]['id'],
        int2FileType(list[0]['type']),
        list[0]['name'],
        list[0]['uri'],
        list[0]['parent_id'],
        list[0]['content_type'],
        list[0]['extra'],
        list[0]['create_time'],
        list[0]['update_time']);
  }

  Future<List<File>> listFileByParentID(int parentID) async {
    List<Map> list = await (await getDataBase()).rawQuery('SELECT * FROM file WHERE `parent_id` = ?', [parentID]);
    var fileList = List<File>();
    for (var item in list) {
      fileList.add(File(
          item['id'],
          int2FileType(item['type']),
          item['name'],
          item['uri'],
          item['parent_id'],
          item['content_type'],
          item['extra'],
          item['create_time'],
          item['update_time']));
    }
    return fileList;
  }

  deleteFile(int id) async {
    await (await getDataBase()).transaction((txn) async {
      int count = await txn.rawDelete('delete from file where `id` = ?', [id]);
      print("deleted: $count");
    });
  }
  
  createFileByFileResult(FileResult fileResult) async {
    final f = io.File(fileResult.uri);
    final appDocDir = await getApplicationDocumentsDirectory();
    final targetPath = path.join(appDocDir.path, '${getCurrentTimestamp()}.${fileResult.archiveType}');
    final newFile = await f.copy(targetPath);
    await insertFile(File(
      0,
      FileType.file,
      fileResult.fileName,
      newFile.path,
      0,
      lookupMimeType(newFile.path),
      json.encode(FileExtra(
        newFile.lastModifiedSync().millisecondsSinceEpoch ~/ 1000,
        newFile.lengthSync(),
      ).toMap()),
      getCurrentTimestamp(),
      getCurrentTimestamp(),
    ));
  }
}

FileModel fileModelIns;

FileModel getFileModel() {
  if (fileModelIns == null) {
    fileModelIns = FileModel();
  }
  return fileModelIns;
}

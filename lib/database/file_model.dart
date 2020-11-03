import 'package:sqflite/sqflite.dart';
import 'data.dart';
import 'database.dart';

class FileModel {
  Database database;

  FileModel() {
    initDB();
  }

  initDB() async {
    database = await getDatabase();
  }

  insertFile(File fileObj) async {
    await this.database.transaction((txn) async {
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
    await this.database.transaction((txn) async {
      int count = await txn.rawUpdate(
          'update file set `name` = ?, `uri` = ?, `parent_id` = ?, `content_type` = ?, `extra` = ? WHERE `id` = ?',
          [fileObj.name, fileObj.uri, fileObj.parentID, fileObj.contentType, fileObj.extra]);
      print("updated: $count");
    });
  }

  Future<File> getFileByID(int id) async {
    List<Map> list =
        await this.database.rawQuery('SELECT * FROM file WHERE `id` = ?', [id]);
    if (list.length == 0) {
      return null;
    }
    return File(
        list[0]['id'],
        list[0]['type'],
        list[0]['name'],
        list[0]['uri'],
        list[0]['parent_id'],
        list[0]['content_type'],
        list[0]['extra'],
        list[0]['create_time'],
        list[0]['update_time']);
  }

  Future<List<File>> getFileByParentID(int parentID) async {
    List<Map> list = await this
        .database
        .rawQuery('SELECT * FROM file WHERE `parent_id` = ?', [parentID]);
    var fileList = List<File>();
    for (var item in list) {
      fileList.add(File(
          item['id'],
          item['type'],
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
    await this.database.transaction((txn) async {
      int count = await txn.rawDelete('delete from file where `id` = ?', [id]);
      print("deleted: $count");
    });
  }
}

FileModel fileModelIns;

FileModel getFileModel() {
  if (fileModelIns == null) {
    fileModelIns = FileModel();
  }
  return fileModelIns;
}

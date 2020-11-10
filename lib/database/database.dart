import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Database databaseIns;

Future<Database> getDatabase() async {
  if (databaseIns == null) {
    String path = join(await getDatabasesPath(), "compressor.db");
    databaseIns = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE file (" +
          "`id` integer NOT NULL PRIMARY KEY autoincrement, " +
          "`type` bigint NOT NULL, " +
          "`name` varchar(256) NOT NULL, " +
          "`uri` varchar(512) NOT NULL, " +
          "`parent_id` bigint NOT NULL, " +
          "`content_type` varchar(64) NOT NULL, " +
          "`extra` varchar(1024) NOT NULL," +
          "`create_time` bigint NOT NULL," +
          "`update_time` bigint NOT NULL" +
          ")");
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {});
  }
  return databaseIns;
}

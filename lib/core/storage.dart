import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalStore {
  LocalStore(this.db) {
    db.execute('CREATE TABLE IF NOT EXISTS app_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    db.execute('PRAGMA user_version = 1');
  }
  final Database db;
  static Future<LocalStore> open() async {
    final dir=await getApplicationSupportDirectory();
    await dir.create(recursive:true);
    return LocalStore(sqlite3.open('${dir.path}${Platform.pathSeparator}finscope.sqlite3'));
  }
  Map<String,dynamic>? read(String key) {
    final rows=db.select('SELECT value FROM app_state WHERE key = ?', [key]);
    return rows.isEmpty?null:Map<String,dynamic>.from(jsonDecode(rows.first['value'] as String) as Map);
  }
  void write(String key,Map<String,dynamic> value) => db.execute('INSERT INTO app_state(key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',[key,jsonEncode(value)]);
  void close()=>db.dispose();
}

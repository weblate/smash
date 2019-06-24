/*
 * Copyright (c) 2019. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */
import 'package:sqflite/sqflite.dart';
import 'package:latlong/latlong.dart';
import 'package:geopaparazzi_light/eu/geopaparazzi/library/utils/utils.dart';

import 'package:geopaparazzi_light/eu/geopaparazzi/library/database/project_tables_objects.dart';

/// Create the geopaparazzi project database.
void createDatabase(Database db) async {
  var createTablesQuery = '''
    CREATE TABLE $TABLE_NOTES (  
      $NOTES_COLUMN_ID  INTEGER PRIMARY KEY AUTOINCREMENT, 
      $NOTES_COLUMN_LON  REAL NOT NULL,  
      $NOTES_COLUMN_LAT  REAL NOT NULL, 
      $NOTES_COLUMN_ALTIM  REAL NOT NULL, 
      $NOTES_COLUMN_TS LONG NOT NULL, 
      $NOTES_COLUMN_DESCRIPTION TEXT,  
      $NOTES_COLUMN_TEXT TEXT NOT NULL,  
      $NOTES_COLUMN_FORM CLOB,  
      $NOTES_COLUMN_STYLE  TEXT, 
      $NOTES_COLUMN_ISDIRTY  INTEGER 
    );
    CREATE INDEX notes_ts_idx ON $TABLE_NOTES ($NOTES_COLUMN_TS);
    CREATE INDEX notes_x_by_y_idx ON $TABLE_NOTES ($NOTES_COLUMN_LON, $NOTES_COLUMN_LAT);
    CREATE INDEX notes_isdirty_idx ON $TABLE_NOTES ($NOTES_COLUMN_ISDIRTY);
    
    CREATE TABLE $TABLE_GPSLOGS (
      $LOGS_COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT, 
      $LOGS_COLUMN_STARTTS LONG NOT NULL,
      $LOGS_COLUMN_ENDTS LONG NOT NULL,
      $LOGS_COLUMN_LENGTHM REAL NOT NULL, 
      $LOGS_COLUMN_ISDIRTY INTEGER NOT NULL, 
      $LOGS_COLUMN_TEXT TEXT NOT NULL 
    );
    CREATE TABLE $TABLE_GPSLOG_DATA (
      $LOGSDATA_COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT, 
      $LOGSDATA_COLUMN_LON  REAL NOT NULL, 
      $LOGSDATA_COLUMN_LAT  REAL NOT NULL,
      $LOGSDATA_COLUMN_ALTIM  REAL NOT NULL,
      $LOGSDATA_COLUMN_TS  LONG NOT NULL,
      $LOGSDATA_COLUMN_LOGID  INTEGER NOT NULL 
          CONSTRAINT $LOGSDATA_COLUMN_LOGID 
          REFERENCES $TABLE_GPSLOGS ( $LOGS_COLUMN_ID ) 
          ON DELETE CASCADE
    );
    CREATE INDEX gpslog_id_idx ON $TABLE_GPSLOG_DATA ( $LOGSDATA_COLUMN_LOGID );
    CREATE INDEX gpslog_ts_idx ON $TABLE_GPSLOG_DATA ( $LOGSDATA_COLUMN_TS );
    CREATE INDEX gpslog_x_by_y_idx ON $TABLE_GPSLOG_DATA ( $LOGSDATA_COLUMN_LON, $LOGSDATA_COLUMN_LAT );
    CREATE INDEX gpslog_logid_x_y_idx ON $TABLE_GPSLOG_DATA ( $LOGSDATA_COLUMN_LOGID, $LOGSDATA_COLUMN_LON, $LOGSDATA_COLUMN_LAT );
    
    CREATE TABLE $TABLE_GPSLOG_PROPERTIES (
      $LOGSPROP_COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT, 
      $LOGSPROP_COLUMN_LOGID INTEGER NOT NULL 
          CONSTRAINT $LOGSPROP_COLUMN_LOGID 
          REFERENCES $TABLE_GPSLOGS ( $LOGS_COLUMN_ID ) 
          ON DELETE CASCADE,
      $LOGSPROP_COLUMN_COLOR  TEXT NOT NULL, 
      $LOGSPROP_COLUMN_WIDTH  REAL NOT NULL, 
      $LOGSPROP_COLUMN_VISIBLE  INTEGER NOT NULL
    );
    
    CREATE TABLE $TABLE_BOOKMARKS (
      $BOOKMARK_COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $BOOKMARK_COLUMN_LON REAL NOT NULL, 
      $BOOKMARK_COLUMN_LAT REAL NOT NULL,
      $BOOKMARK_COLUMN_ZOOM REAL NOT NULL,
      $BOOKMARK_COLUMN_TEXT TEXT NOT NULL 
    );
    CREATE INDEX bookmarks_x_by_y_idx ON $TABLE_BOOKMARKS ($BOOKMARK_COLUMN_LAT, $BOOKMARK_COLUMN_LON);
    
    CREATE TABLE $TABLE_IMAGES (
      $IMAGES_COLUMN_ID  INTEGER PRIMARY KEY AUTOINCREMENT,
      $IMAGES_COLUMN_LON REAL NOT NULL,
      $IMAGES_COLUMN_LAT REAL NOT NULL,
      $IMAGES_COLUMN_ALTIM REAL NOT NULL,
      $IMAGES_COLUMN_AZIM REAL NOT NULL,
      $IMAGES_COLUMN_IMAGEDATA_ID INTEGER NOT NULL 
          CONSTRAINT $IMAGES_COLUMN_IMAGEDATA_ID
          REFERENCES $TABLE_IMAGE_DATA ($IMAGESDATA_COLUMN_ID)
          ON DELETE CASCADE,
      $IMAGES_COLUMN_TS LONG NOT NULL,
      $IMAGES_COLUMN_TEXT TEXT NOT NULL,
      $IMAGES_COLUMN_NOTE_ID INTEGER,
      $IMAGES_COLUMN_ISDIRTY INTEGER NOT NULL
    );
    
    CREATE INDEX images_ts_idx ON $TABLE_IMAGES ($IMAGES_COLUMN_TS);
    CREATE INDEX images_noteid_idx ON $TABLE_IMAGES ($IMAGES_COLUMN_NOTE_ID);
    CREATE INDEX images_isdirty_idx ON $TABLE_IMAGES ($IMAGES_COLUMN_ISDIRTY);
    CREATE INDEX images_x_by_y_idx ON $TABLE_IMAGES ($IMAGES_COLUMN_LAT, $IMAGES_COLUMN_LON);
    
    CREATE TABLE $TABLE_IMAGE_DATA (
      $IMAGESDATA_COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $IMAGESDATA_COLUMN_IMAGE BLOB NOT NULL,
      $IMAGESDATA_COLUMN_THUMBNAIL BLOB NOT NULL
    );
  ''';

  await db.transaction((tx) async {
    var split = createTablesQuery.replaceAll("\n", "").trim().split(";");
    for (int i = 0; i < split.length; i++) {
      var sql = split[i].trim();
      if (sql.length > 0 && !sql.startsWith("--")) {
        await tx.execute(sql);
      }
    }
  });
}

/// Get the count of the current notes
///
/// Get the count on a given [db], using [onlyDirty] to count only dirty notes.
Future<int> getNotesCount(Database db, bool onlyDirty) async {
  String where = !onlyDirty ? "" : " where ${NOTES_COLUMN_ISDIRTY} = 1";
  List<Map<String, dynamic>> resNotes = await db
      .rawQuery("SELECT count(*) as count FROM ${TABLE_NOTES} ${where}");

  var resNote = resNotes[0];
  var count = resNote["count"];
  return count;
}

/*
 * Add a note.
 *
 * @param db the database.
 * @param note the note to insert.
 * @return the inserted note id.
 */
Future<int> addNote(Database db, Note note) {
  var noteId = db.insert(TABLE_NOTES, note.toMap());
  return noteId;
}

/// Get the count of the current logs
///
/// Get the count on a given [db], using [onlyDirty] to count only dirty notes.
Future<int> getGpsLogCount(Database db, bool onlyDirty) async {
  String where = !onlyDirty ? "" : " where ${LOGS_COLUMN_ISDIRTY} = 1";
  var sql = "SELECT count(*) as count FROM ${TABLE_GPSLOGS}${where}";
  List<Map<String, dynamic>> resMap = await db.rawQuery(sql);

  var res = resMap[0];
  var count = res["count"];
  return count;
}

Future<int> addGpsLog(Database db, Log insertLog, LogProperty prop) async {
  // TODO use transaction
  int insertedId = await db.insert(TABLE_GPSLOGS, insertLog.toMap());
  prop.logid = insertedId;
  await db.insert(TABLE_GPSLOG_PROPERTIES, prop.toMap());
  return insertedId;
}

Future<int> addGpsLogPoint(
    Database db, int logId, LogDataPoint logPoint) async {
  logPoint.logid = logId;
  int insertedId = await db.insert(TABLE_GPSLOG_DATA, logPoint.toMap());
  return insertedId;
}

Future<int> updateGpsLogEndts(Database db, int logId, int endTs) async {
  var updatedId = await db.rawUpdate(
      "update ${TABLE_GPSLOGS} set ${LOGS_COLUMN_ENDTS}=${endTs} where ${LOGS_COLUMN_ID}=${logId}");
  return updatedId;
}
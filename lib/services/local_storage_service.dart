import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/guest_user.dart';
import '../models/sync_conflict.dart';
import '../models/sync_operation.dart';
import '../models/user_sync_data.dart';

class LocalStorageService {
  static const String _databaseName = 'english_ai_app.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String userSyncDataTable = 'user_sync_data';
  static const String syncOperationsTable = 'sync_operations';
  static const String guestUsersTable = 'guest_users';
  static const String syncConflictsTable = 'sync_conflicts';
  static const String preferencesTable = 'preferences';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // User sync data table
    await db.execute('''
      CREATE TABLE $userSyncDataTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        data TEXT NOT NULL,
        lastModified TEXT NOT NULL,
        version INTEGER DEFAULT 1
      )
    ''');

    // Sync operations table
    await db.execute('''
      CREATE TABLE $syncOperationsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        type TEXT NOT NULL,
        collection TEXT NOT NULL,
        documentId TEXT NOT NULL,
        data TEXT NOT NULL,
        metadata TEXT NOT NULL,
        status TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0,
        errorMessage TEXT,
        createdAt TEXT NOT NULL,
        completedAt TEXT
      )
    ''');

    // Guest users table
    await db.execute('''
      CREATE TABLE $guestUsersTable (
        guestId TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastActiveAt TEXT NOT NULL
      )
    ''');

    // Sync conflicts table
    await db.execute('''
      CREATE TABLE $syncConflictsTable (
        conflictId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        collection TEXT NOT NULL,
        documentId TEXT NOT NULL,
        localData TEXT NOT NULL,
        remoteData TEXT NOT NULL,
        localMetadata TEXT NOT NULL,
        remoteMetadata TEXT NOT NULL,
        strategy TEXT NOT NULL,
        detectedAt TEXT NOT NULL,
        resolved INTEGER DEFAULT 0,
        resolvedData TEXT,
        resolvedAt TEXT
      )
    ''');

    // Preferences table
    await db.execute('''
      CREATE TABLE $preferencesTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        userId TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion; version < newVersion; version++) {
      await _migrate(db, version);
    }
  }

  Future<void> _migrate(Database db, int fromVersion) async {
    switch (fromVersion) {
      case 1:
        // Migración de v1 → v2: agregar nuevas columnas o tablas aquí
        // Ejemplo:
        // await db.execute('ALTER TABLE user_sync_data ADD COLUMN syncStatus TEXT DEFAULT "pending"');
        // await db.execute('''
        //   CREATE TABLE IF NOT EXISTS new_table (
        //     id TEXT PRIMARY KEY,
        //     data TEXT NOT NULL
        //   )
        // ''');
        break;
      default:
        debugPrint(
          '⚠️ No migration defined for v$fromVersion. '
          'Preserving existing data. '
          'Add migration logic in _migrate() before releasing.',
        );
        break;
    }
  }

  // User Sync Data operations
  Future<void> saveUserSyncData(UserSyncData syncData) async {
    final db = await database;
    final data = jsonEncode(syncData.toJson());

    await db.insert(userSyncDataTable, {
      'id': syncData.userId,
      'userId': syncData.userId,
      'data': data,
      'lastModified': DateTime.now().toIso8601String(),
      'version': syncData.metadata.version,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserSyncData?> getUserSyncData(String userId) async {
    final db = await database;
    final maps = await db.query(
      userSyncDataTable,
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    try {
      final data = jsonDecode(maps.first['data'] as String);
      return UserSyncData.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing user sync data: $e');
      return null;
    }
  }

  Future<void> deleteUserSyncData(String userId) async {
    final db = await database;
    await db.delete(
      userSyncDataTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // Sync Operations operations
  Future<void> saveSyncOperation(SyncOperation operation) async {
    final db = await database;

    await db.insert(syncOperationsTable, {
      'id': operation.id,
      'userId': operation.userId,
      'type': operation.type.name,
      'collection': operation.collection,
      'documentId': operation.documentId,
      'data': jsonEncode(operation.data),
      'metadata': jsonEncode(operation.metadata.toJson()),
      'status': operation.status.name,
      'retryCount': operation.retryCount,
      'errorMessage': operation.errorMessage,
      'createdAt': operation.metadata.timestamp.toIso8601String(),
      'completedAt': operation.completedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SyncOperation>> getPendingSyncOperations(String userId) async {
    final db = await database;
    final maps = await db.query(
      syncOperationsTable,
      where: 'userId = ? AND status = ?',
      whereArgs: [userId, SyncStatus.pending.name],
      orderBy: 'createdAt ASC',
    );

    try {
      return maps.map((map) {
        final data = Map<String, dynamic>.from(
          jsonDecode(map['data'] as String),
        );
        final metadata = Map<String, dynamic>.from(
          jsonDecode(map['metadata'] as String),
        );
        final operationData = {...data, 'metadata': metadata};
        return SyncOperation.fromJson(operationData);
      }).toList();
    } catch (e) {
      debugPrint('Error parsing sync operations: $e');
      return [];
    }
  }

  Future<void> updateSyncOperationStatus(
    String operationId,
    SyncStatus status, {
    String? errorMessage,
    DateTime? completedAt,
  }) async {
    final db = await database;
    await db.update(
      syncOperationsTable,
      {
        'status': status.name,
        'errorMessage': errorMessage,
        'completedAt': completedAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  Future<void> incrementRetryCount(String operationId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $syncOperationsTable SET retryCount = retryCount + 1 WHERE id = ?',
      [operationId],
    );
  }

  // Guest User operations
  Future<void> saveGuestUser(GuestUser guestUser) async {
    final db = await database;
    final data = jsonEncode(guestUser.toJson());

    await db.insert(guestUsersTable, {
      'guestId': guestUser.guestId,
      'data': data,
      'createdAt': guestUser.createdAt.toIso8601String(),
      'lastActiveAt': guestUser.lastActiveAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<GuestUser?> getGuestUser(String guestId) async {
    final db = await database;
    final maps = await db.query(
      guestUsersTable,
      where: 'guestId = ?',
      whereArgs: [guestId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    try {
      final data = jsonDecode(maps.first['data'] as String);
      return GuestUser.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing guest user: $e');
      return null;
    }
  }

  Future<List<GuestUser>> getAllGuestUsers() async {
    final db = await database;
    final maps = await db.query(guestUsersTable);

    try {
      return maps.map((map) {
        final data = jsonDecode(map['data'] as String);
        return GuestUser.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error parsing guest users: $e');
      return [];
    }
  }

  Future<void> deleteGuestUser(String guestId) async {
    final db = await database;
    await db.delete(
      guestUsersTable,
      where: 'guestId = ?',
      whereArgs: [guestId],
    );
  }

  // Sync Conflicts operations
  Future<void> saveSyncConflict(SyncConflict conflict) async {
    final db = await database;
    await db.insert(syncConflictsTable, {
      'conflictId': conflict.conflictId,
      'userId': conflict.userId,
      'collection': conflict.collection,
      'documentId': conflict.documentId,
      'localData': jsonEncode(conflict.localData),
      'remoteData': jsonEncode(conflict.remoteData),
      'localMetadata': jsonEncode(conflict.localMetadata.toJson()),
      'remoteMetadata': jsonEncode(conflict.remoteMetadata.toJson()),
      'strategy': conflict.strategy.name,
      'detectedAt': conflict.detectedAt.toIso8601String(),
      'resolved': conflict.resolved ? 1 : 0,
      'resolvedData': conflict.resolvedData != null
          ? jsonEncode(conflict.resolvedData)
          : null,
      'resolvedAt': conflict.resolvedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SyncConflict>> getUnresolvedConflicts(String userId) async {
    final db = await database;
    final maps = await db.query(
      syncConflictsTable,
      where: 'userId = ? AND resolved = 0',
      whereArgs: [userId],
    );

    try {
      return maps.map((map) {
        final localData = jsonDecode(map['localData'] as String);
        final remoteData = jsonDecode(map['remoteData'] as String);
        final localMetadata = jsonDecode(map['localMetadata'] as String);
        final remoteMetadata = jsonDecode(map['remoteMetadata'] as String);

        final conflictData = {
          'conflictId': map['conflictId'],
          'userId': map['userId'],
          'collection': map['collection'],
          'documentId': map['documentId'],
          'localData': localData,
          'remoteData': remoteData,
          'localMetadata': localMetadata,
          'remoteMetadata': remoteMetadata,
          'strategy': map['strategy'],
          'detectedAt': map['detectedAt'],
          'resolved': map['resolved'] == 1,
          'resolvedData': map['resolvedData'] != null
              ? jsonDecode(map['resolvedData'] as String)
              : null,
          'resolvedAt': map['resolvedAt'],
        };
        return SyncConflict.fromJson(conflictData);
      }).toList();
    } catch (e) {
      debugPrint('Error parsing sync conflicts: $e');
      return [];
    }
  }

  // Preferences operations
  Future<void> savePreference(
    String key,
    String value, {
    String? userId,
  }) async {
    final db = await database;
    await db.insert(preferencesTable, {
      'key': userId != null ? '${userId}_$key' : key,
      'value': value,
      'userId': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getPreference(String key, {String? userId}) async {
    final db = await database;
    final maps = await db.query(
      preferencesTable,
      where: 'key = ?',
      whereArgs: [userId != null ? '${userId}_$key' : key],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  // Cleanup operations
  Future<void> cleanupExpiredData() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    // Clean up old sync operations
    await db.delete(
      syncOperationsTable,
      where: 'status = ? AND createdAt < ?',
      whereArgs: [SyncStatus.completed.name, thirtyDaysAgo.toIso8601String()],
    );

    // Clean up old guest users
    await db.delete(
      guestUsersTable,
      where: 'lastActiveAt < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

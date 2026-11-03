import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/transaction_record.dart';

abstract interface class TransactionRepository {
  Future<List<TransactionRecord>> getAll();
  Future<int> insert(TransactionRecord transaction);
  Future<void> update(TransactionRecord transaction);
  Future<void> delete(int id);
}

class SqfliteTransactionRepository implements TransactionRepository {
  static const _databaseName = 'expense_tracker.db';
  static const _tableName = 'transactions';

  Future<Database>? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final opening = _openDatabase();
    _database = opening;
    try {
      return await opening;
    } catch (_) {
      if (identical(_database, opening)) _database = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    return openDatabase(
      path.join(databasePath, _databaseName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<List<TransactionRecord>> getAll() async {
    final rows = await (await database).query(
      _tableName,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransactionRecord.fromDatabaseMap).toList();
  }

  @override
  Future<int> insert(TransactionRecord transaction) async {
    return (await database).insert(_tableName, transaction.toDatabaseMap());
  }

  @override
  Future<void> update(TransactionRecord transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw ArgumentError.value(
        id,
        'transaction.id',
        'Cannot update without an id',
      );
    }
    await (await database).update(
      _tableName,
      transaction.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await (await database).delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}

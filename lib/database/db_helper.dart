import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todos.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todos.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      isDone INTEGER NOT NULL,
      date TEXT,
      time TEXT NOT NULL,

      repeatType TEXT NOT NULL,
      repeatValue INTEGER,

      category TEXT,
      lastDoneDate TEXT,
      isReminder INTEGER NOT NULL DEFAULT 0,
      reminderTime TEXT,
      notificationId INTEGER
    )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute(
          "ALTER TABLE todos ADD COLUMN repeatType TEXT DEFAULT 'none'");
      await db.execute("ALTER TABLE todos ADD COLUMN repeatValue INTEGER");
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE todos ADD COLUMN isReminder INTEGER NOT NULL DEFAULT 0");
      await db.execute("ALTER TABLE todos ADD COLUMN reminderTime TEXT");
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE todos ADD COLUMN notificationId INTEGER");
    }
  }

  Future<List<Todo>> getTodos() async {
    final db = await instance.database;
    final result = await db.query('todos');
    return result.map((json) => Todo.fromMap(json)).toList();
  }

  Future<void> insertTodo(Todo todo) async {
    final db = await instance.database;
    await db.insert('todos', todo.toMap());
  }

  Future<void> deleteTodo(int id) async {
    final db = await instance.database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTodoStatus(int id, bool isDone) async {
    final db = await instance.database;
    await db.update(
      'todos',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await instance.database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('todos');
  }
}

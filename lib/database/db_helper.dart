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
      version: 3, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Handle migration for existing users
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE todos ADD COLUMN category TEXT");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE todos ADD COLUMN lastDoneDate TEXT");
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    isDone INTEGER NOT NULL,
    date TEXT,
    time TEXT NOT NULL,
    isRepeat INTEGER NOT NULL,
    dayOfWeek INTEGER,
    category TEXT,
    lastDoneDate TEXT
  )
  ''');
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
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTodoStatus(int id, bool isDone) async {
    final db = await database;
    await db.update(
      'todos',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }
}

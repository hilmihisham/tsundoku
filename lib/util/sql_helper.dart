import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {

  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE books(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      title TEXT,
      author TEXT,
      status TEXT,
      datePurchase TEXT,
      dateCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """);
  }

  static Future<void> createTablesV2(sql.Database database) async {
    await database.execute("""CREATE TABLE books(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      title TEXT,
      author TEXT,
      status TEXT,
      datePurchase TEXT,
      dateCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      dateFinished TEXT
    )
    """);
  }

  static Future<void> updateTablesV1toV2(sql.Database database) async {
    await database.execute('ALTER TABLE books ADD dateFinished TEXT');
  }

  // id: the id of a item
  // title, author, status, datePurchase: all about the book data
  // status: 0 new, 1 reading, 2 finished
  // datePurchase: yyyy-MM-dd
  // dateCreated: the time that the item was created. It will be automatically handled by SQLite
  // dateFinished: yyyy-MM-dd

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'tsundoku.db',
      version: 2,
      onCreate: (sql.Database database, int version) async {
        await createTablesV2(database);
      },
      onUpgrade: (sql.Database database, oldVersion, newVersion) async {
        if (oldVersion == 1) {
          await updateTablesV1toV2(database);
        }
      },
    );
  }

  // input new book
  static Future<int> inputBook(String title, String? author, String? status, String? datePurchase, String? dateFinished) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'author': author,
      'status': status,
      'datePurchase': datePurchase,
      'dateCreated': DateTime.now().toString(),
      'dateFinished': dateFinished,
    };

    final id = await db.insert('books', data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace);
    
    return id;
  }

  // insert multiple books
  static Future<int> insertMultiple(List<List> books) async {
    // logger
    final logger = Logger();
    
    final db = await SQLHelper.db();

    var buffer = StringBuffer();
    for (var book in books) { 
      if (buffer.isNotEmpty) {
        buffer.write(",\n");
      }
      // buffer.write = ('id', 'title', 'author', 'status', 'date purchase', 'date finished')
      buffer.write("('");
      buffer.write(book.elementAt(0)); // id
      buffer.write("', '");
      buffer.write(book.elementAt(1)); // title
      buffer.write("', '");
      buffer.write(book.elementAt(2)); // author
      buffer.write("', '");
      buffer.write(book.elementAt(3)); // status
      buffer.write("', '");
      buffer.write(book.elementAt(4)); // date purchase
      buffer.write("', '");
      buffer.write(book.elementAt(5)); // date finished
      buffer.write("')");
    }
    logger.d('buffer = $buffer');

    var raw = await db.rawInsert("INSERT INTO books (id, title, author, status, datePurchase, dateFinished) VALUES ${buffer.toString()}");
    return raw;
  }

  // get all books
  static Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await SQLHelper.db();
    return db.query('books', orderBy: "id");
  }

  // get all books status 0 and 1
  static Future<List<Map<String, dynamic>>> getBooksNewAndReading() async {
    final db = await SQLHelper.db();
    return db.rawQuery("SELECT * FROM books WHERE status IN ('0', '1') ORDER BY status, datePurchase, id");
  }

  // get all books status 2 order by earliest date finish first
  static Future<List<Map<String, dynamic>>> getBooksInFinishedOrder() async {
    final db = await SQLHelper.db();
    return db.rawQuery("SELECT * FROM books WHERE status = '2' ORDER BY dateFinished DESC, datePurchase, id");
  }

  // get book list by status
  static Future<List<Map<String, dynamic>>> getBooksByStatus(String status) async {
    final db = await SQLHelper.db();
    return db.query('books', where: "status = ?", whereArgs: [status], orderBy: "datePurchase");
  }

  // get a book by id
  static Future<List<Map<String, dynamic>>> getBookById(int id) async {
    final db = await SQLHelper.db();
    return db.query('books', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // get count based on book status
  static Future<int?> getCountByStatus(String status) async {
    final db = await SQLHelper.db();
    int? count = sql.Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM books WHERE status = $status'));
    return count;
  }

  // update a book by id
  static Future<int> updateBook(int id, String title, String? author, String? status, String? datePurchase, String? dateFinished) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'author': author,
      'status': status,
      'datePurchase': datePurchase,
      'dateFinished': dateFinished,
    };

    final result = await db.update('books', data, where: "id = ?", whereArgs: [id]);

    return result;
  }

  // delete a book by id
  static Future<void> deleteBook(int id) async {
    // logger
    final logger = Logger();

    final db = await SQLHelper.db();
    try {
      await db.delete("books", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      logger.e("Error deleting a book: $e", error: 'Error',);
    }
  }

  // delete all books from table
  static Future<int> deleteAllBooks() async {
    // logger
    final logger = Logger();

    final db = await SQLHelper.db();
    int result = 0;
    try {
      result = await db.delete("books");
    } catch (e) {
      logger.e("Error deleting all books: $e", error: 'Error',);
    }
    return result;
  }

}


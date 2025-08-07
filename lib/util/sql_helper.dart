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
      dateCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      dateFinished TEXT,
      isbn TEXT,
      publisher TEXT
    )
    """);
  }

  // static Future<void> createTables(sql.Database database) async {
  //   await database.execute("""CREATE TABLE books(
  //     id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  //     title TEXT,
  //     author TEXT,
  //     status TEXT,
  //     datePurchase TEXT,
  //     dateCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  //   )
  //   """);
  // }

  // static Future<void> createTablesV2(sql.Database database) async {
  //   await database.execute("""CREATE TABLE books(
  //     id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  //     title TEXT,
  //     author TEXT,
  //     status TEXT,
  //     datePurchase TEXT,
  //     dateCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  //     dateFinished TEXT
  //   )
  //   """);
  // }

  // static Future<void> createTablesV3(sql.Database database) async {
  //   await database.execute("""CREATE TABLE books(
  //     id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  //     title TEXT,
  //     author TEXT,
  //     status TEXT,
  //     datePurchase TEXT,
  //     dateCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  //     dateFinished TEXT,
  //     isbn TEXT
  //   )
  //   """);
  // }

  // static Future<void> updateTablesV1toV2(sql.Database database) async {
  //   await database.execute('ALTER TABLE books ADD dateFinished TEXT');
  // }

  // static Future<void> updateTablesV2toV3(sql.Database database) async {
  //   await database.execute('ALTER TABLE books ADD isbn TEXT');
  // }

  // id: the id of a item
  // title, author, status, datePurchase: all about the book data
  // status: 0 new, 1 reading, 2 finished
  // datePurchase: yyyy-MM-dd
  // dateCreated: the time that the item was created. It will be automatically handled by SQLite
  // dateFinished: yyyy-MM-dd
  // isbn: ISBN-13 number
  // publisher: book publisher (can get from google books api as well)

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'tsundoku.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
      // onUpgrade: (sql.Database database, oldVersion, newVersion) async {
      //   if (oldVersion == 1) {
      //     await updateTablesV1toV2(database);
      //   }
      //   if (oldVersion == 2) {
      //     await updateTablesV2toV3(database);
      //   }
      // },
    );
  }

  /// input new book into db
  static Future<int> inputBook(
      String title,
      String? author,
      String? status,
      String? datePurchase,
      String? dateFinished,
      String? isbn,
      String? publisher) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'author': author,
      'status': status,
      'datePurchase': datePurchase,
      'dateCreated': DateTime.now().toString(),
      'dateFinished': dateFinished,
      'isbn': isbn,
      'publisher': publisher,
    };

    final id = await db.insert('books', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);

    return id;
  }

  /// insert multiple books
  static Future<int> insertMultiple(List<List> books) async {
    // logger
    final logger = Logger();

    // regex
    // '''[ to start expression
    // anything inside is the symbol we need to check
    // ]''' to end expression
    final regex = RegExp(r'''[']''');
    const String apostropheReplacement =
        '\'\''; // for sqlite, use double apostrophe to escape

    final db = await SQLHelper.db();

    var buffer = StringBuffer();
    for (var book in books) {
      if (buffer.isNotEmpty) {
        buffer.write(",\n");
      }
      // buffer.write = ('id', 'title', 'author', 'status', 'date purchase', 'date finished', 'isbn','publisher')
      buffer.write("('");
      buffer.write(book.elementAt(0)); // id
      buffer.write("', '");

      if (book.elementAt(1).toString().contains(regex)) {
        String titleString = book.elementAt(1); // title
        String titleStringNew =
            titleString.replaceAll(regex, apostropheReplacement);
        logger.d('new titleString = $titleStringNew');
        buffer.write(titleStringNew);
      } else {
        buffer.write(book.elementAt(1)); // title
      }

      buffer.write("', '");
      buffer.write(book.elementAt(2)); // author
      buffer.write("', '");
      buffer.write(book.elementAt(3)); // status
      buffer.write("', '");
      buffer.write(book.elementAt(4)); // date purchase
      buffer.write("', '");
      buffer.write(book.elementAt(5)); // date finished
      buffer.write("', '");
      buffer.write(book.elementAt(6)); // isbn
      buffer.write("', '");
      buffer.write(book.elementAt(7)); // publisher
      buffer.write("')");
    }
    logger.d(
        'INSERT INTO books (id, title, author, status, datePurchase, dateFinished, isbn, publisher) VALUES ${buffer.toString()}');

    var raw = await db.rawInsert(
        "INSERT INTO books (id, title, author, status, datePurchase, dateFinished, isbn, publisher) VALUES ${buffer.toString()}");
    return raw;
  }

  /// get all books
  static Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await SQLHelper.db();
    return db.query('books', orderBy: "id");
  }

  /// get all books status 0 and 1
  static Future<List<Map<String, dynamic>>> getBooksNewAndReading() async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        "SELECT * FROM books WHERE status IN ('0', '1') ORDER BY status, datePurchase, id");
  }

  /// get all books status 2 (finished) order by earliest date finish first
  static Future<List<Map<String, dynamic>>> getBooksInFinishedOrder() async {
    final db = await SQLHelper.db();
    // note: asc will make empty date top
    return db.rawQuery(
        "SELECT * FROM books WHERE status = '2' ORDER BY dateFinished DESC, datePurchase DESC, author, title, id");
  }

  /// get book list by status
  static Future<List<Map<String, dynamic>>> getBooksByStatus(
      String status) async {
    final db = await SQLHelper.db();
    return db.query('books',
        where: "status = ?", whereArgs: [status], orderBy: "datePurchase");
  }

  /// get a book by id
  static Future<List<Map<String, dynamic>>> getBookById(int id) async {
    final db = await SQLHelper.db();
    return db.query('books', where: "id = ?", whereArgs: [id], limit: 1);
  }

  /// get count based on book status
  static Future<int?> getCountByStatus(String status) async {
    final db = await SQLHelper.db();
    int? count = sql.Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM books WHERE status = $status'));
    return count;
  }

  /// update a book by id
  static Future<int> updateBook(
      int id,
      String title,
      String? author,
      String? status,
      String? datePurchase,
      String? dateFinished,
      String? isbn,
      String? publisher) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'author': author,
      'status': status,
      'datePurchase': datePurchase,
      'dateFinished': dateFinished,
      'isbn': isbn,
      'publisher': publisher,
    };

    final result =
        await db.update('books', data, where: "id = ?", whereArgs: [id]);

    return result;
  }

  /// delete a book by id
  static Future<void> deleteBook(int id) async {
    // logger
    final logger = Logger();

    final db = await SQLHelper.db();
    try {
      await db.delete("books", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      logger.e(
        "Error deleting a book: $e",
        error: 'Error',
      );
    }
  }

  /// delete all books from table
  static Future<int> deleteAllBooks() async {
    // logger
    final logger = Logger();

    final db = await SQLHelper.db();
    int result = 0;
    try {
      result = await db.delete("books");
    } catch (e) {
      logger.e(
        "Error deleting all books: $e",
        error: 'Error',
      );
    }
    return result;
  }

  // -------------- getter for StatsScreen ------------------

  /// get all books with date purchase, date finished
  static Future<List<Map<String, dynamic>>>
      getBooksWithDatePurchaseAndFinished() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT * FROM books 
      WHERE status = '2'
        AND (datePurchase IS NOT NULL AND datePurchase != '')
        AND (dateFinished IS NOT NULL AND dateFinished != '')
      ORDER BY id
    """);
  }

  /// get longest time to start reading (status 0)
  /// now reading with longest time (status 1)
  static Future<List<Map<String, dynamic>>> getBooksWithDatePurchaseAndStatus(
      int status) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT * FROM books 
      WHERE status = '$status'
        AND (datePurchase IS NOT NULL AND datePurchase != '')
      ORDER BY id
    """);
  }

  /// get latest book in each category
  /// (since query is union, so we need to use subquery (coz got ORDER BY) to eliminate error wrong clause order)
  static Future<List<Map<String, dynamic>>> getLatestBooksInEachStatus() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT * 
      FROM (
            SELECT * FROM books 
            WHERE status = '0'
              AND (datePurchase IS NOT NULL AND datePurchase != '')
            ORDER BY datePurchase DESC
            LIMIT 1
      )

      UNION

      SELECT * 
      FROM (
            SELECT * FROM books 
            WHERE status = '2'
              AND (dateFinished IS NOT NULL AND dateFinished != '')
            ORDER BY dateFinished DESC
            LIMIT 1
      )
    """);
  }

  // -------------- getter for SearchScreen ------------------

  /// get all books that contains the searched title
  static Future<List<Map<String, dynamic>>> getBooksByTitleSearch(
      String title) async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        "SELECT * FROM books WHERE title LIKE '%$title%' ORDER BY status, datePurchase, id");
  }
}

import 'package:flutter/material.dart';
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

  // id: the id of a item
  // title, author, status, datePurchase: all about the book data
  // status: 0 new, 1 reading, 2 finished
  // datePurchase: yyyy-MM-dd
  // dateCreated: the time that the item was created. It will be automatically handled by SQLite

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'tsundoku.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      }
    );
  }

  // input new book
  static Future<int> inputBook(String title, String? author, String? status, String? datePurchase) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'author': author,
      'status': status,
      'datePurchase': datePurchase,
      'dateCreated': DateTime.now().toString(),
    };

    final id = await db.insert('books', data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace);
    
    return id;
  }

  // get all books
  static Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await SQLHelper.db();
    return db.query('books', orderBy: "status, datePurchase, id");
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
  static Future<int> updateBook(int id, String title, String? author, String? status, String? datePurchase) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'author': author,
      'status': status,
      'datePurchase': datePurchase,
    };

    final result = await db.update('books', data, where: "id = ?", whereArgs: [id]);

    return result;
  }

  // delete a book by id
  static Future<void> deleteBook(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("books", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      debugPrint("Error deleting a book: $e");
    }
  }

}


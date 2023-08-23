import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tsundoku/screen/addbook_screen.dart';
import 'package:tsundoku/util/sql_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static void refreshBooksCaller() => _HomeScreenState()._refreshBooks();
}

class _HomeScreenState extends State<HomeScreen> {
  // logger
  final logger = Logger();

  // to control showing floating action button
  bool _showFab = true;

  // all books
  List<Map<String, dynamic>> _books = [];

  // books separate by status
  // List<Map<String, dynamic>> _booksNew = [];
  // List<Map<String, dynamic>> _booksReading = [];
  // List<Map<String, dynamic>> _booksFinished = [];

  bool _isLoading = true; // bool for checking loading book list

  int _countBooksNew = 0;
  int _countBooksReading = 0;
  int _countBooksFinished = 0;

  // fetch all data from db
  void _refreshBooks() async {
    //final data = await SQLHelper.getBooks();

    final dataNewAndReading = await SQLHelper.getBooksNewAndReading();
    final dataFinished = await SQLHelper.getBooksInFinishedOrder();

    // final dataBooksNew = await SQLHelper.getBooksByStatus("0");
    // final dataBooksReading = await SQLHelper.getBooksByStatus("1");
    // final dataBooksFinished = await SQLHelper.getBooksByStatus("2");

    final countNewBooks = await SQLHelper.getCountByStatus("0");
    _countBooksNew = countNewBooks!;

    final countReadingBooks = await SQLHelper.getCountByStatus("1");
    _countBooksReading = countReadingBooks!;

    final countFinishedBooks = await SQLHelper.getCountByStatus("2");
    _countBooksFinished = countFinishedBooks!;

    logger.i("new = $_countBooksNew, reading = $_countBooksReading, finished = $_countBooksFinished");

    setState(() {
      //_books = data;
      _books = dataNewAndReading + dataFinished;
      // _books = dataBooksNew + dataBooksReading + dataBooksFinished;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshBooks(); // load books when the app started
  }

  @override
  void dispose() {
    super.dispose();
  }

  // delete a book
  void _deleteItem(int id, String title) async {
    await SQLHelper.deleteBook(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book $title is deleted.'),
          action: SnackBarAction(
            label: 'OK', 
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
    _refreshBooks();
  }

  // delete and re-add books from imported csv
  void _deleteAllAndAddBooks(List<List> listFromCsv) async {
    int deleteCount = await SQLHelper.deleteAllBooks();
    logger.i('all $deleteCount books deleted');

    int lastIdInserted = await SQLHelper.insertMultiple(listFromCsv);
    logger.i('last id inserted = $lastIdInserted');

    _refreshBooks();
  }

  Color bookListColor(String status) {
    
    Color result = Colors.grey;
    
    switch (status) {
      case "0":
        result = Colors.red.shade400;
        break;
      case "1":
        result = Colors.amber;
        break;
      case "2":
        result = Colors.green.shade400;
        break;
    }

    return result;
  }

  Widget alertForOverwrite() {
    return AlertDialog(
      title: const Text('Import from CSV'),
      content: const Text('Current book list is not empty in the database. Overwrite the list?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'OK'),
          child: const Text('OK'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('tsundoku'),
      ),
      body: _isLoading
        ? const Center(
          child: CircularProgressIndicator(),
        )
        : NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              final ScrollDirection direction = notification.direction;
              setState(() {
                if (direction == ScrollDirection.reverse) {
                  _showFab = false;
                }
                else if (direction == ScrollDirection.forward) {
                  _showFab = true;
                }
              });
              return true;
            },
            child: ListView.builder(
              itemCount: _books.length,
              itemBuilder:(context, index) => Card(
                color: bookListColor(_books[index]['status']),
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0,),
                  title: Text(_books[index]['title']),
                  titleTextStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 17, color: Colors.black87,),
                  subtitle: ('2' != _books[index]['status'])
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: _books[index]['author'] + '\n'),
                            const WidgetSpan(child: Icon(Icons.shopping_cart_sharp, size: 18.0,)),
                            TextSpan(text: ' ${_books[index]['datePurchase']}'),
                          ],
                        ),
                      )
                    : Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: _books[index]['author'] + '\n'),
                            const WidgetSpan(child: Icon(Icons.shopping_cart_sharp, size: 18.0,)),
                            TextSpan(text: ' ${_books[index]['datePurchase']} \n'),
                            const WidgetSpan(child: Icon(Icons.done_all, size: 18.0,)),
                            TextSpan(text: ' ${_books[index]['dateFinished']}'),
                          ],
                        ),
                      ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            var result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddBookScreen(id: _books[index]['id'], book: _books[index])));

                            if (result != null && result) {
                              setState(() {
                                _refreshBooks();
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(_books[index]['id'], _books[index]['title']),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal,),
              child: Text(
                'tsundoku\n積ん読',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fiber_new_rounded, color: Colors.red,),
              title: Text('$_countBooksNew new books!'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_sharp, color: Colors.amber,),
              title: Text('$_countBooksReading currently reading.'),
            ),
            ListTile(
              leading: const Icon(Icons.done_all_sharp, color: Colors.green,),
              title: Text('$_countBooksFinished already finished!'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 5.0),
              child: ElevatedButton(
                child: const Text('Export to CSV'),
                onPressed: () async {
                  logger.d('export to csv clicked');
                  List<List<String>> booksList = [];

                  // add identification header to csv text [id],[title],[author],[status],[datePurchase],[dateFinished],[isbn],[publisher]
                  List<String> identificationHeader = ['0','tsundoku','aolabs','0','','','',''];
                  booksList.add(identificationHeader);

                  final sortedBooksList = await SQLHelper.getBooks();

                  // convert book list to type usable for csv
                  for (var i = 0; i < sortedBooksList.length; i++) {
                    // prevent null value from throwing error
                    // String nullProtection = '';
                    // if (sortedBooksList[i]['isbn'] != null) nullProtection = sortedBooksList[i]['isbn'];

                    List<String> oneBookData = [
                      sortedBooksList[i]['id'].toString(),
                      sortedBooksList[i]['title'],
                      sortedBooksList[i]['author'],
                      sortedBooksList[i]['status'],
                      sortedBooksList[i]['datePurchase'],
                      sortedBooksList[i]['dateFinished'],
                      //if (sortedBooksList[i]['isbn'] != null) nullProtection = sortedBooksList[i]['isbn'],
                      //if (sortedBooksList[i]['publisher'] != null) nullProtection = sortedBooksList[i]['publisher']
                    ];
                    // handling for new field added in db (with null value)
                    String nullProtection = '';
                    (sortedBooksList[i]['isbn'] != null) ? oneBookData.add(sortedBooksList[i]['isbn']) : oneBookData.add(nullProtection);
                    (sortedBooksList[i]['publisher'] != null) ? oneBookData.add(sortedBooksList[i]['publisher']) : oneBookData.add(nullProtection);

                    booksList.add(oneBookData);
                  }
                  logger.i('booksList = $booksList');

                  String csvData = const ListToCsvConverter().convert(booksList);
                  logger.i('csvData = $csvData');

                  // check whether permission is given for this app or not.
                  var permissionStatus = await Permission.manageExternalStorage.status;
                  if (!permissionStatus.isGranted) {
                    // ask for permission if not granted
                    var newPermission = await Permission.manageExternalStorage.request();

                    if (!newPermission.isGranted) {
                      logger.w('permission not granted.');

                      // show snack bar informing user of permission status
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to export to CSV - storage access permission is not granted.'),
                          ),
                        );
                      }
                    } 
                    else {
                      logger.d('permission now granted. please try again.');

                      // show snack bar informing user of permission status
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Storage access permission is now granted. Please try again to export to CSV.'),
                          ),
                        );
                      }
                    }
                  }
                  else {
                    // get path to export csv to
                    // final String exportDir = (await getExternalStorageDirectory())!.path;
                    // final String exportPath = "$exportDir/csv-${DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now())}.csv";

                    // init to download folder first
                    Directory directory = Directory("/storage/emulated/0/Download");
                    try {
                      if (Platform.isIOS) {
                        directory = await getApplicationDocumentsDirectory();
                      }
                      else {
                        directory = Directory("/storage/emulated/0/Download");

                        // fallback if download folder didn't exist
                        if (!await directory.exists()) {
                          await getExternalStorageDirectory();
                        }
                      }
                    }
                    catch (err, stack) {
                      logger.e('cannot get download folder path', error: err, stackTrace: stack);
                    }

                    // const String downloadDir = "/storage/emulated/0/Download";
                    final String downloadDir = directory.path;
                    final String filenameCsv = "tsundoku-${DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now())}.csv";
                    final String exportPath = "$downloadDir/$filenameCsv";
                    logger.i('exportPath = $exportPath');
                    
                    // write the csv file
                    final File file = File(exportPath);
                    await file.writeAsString(csvData);

                    // show snack bar with path to exported file
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('All books data is exported at Download/$filenameCsv .'),
                          action: SnackBarAction(
                            label: 'OK', 
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 15.0),
              child: ElevatedButton(
                child: const Text('Import from CSV'),
                onPressed: () async {
                  // open file picker
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    allowedExtensions: ['csv'],
                    type: FileType.custom,
                  );

                  if (result == null) {
                    // user cancel selecting file
                    logger.d('file picking cancelled');
                  }
                  else {
                    String? path = result.files.first.path;
                    logger.i('selected file path = $path');

                    // get file
                    final csvFile = File(path!).openRead();

                    // convert csv to list
                    List<List> listFromCsv = await csvFile.transform(utf8.decoder).transform(const CsvToListConverter()).toList();

                    // safety check on the imported list
                    List safetyRowFromCsv = listFromCsv.first;
                    List defaultIdHeader = [0,'tsundoku','aolabs',0,'','','',''];
                    bool checkPass = listEquals(safetyRowFromCsv, defaultIdHeader);
                    logger.i('list from csv = $listFromCsv, defaultIdHeader = $defaultIdHeader, checkPass = $checkPass');

                    if (checkPass == false && mounted) {
                      // show snack bar for confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Import cancelled. Incompatible CSV file selected.'),
                          action: SnackBarAction(
                            label: 'OK', 
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ),
                      );
                    }
                    else {
                      // remove safety row first (no need to omport that)
                      listFromCsv.removeAt(0);

                      // if _books not null (got existing records) show alert dialog to add or overwrite
                      var overwriteConfirm = 'Cancel';
                      if (_books.isNotEmpty) {
                        overwriteConfirm = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => alertForOverwrite(),));
                      }
                      else {
                        // _books list is empty, then just proceed to write data from csv
                        overwriteConfirm = 'OK';
                      }
                      logger.d('overwrite confirm = $overwriteConfirm');

                      // add csv books into db
                      if ('Cancel'.compareTo(overwriteConfirm) == 0 && mounted) {
                        // show snack bar for confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Import cancelled. Books data won\'t be overwrite.'),
                            action: SnackBarAction(
                              label: 'OK', 
                              onPressed: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }
                      else {
                        // do db works
                        _deleteAllAndAddBooks(listFromCsv);
                        // show snack bar for confirmation
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Import completed. Books data has been updated.'),
                              action: SnackBarAction(
                                label: 'OK', 
                                onPressed: () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                },
                              ),
                            ),
                          );
                        }
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showFab ? Offset.zero : const Offset(0.0, 2.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showFab ? 1.0 : 0.0,
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              var result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddBookScreen(id: -1, book: null)));

              // to rebuild the screen if navigator pop returns true
              if (result != null && result) {
                setState(() {
                  _refreshBooks();
                });
              }
            },
          ),
        ),
      )
    );
  }
}
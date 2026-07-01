import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tsundoku/screen/addbook_screen.dart';
import 'package:tsundoku/screen/settings_screen.dart';
import 'package:tsundoku/util/sql_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static void refreshBooksCaller() => _HomeScreenState()._refreshBooks();
}

class _HomeScreenState extends State<HomeScreen> {
  // logger
  final logger = Logger();

  // to control showing floating action button
  // bool _showFab = true;

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
  Future<void> _refreshBooks() async {
    final dataNewAndReading = await SQLHelper.getBooksNewAndReading();
    final dataFinished = await SQLHelper.getBooksInFinishedOrder();

    final countNewBooks = await SQLHelper.getCountByStatus("0");
    final countReadingBooks = await SQLHelper.getCountByStatus("1");
    final countFinishedBooks = await SQLHelper.getCountByStatus("2");

    if (!mounted) {
      return;
    }

    setState(() {
      _books = dataNewAndReading + dataFinished;
      _countBooksNew = countNewBooks!;
      _countBooksReading = countReadingBooks!;
      _countBooksFinished = countFinishedBooks!;
      _isLoading = false;
    });

    logger.i(
        "new = $_countBooksNew, reading = $_countBooksReading, finished = $_countBooksFinished");
  }

  Future<void> _handleAddBook() async {
    if (!mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddBookScreen(id: -1, book: null),
      ),
    );

    if (result != null && result) {
      _refreshBooks();
    }
  }

  Future<void> _handleEditBook(Map<String, dynamic> book) async {
    if (!mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBookScreen(id: book['id'], book: book),
      ),
    );

    if (result != null && result) {
      _refreshBooks();
    }
  }

  Future<void> _handleExportCsv() async {
    logger.d('export to csv clicked');
    final booksList = <List<String>>[];

    final identificationHeader = [
      '0',
      'tsundoku',
      'aolabs',
      '0',
      '',
      '',
      '',
      ''
    ];
    booksList.add(identificationHeader);

    final sortedBooksList = await SQLHelper.getBooks();

    for (var i = 0; i < sortedBooksList.length; i++) {
      final oneBookData = <String>[
        sortedBooksList[i]['id'].toString(),
        '${sortedBooksList[i]['title']}',
        '${sortedBooksList[i]['author']}',
        '${sortedBooksList[i]['status']}',
        '${sortedBooksList[i]['datePurchase']}',
        '${sortedBooksList[i]['dateFinished']}',
      ];

      oneBookData.add(
          sortedBooksList[i]['isbn']?.toString() ?? '');
      oneBookData.add(
          sortedBooksList[i]['publisher']?.toString() ?? '');

      booksList.add(oneBookData);
    }
    logger.i('booksList = $booksList');

    final csvData = const CsvEncoder().convert(booksList);
    logger.i('csvData = $csvData');

    final permissionStatus = await Permission.manageExternalStorage.status;
    if (!permissionStatus.isGranted) {
      final newPermission = await Permission.manageExternalStorage.request();

      if (!newPermission.isGranted) {
        logger.w('permission not granted.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unable to export to CSV - storage access permission is not granted.'),
              duration: Duration(seconds: 4),
              showCloseIcon: true,
              closeIconColor: Colors.deepOrange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        logger.d('permission now granted. please try again.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Storage access permission is now granted. Please try again to export to CSV.'),
              duration: Duration(seconds: 4),
              showCloseIcon: true,
              closeIconColor: Colors.deepOrange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    Directory directory = Directory('/storage/emulated/0/Download');
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');

        if (!await directory.exists()) {
          await getExternalStorageDirectory();
        }
      }
    } catch (err, stack) {
      logger.e('cannot get download folder path', error: err, stackTrace: stack);
    }

    final downloadDir = directory.path;
    final filenameCsv =
        'tsundoku-${DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now())}.csv';
    final exportPath = '$downloadDir/$filenameCsv';
    logger.i('exportPath = $exportPath');

    final file = File(exportPath);
    await file.writeAsString(csvData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All books data is exported at Download/$filenameCsv .'),
          duration: const Duration(seconds: 4),
          showCloseIcon: true,
          closeIconColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleImportCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await FilePicker.pickFiles(
      allowedExtensions: ['csv'],
      type: FileType.custom,
    );

    if (result == null) {
      logger.d('file picking cancelled');
      return;
    }

    if (!mounted) {
      return;
    }

    final path = result.files.first.path;
    logger.i('selected file path = $path');

    final csvFile = File(path!).openRead();

    final listFromCsv = await csvFile
        .transform(utf8.decoder)
        .transform(const CsvDecoder())
        .toList();

    final safetyRowFromCsv = listFromCsv.first;
    final defaultIdHeader = [
      '0',
      'tsundoku',
      'aolabs',
      '0',
      '',
      '',
      '',
      ''
    ];
    final checkPass = listEquals(safetyRowFromCsv, defaultIdHeader);
    logger.i(
        'list from csv = $listFromCsv, defaultIdHeader = $defaultIdHeader, checkPass = $checkPass');

    if (checkPass == false) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Import cancelled. Incompatible CSV file selected.'),
          duration: Duration(seconds: 4),
          showCloseIcon: true,
          closeIconColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    listFromCsv.removeAt(0);

    var overwriteConfirm = 'Cancel';
    if (_books.isNotEmpty) {
      if (!mounted) {
        return;
      }
      overwriteConfirm = await navigator.push(MaterialPageRoute(
        builder: (context) => alertForOverwrite(),
      ));
    } else {
      overwriteConfirm = 'OK';
    }
    logger.d('overwrite confirm = $overwriteConfirm');

    if ('Cancel'.compareTo(overwriteConfirm) == 0) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Import cancelled. Books data won\'t be overwrite.'),
          duration: Duration(seconds: 4),
          showCloseIcon: true,
          closeIconColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _deleteAllAndAddBooks(listFromCsv);

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Import completed. Books data has been updated.'),
        duration: Duration(seconds: 4),
        showCloseIcon: true,
        closeIconColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBookList() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: kFloatingActionButtonMargin + 60,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return _BookListItem(
          book: book,
          bookColor: bookListColor(book['status'].toString()),
          onTap: () {
            logger.i('tapped: ${book['title']}');
            _showBookDetails(context, book['id']);
          },
          onEdit: () => _handleEditBook(book),
          onDelete: () => _deleteItem(book['id'], book['title']),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromRGBO(141, 166, 131, 1.0),
            ),
            child: Text(
              'tsundoku\n積ん読',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.fiber_new_rounded,
              color: Colors.red,
            ),
            title: Text('$_countBooksNew new books!'),
          ),
          ListTile(
            leading: const Icon(
              Icons.menu_book_sharp,
              color: Colors.amber,
            ),
            title: Text('$_countBooksReading currently reading.'),
          ),
          ListTile(
            leading: const Icon(
              Icons.done_all_sharp,
              color: Colors.green,
            ),
            title: Text('$_countBooksFinished already finished!'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 5.0),
            child: FilledButton.tonal(
              onPressed: _handleExportCsv,
              child: const Text('Export to CSV'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 15.0),
            child: FilledButton.tonal(
              onPressed: _handleImportCsv,
              child: const Text('Import from CSV'),
            ),
          ),
          const ListTile(
            leading: Icon(
              Icons.code_sharp,
              color: Colors.grey,
            ),
            title: Text(
              'tsundoku v0.7.1',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
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
          content: Text("Book '$title' is deleted."),
          duration: const Duration(seconds: 4),
          showCloseIcon: true,
          closeIconColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          // action: SnackBarAction(
          //   label: 'OK',
          //   onPressed: () {
          //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
          //   },
          // ),
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
      content: const Text(
          'Current book list is not empty in the database. Overwrite the list?'),
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

  /// show simple dialog for more book details when user tap ListTile
  void _showBookDetails(BuildContext ctx, int id) async {
    logger.i('_showBookDetails tapped for book id $id');

    final selectedBook = _books.firstWhere((element) => element['id'] == id);
    logger.i('selected book = $selectedBook');

    showDialog(
        context: ctx,
        builder: (_) {
          return SimpleDialog(
            title: Text("${selectedBook['title']}"),
            surfaceTintColor: bookListColor(selectedBook['status']),
            children: [
              Container(
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Title: ${selectedBook['title']}"),
                    Text("Author: ${selectedBook['author']}"),
                    Text("Publisher: ${selectedBook['publisher']}"),
                    const Divider(),
                    Text("Date of Purchase: ${selectedBook['datePurchase']}"),
                  ],
                ),
              ),
              SimpleDialogOption(
                // padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                onPressed: () {
                  logger.i('SimpleDialog OK pressed');
                  Navigator.of(ctx).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
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
          : _buildBookList(),
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddBook,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BookListItem extends StatelessWidget {
  const _BookListItem({
    required this.book,
    required this.bookColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> book;
  final Color bookColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isFinished = book['status'] == '2';
    final purchaseText = ' ${book['datePurchase']}${isFinished ? ' \n' : ''}';

    return Card(
      color: bookColor,
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 15.0,
        ),
        title: Text(book['title']),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 19,
          color: Colors.black87,
        ),
        subtitle: Text.rich(
          TextSpan(
            children: [
              const WidgetSpan(
                child: Icon(
                  Icons.account_circle_sharp,
                  size: 18.0,
                ),
              ),
              TextSpan(text: ' ${book['author']}\n'),
              const WidgetSpan(
                child: Icon(
                  Icons.storefront_sharp,
                  size: 18.0,
                ),
              ),
              TextSpan(text: ' ${book['publisher']}\n'),
              const WidgetSpan(
                child: Icon(
                  Icons.shopping_cart_sharp,
                  size: 18.0,
                ),
              ),
              TextSpan(text: purchaseText),
              if (isFinished) ...[
                const WidgetSpan(
                  child: Icon(
                    Icons.done_all_sharp,
                    size: 18.0,
                  ),
                ),
                TextSpan(text: ' ${book['dateFinished']}'),
              ],
            ],
          ),
        ),
        trailing: SizedBox(
          width: 100,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

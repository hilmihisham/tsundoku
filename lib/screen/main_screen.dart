import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tsundoku/util/sql_helper.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // all books
  List<Map<String, dynamic>> _books = [];

  // books separate by status
  // List<Map<String, dynamic>> _booksNew = [];
  // List<Map<String, dynamic>> _booksReading = [];
  // List<Map<String, dynamic>> _booksFinished = [];

  bool _isLoading = true;

  int _bookStatus = 0;
  int _countBooksNew = 0;
  int _countBooksReading = 0;
  int _countBooksFinished = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _datePurchaseController = TextEditingController();
  final TextEditingController _dateReadDoneController = TextEditingController();

  // fetch all data from db
  void _refreshBooks() async {
    final data = await SQLHelper.getBooks();

    // final dataBooksNew = await SQLHelper.getBooksByStatus("0");
    // final dataBooksReading = await SQLHelper.getBooksByStatus("1");
    // final dataBooksFinished = await SQLHelper.getBooksByStatus("2");

    final countNewBooks = await SQLHelper.getCountByStatus("0");
    _countBooksNew = countNewBooks!;

    final countReadingBooks = await SQLHelper.getCountByStatus("1");
    _countBooksReading = countReadingBooks!;

    final countFinishedBooks = await SQLHelper.getCountByStatus("2");
    _countBooksFinished = countFinishedBooks!;

    print("new = $_countBooksNew, reading = $_countBooksReading, finished = $_countBooksFinished");

    setState(() {
      _books = data;
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
    _titleController.dispose();
    _authorController.dispose();
    _datePurchaseController.dispose();
    _dateReadDoneController.dispose();
    super.dispose();
  }

  // creating a custom button for book status options
  Widget customBookStatusButton(String buttonName, int value, Color color) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _bookStatus = value;
        });

        // a hack style of getting the button to update its color itself
        // problem: i noticed the color only changed after tapping somewhere else after button was pressed
        // solution: simulate that tapping somewhere else by code (pointer down, wait 2ms, pointer up) 
        WidgetsBinding.instance.handlePointerEvent(PointerDownEvent(
          position: Offset((MediaQuery.of(context).size.width)/2, (MediaQuery.of(context).size.height)-20),
        ));
        Timer(const Duration(milliseconds: 2), () { 
          setState(() {
            WidgetsBinding.instance.handlePointerEvent(PointerUpEvent(
              position: Offset((MediaQuery.of(context).size.width)/2, (MediaQuery.of(context).size.height)-20),
            ));
          });
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5,),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        side: BorderSide(
          width: (_bookStatus == value) ? 2.0 : 0.5,
          color: (_bookStatus == value) ? color : Colors.grey,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              buttonName,
              style: TextStyle(
                color: (_bookStatus == value) ? color : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // method that will trigger when press floating button / update item
  void _showForm(int? id) async {

    print("_showForm clicked, id = $id");

    if (id == null) {
      // id == null -> create new item

      // erase any text in controller just in case modal bottom sheet was closed without any update made
      _titleController.text = '';
      _authorController.text = '';
      _bookStatus = 0;
      _datePurchaseController.text = '';
      _dateReadDoneController.text = '';
    }

    if (id != null) {
      // id != null -> update existing
      final existingBook = _books.firstWhere((element) => element['id'] == id);

      print("existing book title = $existingBook");
      _titleController.text = existingBook['title'];
      _authorController.text = existingBook['author'];
      _bookStatus = int.parse(existingBook['status']);
      _datePurchaseController.text = existingBook['datePurchase'];
      //_dateReadDoneController.text = existingBook['dateFinished'];
    }

    showModalBottomSheet(
      context: context, 
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20, // preventing soft keyboard from covering text fields
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title',),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Author'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: customBookStatusButton('New Book!', 0, Colors.red),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: customBookStatusButton('Reading', 1, Colors.amber),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: customBookStatusButton('Finished', 2, Colors.green),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _datePurchaseController,
              decoration: const InputDecoration(
                icon: Icon(Icons.calendar_today),
                labelText: "Date of Purchase",
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: (_datePurchaseController.text != '') ? DateTime.parse(_datePurchaseController.text) : DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  print(pickedDate);
                  String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate); // format date in required form here we use yyyy-MM-dd that means time is removed
                  print(formattedDate); //formatted date output using intl package =>  2022-07-04

                  setState(() {
                    _datePurchaseController.text = formattedDate;
                  });
                }
                else {
                  print('Date not selected');
                }
              },
            ),
            (_bookStatus == 2) // show date reading done picker if book status = finished
              ? const SizedBox(
                  height: 10,
                )
              : const SizedBox(
                  height: 0,
                )
            ,
            (_bookStatus == 2) // show date reading done picker if book status = finished
              ? TextField(
                  controller: _dateReadDoneController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.done_all_sharp),
                    labelText: "Date Reading Done!",
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDateDone = await showDatePicker(
                      context: context,
                      initialDate: (_dateReadDoneController.text != '') ? DateTime.parse(_dateReadDoneController.text) : DateTime.now(),
                      firstDate: DateTime(1970),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDateDone != null) {
                      print(pickedDateDone);
                      String formattedDateDone = DateFormat('yyyy-MM-dd').format(pickedDateDone); // format date in required form here we use yyyy-MM-dd that means time is removed
                      print(formattedDateDone); //formatted date output using intl package =>  2022-07-04

                      setState(() {
                        _dateReadDoneController.text = formattedDateDone;
                      });
                    }
                    else {
                      print('Date not selected');
                    }
                  },
                )
              :  const SizedBox(
                  height: 0,
                )
            ,
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                // save new book
                if (id == null) {
                  await _addItem();
                }
                if (id != null) {
                  await _updateItem(id);
                }

                // clear text fields
                _titleController.text = '';
                _authorController.text = '';
                _datePurchaseController.text = '';
                _dateReadDoneController.text = '';

                // close bottom sheet
                Navigator.of(context).pop();
              }, 
              child: Text(id == null ? 'Add New Book' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  // insert new book to db
  Future<void> _addItem() async {
    await SQLHelper.inputBook(_titleController.text, _authorController.text, _bookStatus.toString(), _datePurchaseController.text);
    _refreshBooks();
  }

  // update existing book
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateBook(id, _titleController.text, _authorController.text, _bookStatus.toString(), _datePurchaseController.text);
    _refreshBooks();
  }

  // delete a book
  void _deleteItem(int id, String title) async {
    await SQLHelper.deleteBook(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Book $title is deleted.'),
      ),
    );
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
        : ListView.builder(
          itemCount: _books.length,
          itemBuilder:(context, index) => Card(
            color: bookListColor(_books[index]['status']),
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0,),
              title: Text(_books[index]['title']),
              titleTextStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 17, color: Colors.black87,),
              //subtitle: Text(_books[index]['author'] + ' || \u{1F4D6} ' + _books[index]['datePurchase'] + ' || \u{2714} '),
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
                        const TextSpan(text: ' 0000-00-00'),
                      ],
                      //style: const TextStyle(color: Colors.blue)
                    ),
                  ),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showForm(_books[index]['id']),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
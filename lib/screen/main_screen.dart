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

  bool _isLoading = true;

  int bookStatus = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _datePurchaseController = TextEditingController();

  // fetch all data from db
  void _refreshBooks() async {
    final data = await SQLHelper.getBooks();
    setState(() {
      _books = data;
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
    super.dispose();
  }

  // creating a custom button for book status options
  Widget customBookStatusButton(String buttonName, int value, Color color) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          bookStatus = value;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5,),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        side: BorderSide(
          width: (bookStatus == value) ? 2.0 : 0.5,
          color: (bookStatus == value) ? color : Colors.grey,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              buttonName,
              style: TextStyle(
                color: (bookStatus == value) ? color : Colors.grey,
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
      bookStatus = 0;
      _datePurchaseController.text = '';
    }

    if (id != null) {
      // id != null -> update existing
      final existingBook = _books.firstWhere((element) => element['id'] == id);

      print("existing book title = $existingBook");
      _titleController.text = existingBook['title'];
      _authorController.text = existingBook['author'];
      bookStatus = int.parse(existingBook['status']);
      _datePurchaseController.text = existingBook['datePurchase'];
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
    await SQLHelper.inputBook(_titleController.text, _authorController.text, bookStatus.toString(), _datePurchaseController.text);
    _refreshBooks();
  }

  // update existing book
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateBook(id, _titleController.text, _authorController.text, bookStatus.toString(), _datePurchaseController.text);
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
        result = Colors.green;
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
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(_books[index]['title']),
              subtitle: Text(_books[index]['author'] + ' || ' + _books[index]['datePurchase']),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
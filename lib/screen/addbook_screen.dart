import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tsundoku/util/sql_helper.dart';

class AddBookScreen extends StatefulWidget {
  /// [id] value is required. If creating a new book entry, pass in the value as -1.
  /// 
  /// [book] value is required. As of current, [book] object is of type Map<String, dynamic>.
  /// 
  /// On popping the screen from the navigator, return true to indicate there's an entry being inserted/updated.
  const AddBookScreen({Key? key, required this.id, required this.book}) : super(key: key);

  final int id;
  final Map<String, dynamic>? book;

  @override
  State<AddBookScreen> createState() => _AddBookScreen();
}

class _AddBookScreen extends State<AddBookScreen> {

  bool _isForgotDateDone = false;
  bool _isDoneGetDataFromHomeScreen = false;

  int _bookStatus = 0;

  // int? bookId;
  late Map<String, dynamic> existingBook;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _datePurchaseController = TextEditingController();
  final TextEditingController _dateReadDoneController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _datePurchaseController.dispose();
    _dateReadDoneController.dispose();
    super.dispose();
  }

  // create forgot button for finished reading date
  Widget customForgotFinishedReadDateButton() {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _isForgotDateDone = !_isForgotDateDone;
          _dateReadDoneController.text = '';
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

        debugPrint('i forgot lol = $_isForgotDateDone');
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5,),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        side: BorderSide(
          // width: 2.0,
          // color: Colors.green,
          width: (_isForgotDateDone) ? 2.0 : 0.5,
          color: (_isForgotDateDone) ? Colors.green : Colors.grey,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'i forgot lol',
              style: TextStyle(
                // color: Colors.green,
                color: (_isForgotDateDone) ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // creating a custom button for book status options
  Widget customBookStatusButton(String buttonName, int value, Color color) {
    return OutlinedButton(
      onPressed: () {
        // setState(() {
        //   _bookStatus = value;
        // });
        _bookStatus = value;

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
  
  @override
  Widget build(BuildContext context) {

    debugPrint('AddBookScreen building, id = ${widget.id}, _isDoneGetDataFromHomeScreen = $_isDoneGetDataFromHomeScreen');

    if (widget.id != -1 && _isDoneGetDataFromHomeScreen == false) {
      existingBook = widget.book!;
      debugPrint('existing book data = $existingBook');
      _titleController.text = existingBook['title'];
      _authorController.text = existingBook['author'];
      _bookStatus = int.parse(existingBook['status']);
      _datePurchaseController.text = existingBook['datePurchase'];
      (existingBook['dateFinished'] == null) ? _dateReadDoneController.text = '' : _dateReadDoneController.text = existingBook['dateFinished'];
      _isForgotDateDone = false;

      // flip the flag so that we won't refresh all above when screen rebuild mid-edit
      _isDoneGetDataFromHomeScreen = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_sharp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('tsundoku'),
      ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(
              top: 15,
              left: 15,
              right: 15,
              bottom: 15,
              // bottom: MediaQuery.of(context).viewInsets.bottom + 20, // preventing soft keyboard from covering text fields
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header typography
                const Padding(
                  padding: EdgeInsets.only(top: 30.0, bottom: 20.0),
                  child: Text(
                    "Add new book \ninto library.",
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),  
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
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
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _datePurchaseController,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.calendar_today),
                      labelText: "Date of Purchase",
                      border: OutlineInputBorder(),  
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
                        debugPrint(pickedDate.toString());
                        String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate); // format date in required form here we use yyyy-MM-dd that means time is removed
                        debugPrint(formattedDate); //formatted date output using intl.dart package =>  2022-07-04

                        setState(() {
                          _datePurchaseController.text = formattedDate;
                        });
                      }
                      else {
                        debugPrint('Date not selected');
                      }
                    },
                  ),
                ),
                (_bookStatus == 2) // show date reading done picker if book status = finished
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        controller: _dateReadDoneController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.done_all_sharp),
                          labelText: "Date Reading Done!",
                          border: OutlineInputBorder(),  
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDateDone = await showDatePicker(
                            context: context,
                            initialDate: (_dateReadDoneController.text != '') ? DateTime.parse(_dateReadDoneController.text) : DateTime.now(),
                            firstDate: (_datePurchaseController.text != '') ? DateTime.parse(_datePurchaseController.text) : DateTime(1970),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDateDone != null) {
                            debugPrint(pickedDateDone.toString());
                            String formattedDateDone = DateFormat('yyyy-MM-dd').format(pickedDateDone); // format date in required form here we use yyyy-MM-dd that means time is removed
                            debugPrint(formattedDateDone); //formatted date output using intl.dart package =>  2022-07-04

                            setState(() {
                              _dateReadDoneController.text = formattedDateDone;
                            });
                          }
                          else {
                            debugPrint('Date not selected');
                          }
                        },
                      ),
                    )
                  :  const SizedBox(
                      height: 0,
                    )
                ,
                (_bookStatus == 2) // show forgot date reading done button if book status = finished
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(50.0, 10.0, 10.0, 10.0),
                      child: customForgotFinishedReadDateButton(),
                    )
                  : const SizedBox(
                      height: 0,
                    )
                ,
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      
                      // if i forgot date finish is selected
                      if (_isForgotDateDone) {
                        _dateReadDoneController.text = '';
                      }
                      else if ((_bookStatus == 2) && (_dateReadDoneController.text == '')) {
                        // if book finished is selected, but date finished is not inputted, auto select today's date
                        _dateReadDoneController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        debugPrint('date finished auto set to ${_dateReadDoneController.text}');
                      }
                      // save new book
                      if (widget.id == -1) {
                        await _addItem();
                      }
                      if (widget.id != -1) {
                        await _updateItem(widget.id);
                      }

                      // clear text fields
                      _titleController.text = '';
                      _authorController.text = '';
                      _datePurchaseController.text = '';
                      _dateReadDoneController.text = '';
                      _isForgotDateDone = false;

                      // close bottom sheet
                      // Navigator.of(context).pop();
                      Navigator.pop(context, true);
                    }, 
                    child: Text(widget.id == -1 ? 'Add New Book' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        
      // ),
    );
  }
  
  // insert new book to db
  Future<void> _addItem() async {
    await SQLHelper.inputBook(_titleController.text, _authorController.text, _bookStatus.toString(), _datePurchaseController.text, _dateReadDoneController.text);
  }

  // update existing book
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateBook(id, _titleController.text, _authorController.text, _bookStatus.toString(), _datePurchaseController.text, _dateReadDoneController.text);
  }

}
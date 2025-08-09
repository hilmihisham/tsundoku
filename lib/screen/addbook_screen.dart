import 'dart:async';

import 'package:books_finder/books_finder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:tsundoku/util/sql_helper.dart';

class AddBookScreen extends StatefulWidget {
  /// [id] value is required. If creating a new book entry, pass in the value as -1.
  ///
  /// [book] value is required. As of current, [book] object is of type Map<String, dynamic>.
  ///
  /// On popping the screen from the navigator, return true to indicate there's an entry being inserted/updated.
  const AddBookScreen({Key? key, required this.id, required this.book})
      : super(key: key);

  final int id;
  final Map<String, dynamic>? book;

  @override
  State<AddBookScreen> createState() => _AddBookScreen();
}

class _AddBookScreen extends State<AddBookScreen> {
  // logger
  final logger = Logger();

  bool _isForgotDateDone = false;
  bool _isDoneGetDataFromHomeScreen = false;
  bool _validateEmptyTitle = false;
  bool _validateEmptyAuthor = false;
  // bool _validateEmptyPublisher = false;

  int _bookStatus = 0;

  // int? bookId;
  late Map<String, dynamic> existingBook;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _datePurchaseController = TextEditingController();
  final TextEditingController _dateReadDoneController = TextEditingController();
  final TextEditingController _isbn13Controller = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _bookSeriesController = TextEditingController();
  final TextEditingController _bookVolumeController = TextEditingController();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _authorFocus = FocusNode();
  final FocusNode _publisherFocus = FocusNode();
  final FocusNode _bookSeriesFocus = FocusNode();
  final FocusNode _bookVolumeFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _datePurchaseController.dispose();
    _dateReadDoneController.dispose();
    _isbn13Controller.dispose();
    _publisherController.dispose();

    _titleFocus.dispose();
    _authorFocus.dispose();
    _publisherFocus.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  /// create forgot button for finished reading date
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
        // WidgetsBinding.instance.handlePointerEvent(PointerDownEvent(
        //   position: Offset((MediaQuery.of(context).size.width) / 2,
        //       (MediaQuery.of(context).size.height) - 20),
        // ));
        // Timer(const Duration(milliseconds: 2), () {
        //   setState(() {
        //     WidgetsBinding.instance.handlePointerEvent(PointerUpEvent(
        //       position: Offset((MediaQuery.of(context).size.width) / 2,
        //           (MediaQuery.of(context).size.height) - 20),
        //     ));
        //   });
        // });

        logger.i('i forgot lol = $_isForgotDateDone');
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 5,
        ),
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

  /// creating a custom button for book status options
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
        // WidgetsBinding.instance.handlePointerEvent(PointerDownEvent(
        //   position: Offset((MediaQuery.of(context).size.width) / 2,
        //       (MediaQuery.of(context).size.height) - 20),
        // ));
        // Timer(const Duration(milliseconds: 2), () {
        //   setState(() {
        //     WidgetsBinding.instance.handlePointerEvent(PointerUpEvent(
        //       position: Offset((MediaQuery.of(context).size.width) / 2,
        //           (MediaQuery.of(context).size.height) - 20),
        //     ));
        //   });
        // });

        if (value == 2 &&
            _isForgotDateDone == false &&
            "" == _dateReadDoneController.text) {
          // add default today's date to "date reading done" field
          _dateReadDoneController.text =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          logger.d(
              "customBookStatusButton(if status == 2) dateReadDoneController value = ${_dateReadDoneController.value.text}");
        }

        setState(() {});
        // else {
        //   // erase "date reading done" field
        //   _dateReadDoneController.clear();
        //   logger.d(
        //       "customBookStatusButton(else status != 2) dateReadDoneController value = ${_dateReadDoneController.value.text}");
        // }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 5,
        ),
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

  /// popup alert to confirm whether search result is correct
  Widget alertForSearchConfirm(String title, String authors, String publisher) {
    return AlertDialog(
      title: const Text('Is this the correct book?'),
      icon: const Icon(Icons.search_sharp),
      content:
          Text('Title: $title; Author(s): $authors; Publisher: $publisher'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'No'),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'Yes'),
          child: const Text('Yes'),
        ),
      ],
    );
  }

  /// function triggered when tapping clear button in textfield
  void _clearTextField(TextEditingController textController) {
    // clear everything
    textController.clear();
    // update ui
    setState(() {});
  }

  /// call barcode scanner
  Future<void> barcodeScan() async {
    String barcodeScanResult = '-1';

    try {
      barcodeScanResult = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.BARCODE);
      logger.i('Scanned barcode = $barcodeScanResult');
    } on PlatformException {
      // Platform messages may fail, so we use a try/catch PlatformException.
      logger.e('Barcode scanner error on PlatformExeption');
    } catch (e, stack) {
      logger.e('Barcode scanner error',
          time: DateTime.now(), error: e, stackTrace: stack);
    }

    if (!mounted) return;

    setState(() {
      if (barcodeScanResult.compareTo('-1') != 0) {
        _isbn13Controller.text = barcodeScanResult;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    logger.d(
        'AddBookScreen building, id = ${widget.id}, _isDoneGetDataFromHomeScreen = $_isDoneGetDataFromHomeScreen');

    // if we editing the existing book (id != -1), fill in the text controller
    if (widget.id != -1 && _isDoneGetDataFromHomeScreen == false) {
      existingBook = widget.book!;
      logger.i('existing book data = $existingBook');

      if (existingBook['isbn'] != null)
        _isbn13Controller.text = existingBook['isbn'];
      _titleController.text = existingBook['title'];
      _authorController.text = existingBook['author'];
      _bookStatus = int.parse(existingBook['status']);
      _datePurchaseController.text = existingBook['datePurchase'];
      (existingBook['dateFinished'] == null)
          ? _dateReadDoneController.text = ''
          : _dateReadDoneController.text = existingBook['dateFinished'];
      if (existingBook['publisher'] != null)
        _publisherController.text = existingBook['publisher'];

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
        controller: _scrollController,
        child: Container(
          padding: const EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            bottom: 60, // preventing snackbar from covering add/update button
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
                padding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 10.0),
                child: TextField(
                  controller: _isbn13Controller,
                  decoration: InputDecoration(
                    labelText: 'ISBN-13 Number',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_sharp),
                      onPressed: () => barcodeScan(),
                      // onPressed: () async {
                      //   String barcodeScanResult = await FlutterBarcodeScanner.scanBarcode("#ff6666", "Cancel", true, ScanMode.BARCODE);
                      //   logger.i('barcode scanned: $barcodeScanResult');
                      // },
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                child: ElevatedButton(
                  child: const Text('Find Book'),
                  onPressed: () async {
                    logger.i('_isbnController = ${_isbn13Controller.value}');

                    if (_isbn13Controller.text.isEmpty) {
                      // no input, no do search
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No ISBN number entered.'),
                          duration: Duration(seconds: 4),
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
                    } else {
                      final List<Book> bookSearch = await queryBooks(
                        _isbn13Controller.text,
                        queryType: QueryType.isbn,
                        maxResults: 1,
                        printType: PrintType.books,
                        orderBy: OrderBy.relevance,
                      );
                      // for (Book bookResult in bookSearch) {
                      //   logger.d(
                      //     'title: ${bookResult.info.title}, subtitle: ${bookResult.info.subtitle}, author: ${bookResult.info.authors}\n'
                      //     'publisher: ${bookResult.info.publisher}, description: ${bookResult.info.description}'
                      //   );
                      // }

                      // popup to confirm search result is correct
                      if (bookSearch.isEmpty) {
                        // no search result found, show snack bar to notify
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('No books found with that ISBN number.'),
                              duration: Duration(seconds: 4),
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
                      } else {
                        var searchResultConfirm = 'No';

                        Book bookResult = bookSearch.first;

                        String fullTitle = bookResult.info.title;
                        if (bookResult.info.subtitle.isNotEmpty)
                          fullTitle = '$fullTitle: ${bookResult.info.subtitle}';

                        String allAuthors = bookResult.info.authors
                            .toString()
                            .substring(1,
                                bookResult.info.authors.toString().length - 1);

                        // search found a result, confirm result is correct
                        if (mounted) {
                          searchResultConfirm = await Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (context) => alertForSearchConfirm(
                                fullTitle,
                                allAuthors,
                                bookResult.info.publisher),
                          ));
                        }

                        if (searchResultConfirm.compareTo('No') == 0 &&
                            mounted) {
                          // search result is wrong
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Too bad, search result is not the book that we looking for.'),
                              duration: Duration(seconds: 4),
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
                        } else {
                          setState(() {
                            _titleController.text = fullTitle;
                            _authorController.text = allAuthors;
                            _publisherController.text =
                                bookResult.info.publisher;
                          });
                        }
                      }
                    }
                  },
                ),
              ),
              const Divider(
                thickness: 2.5,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _titleController,
                  onChanged: (value) {
                    // update ui
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: const OutlineInputBorder(),
                    suffixIcon: _titleController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_sharp),
                            onPressed: () => _clearTextField(_titleController),
                          ),
                    errorText: _validateEmptyTitle
                        ? "c'mon, there's no books with no title, innit?"
                        : null,
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  focusNode: _titleFocus,
                  onEditingComplete: () {
                    // had to do this coz there's a clear button in between TextField for textInputAction to work properly
                    logger.d('onEditingComplete title');
                    // unfocus this title field
                    _titleFocus.unfocus();
                    // request to move the focus to author field
                    FocusScope.of(context).requestFocus(_authorFocus);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _authorController,
                  onChanged: (value) {
                    // update ui
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Author',
                    border: const OutlineInputBorder(),
                    suffixIcon: _authorController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_sharp),
                            onPressed: () => _clearTextField(_authorController),
                          ),
                    errorText: _validateEmptyAuthor
                        ? "who's the writer? ghost ah?"
                        : null,
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  focusNode: _authorFocus,
                  onEditingComplete: () {
                    // had to do this coz there's a clear button in between TextField for textInputAction to work properly
                    logger.d('onEditingComplete author');
                    // unfocus this author field
                    _authorFocus.unfocus();
                    // request to move the focus to publisher field
                    FocusScope.of(context).requestFocus(_publisherFocus);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _publisherController,
                  onChanged: (value) {
                    // update ui
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Publisher',
                    border: const OutlineInputBorder(),
                    suffixIcon: _publisherController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_sharp),
                            onPressed: () =>
                                _clearTextField(_publisherController),
                          ),
                    // errorText: _validateEmptyPublisher ? "ey, if no publisher then how u get this book?" : null,
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  focusNode: _publisherFocus,
                ),
              ),
              const Divider(
                thickness: 1.0,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _bookSeriesController,
                  onChanged: (value) {
                    // update ui
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Book Series',
                    border: const OutlineInputBorder(),
                    suffixIcon: _bookSeriesController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_sharp),
                            onPressed: () =>
                                _clearTextField(_bookSeriesController),
                          ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  focusNode: _bookSeriesFocus,
                  onTap: () {
                    _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut);

                    logger.d("onTap bookSeries TextField");
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _bookVolumeController,
                  onChanged: (value) {
                    // update ui
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Volume/Issue #',
                    border: const OutlineInputBorder(),
                    suffixIcon: _bookVolumeController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_sharp),
                            onPressed: () =>
                                _clearTextField(_bookVolumeController),
                          ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  focusNode: _bookVolumeFocus,
                  onTap: () {
                    logger.d("Vol/Issue # tapped");
                  },
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
                      child:
                          customBookStatusButton('Finished', 2, Colors.green),
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
                      initialDate: (_datePurchaseController.text != '')
                          ? DateTime.parse(_datePurchaseController.text)
                          : DateTime.now(),
                      firstDate: DateTime(1970),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      logger.i(pickedDate.toString());
                      String formattedDate = DateFormat('yyyy-MM-dd').format(
                          pickedDate); // format date in required form here we use yyyy-MM-dd that means time is removed
                      logger.d(
                          formattedDate); //formatted date output using intl.dart package =>  2022-07-04

                      setState(() {
                        _datePurchaseController.text = formattedDate;
                      });
                    } else {
                      logger.d('Date not selected');
                    }
                  },
                ),
              ),
              (_bookStatus ==
                      2) // show date reading done picker if book status = finished
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
                            initialDate: (_dateReadDoneController.text != '')
                                ? DateTime.parse(_dateReadDoneController.text)
                                : DateTime.now(),
                            firstDate: (_datePurchaseController.text != '')
                                ? DateTime.parse(_datePurchaseController.text)
                                : DateTime(1970),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDateDone != null) {
                            logger.i(pickedDateDone.toString());
                            String formattedDateDone = DateFormat('yyyy-MM-dd')
                                .format(
                                    pickedDateDone); // format date in required form here we use yyyy-MM-dd that means time is removed
                            logger.d(
                                formattedDateDone); //formatted date output using intl.dart package =>  2022-07-04

                            setState(() {
                              _dateReadDoneController.text = formattedDateDone;
                            });
                          } else {
                            logger.d('Date not selected');
                          }
                        },
                      ),
                    )
                  : const SizedBox(
                      height: 0,
                    ),
              (_bookStatus ==
                      2) // show forgot date reading done button if book status = finished
                  ? Padding(
                      padding:
                          const EdgeInsets.fromLTRB(50.0, 10.0, 10.0, 10.0),
                      child: customForgotFinishedReadDateButton(),
                    )
                  : const SizedBox(
                      height: 0,
                    ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // for title entry validation
                    setState(() {
                      _validateEmptyTitle = _titleController.text.isEmpty;
                      _validateEmptyAuthor = _authorController.text.isEmpty;
                      // _validateEmptyPublisher = _publisherController.text.isEmpty;
                    });

                    // proceed only if all required field is not empty (_validateEmptyTitle & _validateEmptyAuthor = false)
                    if (!_validateEmptyTitle && !_validateEmptyAuthor) {
                      // if i forgot date finish is selected
                      if (_isForgotDateDone) {
                        _dateReadDoneController.text = '';
                      } else if ((_bookStatus == 2) &&
                          (_dateReadDoneController.text == '')) {
                        // if book finished is selected, but date finished is not inputted, auto select today's date
                        _dateReadDoneController.text =
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                        logger.d(
                            'date finished auto set to ${_dateReadDoneController.text}');
                      }

                      // save new book
                      if (widget.id == -1) {
                        await _addItem();
                      }
                      if (widget.id != -1) {
                        await _updateItem(widget.id);
                      }

                      // clear text fields (relics from having this screen as bottom sheet)
                      // _isbn13Controller.text = '';
                      // _titleController.text = '';
                      // _authorController.text = '';
                      // _datePurchaseController.text = '';
                      // _dateReadDoneController.text = '';
                      // _isForgotDateDone = false;

                      if (mounted) {
                        // give update to user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: (widget.id == -1)
                                ? Text(
                                    "New book '${_titleController.text}' added.")
                                : Text(
                                    "Book '${_titleController.text}' is updated."),
                            duration: const Duration(seconds: 4),
                            showCloseIcon: true,
                            closeIconColor: Colors.deepOrange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        // close add book screen, and send true to notify home screen that a book has been added/updated to refresh the book list there
                        Navigator.pop(context, true);
                      }
                    }
                  },
                  child: Text(widget.id == -1 ? 'Add New Book' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// insert new book to db
  Future<void> _addItem() async {
    await SQLHelper.inputBook(
        _titleController.text,
        _authorController.text,
        _bookStatus.toString(),
        _datePurchaseController.text,
        _dateReadDoneController.text,
        _isbn13Controller.text,
        _publisherController.text);
  }

  /// update existing book
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateBook(
        id,
        _titleController.text,
        _authorController.text,
        _bookStatus.toString(),
        _datePurchaseController.text,
        _dateReadDoneController.text,
        _isbn13Controller.text,
        _publisherController.text);
  }
}

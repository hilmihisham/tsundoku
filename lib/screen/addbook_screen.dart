import 'dart:async';
import 'dart:convert';

import 'package:books_finder/books_finder.dart' as books_finder;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsundoku/util/book.dart';
import 'package:tsundoku/util/sql_helper.dart';

import 'barcode_scanner_view.dart';

String resolveReadCompletionDate({
  required String purchaseDate,
  String? completionDate,
  DateTime? currentTime,
}) {
  final now = currentTime ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if ((completionDate ?? '').trim().isNotEmpty) {
    return completionDate!.trim();
  }

  final purchaseValue = purchaseDate.trim();
  if (purchaseValue.isEmpty) {
    return DateFormat('yyyy-MM-dd').format(today);
  }

  final parsedPurchase = DateTime.tryParse(purchaseValue);
  if (parsedPurchase == null) {
    return DateFormat('yyyy-MM-dd').format(today);
  }

  final purchaseDay = DateTime(
    parsedPurchase.year,
    parsedPurchase.month,
    parsedPurchase.day,
  );

  final effectiveDate = purchaseDay.isAfter(today) ? purchaseDay : today;
  return DateFormat('yyyy-MM-dd').format(effectiveDate);
}

class AddBookScreen extends StatefulWidget {
  /// [id] value is required. If creating a new book entry, pass in the value as -1.
  ///
  /// [book] value is required. If creating a new book entry, pass in the value as null.
  ///
  /// On popping the screen from the navigator, return true to indicate there's an entry being inserted/updated.
  const AddBookScreen({super.key, required this.id, required this.book});

  final int id;
  final Book? book;

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

  int _bookStatus = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _datePurchaseController = TextEditingController();
  final TextEditingController _dateReadDoneController = TextEditingController();
  final TextEditingController _isbn13Controller = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _authorFocus = FocusNode();
  final FocusNode _publisherFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    if (widget.id == -1) {
      _datePurchaseController.text = _formatDateYmd(DateTime.now());
    }
  }

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
        WidgetsBinding.instance.handlePointerEvent(PointerDownEvent(
          position: Offset((MediaQuery.of(context).size.width) / 2,
              (MediaQuery.of(context).size.height) - 20),
        ));
        Timer(const Duration(milliseconds: 2), () {
          setState(() {
            WidgetsBinding.instance.handlePointerEvent(PointerUpEvent(
              position: Offset((MediaQuery.of(context).size.width) / 2,
                  (MediaQuery.of(context).size.height) - 20),
            ));
          });
        });

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
        _bookStatus = value;

        if (_bookStatus == 2 && _dateReadDoneController.text.isEmpty) {
          _dateReadDoneController.text = resolveReadCompletionDate(
            purchaseDate: _datePurchaseController.text,
            completionDate: _dateReadDoneController.text,
          );
        }

        // a hack style of getting the button to update its color itself
        // problem: i noticed the color only changed after tapping somewhere else after button was pressed
        // solution: simulate that tapping somewhere else by code (pointer down, wait 2ms, pointer up)
        WidgetsBinding.instance.handlePointerEvent(PointerDownEvent(
          position: Offset((MediaQuery.of(context).size.width) / 2,
              (MediaQuery.of(context).size.height) - 20),
        ));
        Timer(const Duration(milliseconds: 2), () {
          setState(() {
            WidgetsBinding.instance.handlePointerEvent(PointerUpEvent(
              position: Offset((MediaQuery.of(context).size.width) / 2,
                  (MediaQuery.of(context).size.height) - 20),
            ));
          });
        });
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

  void _showSnackBar(String message,
      {Duration duration = const Duration(seconds: 4)}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        showCloseIcon: true,
        closeIconColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateYmd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// call barcode scanner
  Future<void> barcodeScan() async {
    String? barcodeScanResult;

    try {
      barcodeScanResult = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => BarcodeScannerView(
            onScan: (value) => Navigator.of(context).pop(value),
          ),
        ),
      );
      logger.i('Scanned barcode = $barcodeScanResult');
    } catch (e, stack) {
      logger.e('Barcode scanner error',
          time: DateTime.now(), error: e, stackTrace: stack);
    }

    if (!mounted || barcodeScanResult == null || barcodeScanResult.isEmpty)
      return;

    setState(() {
      _isbn13Controller.text = barcodeScanResult!;
    });
  }

  @override
  Widget build(BuildContext context) {
    logger.d(
        'AddBookScreen building, id = ${widget.id}, _isDoneGetDataFromHomeScreen = $_isDoneGetDataFromHomeScreen');

    final bookToEdit = widget.book;

    // if we editing the existing book (id != -1), fill in the text controller
    if (widget.id != -1 && _isDoneGetDataFromHomeScreen == false) {
      // guard against null bookToEdit, which should not happen, but just in case
      if (bookToEdit == null) {
        logger.e('Unexpected Error: bookToEdit is null for id = ${widget.id}');
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
          body: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: Text(
                'Unexpected Error: Book data not found. Please go back and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      } else {
        logger.i('existing book data = ${bookToEdit.toDebugString()}');

        // fill in the text controller with existing book data
        if (bookToEdit.isbn != null) _isbn13Controller.text = bookToEdit.isbn!;
        _titleController.text = bookToEdit.title;
        _authorController.text = bookToEdit.author ?? '';
        _bookStatus = int.parse(bookToEdit.status);
        _datePurchaseController.text = bookToEdit.datePurchase ?? '';
        (bookToEdit.dateFinished == null)
            ? _dateReadDoneController.text = ''
            : _dateReadDoneController.text = bookToEdit.dateFinished ?? '';
        if (bookToEdit.publisher != null)
          _publisherController.text = bookToEdit.publisher ?? '';

        _isForgotDateDone = false;

        // flip the flag so that we won't refresh all above when screen rebuild mid-edit
        _isDoneGetDataFromHomeScreen = true;
      }
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
            bottom: 60, // preventing snackbar from covering add/update button
            // bottom: MediaQuery.of(context).viewInsets.bottom + 20, // preventing soft keyboard from covering text fields
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildIsbnInputField(),
              _buildFindBookButton(),
              const Divider(
                thickness: 2.5,
              ),
              _buildTitleField(),
              _buildAuthorField(),
              _buildPublisherField(),
              _buildStatusButtonsRow(),
              _buildPurchaseDateField(),
              _buildFinishedDateFieldOrPlaceholder(),
              _buildForgotDateButtonOrPlaceholder(),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // header typography
    return const Padding(
      padding: EdgeInsets.only(top: 30.0, bottom: 20.0),
      child: Text(
        "Add new book \ninto library.",
        style: TextStyle(
          fontSize: 30.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildIsbnInputField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 10.0),
      child: TextField(
        controller: _isbn13Controller,
        decoration: InputDecoration(
          labelText: 'ISBN-13 Number',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_sharp),
            onPressed: () => barcodeScan(),
          ),
        ),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildFindBookButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
      child: ElevatedButton(
        child: const Text('Find Book'),
        onPressed: () async {
          logger.i('_isbnController = ${_isbn13Controller.value}');

          if (_isbn13Controller.text.isEmpty) {
            // no input, no do search
            _showSnackBar('No ISBN number entered.');
          } else {
            try {
              final prefs = await SharedPreferences.getInstance();
              final savedApiKey =
                  prefs.getString('google_books_api_key')?.trim() ?? '';

              final List<books_finder.Book> bookSearch = savedApiKey.isEmpty
                  ? await books_finder.queryBooks(
                      _isbn13Controller.text,
                      queryType: books_finder.QueryType.isbn,
                      maxResults: 1,
                      printType: books_finder.PrintType.books,
                      orderBy: books_finder.OrderBy.relevance,
                    )
                  : await books_finder.queryBooks(
                      _isbn13Controller.text,
                      queryType: books_finder.QueryType.isbn,
                      maxResults: 1,
                      printType: books_finder.PrintType.books,
                      orderBy: books_finder.OrderBy.relevance,
                      apiKey: savedApiKey,
                    );
              // popup to confirm search result is correct
              if (bookSearch.isEmpty) {
                // no search result found, show snack bar to notify
                if (mounted) {
                  _showSnackBar('No books found with that ISBN number.');
                }
              } else {
                var searchResultConfirm = 'No';

                books_finder.Book bookResult = bookSearch.first;

                String fullTitle = bookResult.info.title;
                if (bookResult.info.subtitle.isNotEmpty) {
                  fullTitle = '$fullTitle: ${bookResult.info.subtitle}';
                }

                String allAuthors = bookResult.info.authors
                    .toString()
                    .substring(
                        1, bookResult.info.authors.toString().length - 1);

                // search found a result, confirm result is correct
                if (mounted) {
                  searchResultConfirm = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => alertForSearchConfirm(
                          fullTitle, allAuthors, bookResult.info.publisher),
                    ),
                  );
                }

                if (searchResultConfirm == 'No' && mounted) {
                  // search result is wrong
                  _showSnackBar(
                      'Too bad, search result is not the book that we looking for.');
                } else {
                  setState(() {
                    _titleController.text = fullTitle;
                    _authorController.text = allAuthors;
                    _publisherController.text = bookResult.info.publisher;
                  });
                }
              }
            } catch (e, stack) {
              logger.e('Error searching book by ISBN',
                  time: DateTime.now(), error: e, stackTrace: stack);

              String errorMessageText;
              String errorText = e.toString();
              final bool isHostLookupError =
                  errorText.contains('Failed host lookup');

              if (isHostLookupError) {
                errorMessageText =
                    'Error searching book by ISBN. Please check your internet connection.';
              } else {
                // try to parse the error message from server response
                String? serverMessage;

                try {
                  final Map<String, dynamic> parsedError =
                      jsonDecode(errorText) as Map<String, dynamic>;
                  serverMessage = parsedError['error']?['message']?.toString();
                } catch (_) {
                  serverMessage = null;
                }

                errorMessageText =
                    (serverMessage != null && serverMessage.isNotEmpty)
                        ? 'Error searching book by ISBN.\n\n$serverMessage'
                        : 'Error searching book by ISBN.';
              }

              _showSnackBar(errorMessageText,
                  duration: const Duration(seconds: 6));
            }
          }
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Padding(
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
    );
  }

  Widget _buildAuthorField() {
    return Padding(
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
          errorText:
              _validateEmptyAuthor ? "who's the writer? ghost ah?" : null,
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
    );
  }

  Widget _buildPublisherField() {
    return Padding(
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
                  onPressed: () => _clearTextField(_publisherController),
                ),
        ),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        focusNode: _publisherFocus,
      ),
    );
  }

  Widget _buildStatusButtonsRow() {
    return Padding(
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
    );
  }

  Widget _buildPurchaseDateField() {
    final hasPurchaseDate = _datePurchaseController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: _datePurchaseController,
        decoration: InputDecoration(
          icon: const Icon(Icons.calendar_today),
          labelText: "Date of Purchase",
          border: const OutlineInputBorder(),
          suffixIcon: hasPurchaseDate
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear purchase date',
                  onPressed: () {
                    setState(() {
                      _datePurchaseController.clear();
                    });
                  },
                )
              : null,
        ),
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: _datePurchaseController.text.isNotEmpty
                ? DateTime.parse(_datePurchaseController.text)
                : DateTime.now(),
            firstDate: DateTime(1970),
            lastDate: DateTime(2100),
          );

          if (pickedDate != null) {
            logger.i(pickedDate.toString());
            String formattedDate = _formatDateYmd(
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
    );
  }

  Widget _buildFinishedDateFieldOrPlaceholder() {
    if (_bookStatus == 2) {
      final hasFinishedDate = _dateReadDoneController.text.isNotEmpty;

      // show date reading done picker if book status = finished
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: TextField(
          controller: _dateReadDoneController,
          decoration: InputDecoration(
            icon: const Icon(Icons.done_all_sharp),
            labelText: "Date Reading Done!",
            border: const OutlineInputBorder(),
            suffixIcon: hasFinishedDate
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear finished date',
                    onPressed: () {
                      setState(() {
                        _dateReadDoneController.clear();
                      });
                    },
                  )
                : null,
          ),
          readOnly: true,
          onTap: () async {
            DateTime? pickedDateDone = await showDatePicker(
              context: context,
              initialDate: _dateReadDoneController.text.isNotEmpty
                  ? DateTime.parse(_dateReadDoneController.text)
                  : DateTime.now(),
              firstDate: _datePurchaseController.text.isNotEmpty
                  ? DateTime.parse(_datePurchaseController.text)
                  : DateTime(1970),
              lastDate: DateTime(2100),
            );

            if (pickedDateDone != null) {
              logger.i(pickedDateDone.toString());
              String formattedDateDone = _formatDateYmd(
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
      );
    }

    return const SizedBox(
      height: 0,
    );
  }

  Widget _buildForgotDateButtonOrPlaceholder() {
    if (_bookStatus == 2) {
      // show forgot date reading done button if book status = finished
      return Padding(
        padding: const EdgeInsets.fromLTRB(50.0, 10.0, 10.0, 10.0),
        child: customForgotFinishedReadDateButton(),
      );
    }

    return const SizedBox(
      height: 0,
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () async {
          // for title entry validation
          setState(() {
            _validateEmptyTitle = _titleController.text.isEmpty;
            _validateEmptyAuthor = _authorController.text.isEmpty;
          });

          // proceed only if all required field is not empty (_validateEmptyTitle & _validateEmptyAuthor = false)
          if (!_validateEmptyTitle && !_validateEmptyAuthor) {
            // if i forgot date finish is selected
            if (_isForgotDateDone) {
              _dateReadDoneController.text = '';
            } else if ((_bookStatus == 2) &&
                _dateReadDoneController.text.isEmpty) {
              // if book finished is selected, but date finished is not inputted, resolve using central date policy
              _dateReadDoneController.text = resolveReadCompletionDate(
                purchaseDate: _datePurchaseController.text,
                completionDate: _dateReadDoneController.text,
              );
              logger.d(
                  'date finished auto set to ${_dateReadDoneController.text}');
            }

            // save new book
            if (widget.id == -1) {
              await _addItem();
            }
            if (widget.id != -1) {
              await _updateItem(widget.id, widget.book!);
            }

            if (mounted) {
              // give update to user
              _showSnackBar((widget.id == -1)
                  ? "New book '${_titleController.text}' added."
                  : "Book '${_titleController.text}' is updated.");

              // close add book screen, and send true to notify home screen that a book has been added/updated to refresh the book list there
              Navigator.pop(context, true);
            }
          }
        },
        child: Text(widget.id == -1 ? 'Add New Book' : 'Update'),
      ),
    );
  }

  /// insert new book to db
  Future<void> _addItem() async {
    final newBook = Book(
      title: _titleController.text,
      author: _authorController.text,
      status: _bookStatus.toString(),
      datePurchase: _datePurchaseController.text,
      dateFinished: _dateReadDoneController.text,
      isbn: _isbn13Controller.text,
      publisher: _publisherController.text,
    );

    await SQLHelper.inputBook(newBook);
  }

  /// update existing book
  Future<void> _updateItem(int bookId, Book book) async {
    final updatedBook = Book(
      id: bookId,
      title: _titleController.text,
      author: _authorController.text,
      status: _bookStatus.toString(),
      datePurchase: _datePurchaseController.text,
      dateFinished: _dateReadDoneController.text,
      isbn: _isbn13Controller.text,
      publisher: _publisherController.text,
      dateCreated: book.dateCreated, // keep the original dateCreated value
    );

    await SQLHelper.updateBook(updatedBook);
  }
}

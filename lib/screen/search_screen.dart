import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:tsundoku/util/sql_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // logger
  final logger = Logger();

  bool _isLoading = true; // bool for checking loading book list
  bool _validateEmptySearch = false; // set to false when search field is empty

  // all books
  List<Map<String, dynamic>> _books = [];

  final TextEditingController _searchTextController = TextEditingController();

  /// function triggered when tapping clear button in textfield
  void _clearTextField(TextEditingController textController) {
    // clear everything
    textController.clear();
    // update ui
    setState(() {});
  }

  // fetch all data from db
  void _searchBooks(String title) async {
    _books = await SQLHelper.getBooksByTitleSearch(title);
    setState(() {
      _isLoading = false;
    });
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
  void initState() {
    super.initState();
    setState(() {
      logger.i('initState SearchScreen');
      _books.clear();
      _searchTextController.clear();
      _validateEmptySearch = false;
      _isLoading = true;
    });
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('SearchScreen building');

    return Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.arrow_forward_ios_sharp),
          title: const Text('tsundoku'),
        ),
        body: Column(
          children: <Widget>[
            // top part
            Container(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header typography
                  const Padding(
                    padding: EdgeInsets.only(top: 30.0, left: 15.0),
                    child: Text(
                      "Search book.",
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 10.0),
                    child: TextField(
                      controller: _searchTextController,
                      onChanged: (value) {
                        //update ui
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'Search title',
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchTextController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear_sharp),
                                onPressed: () =>
                                    _clearTextField(_searchTextController),
                              ),
                        errorText: _validateEmptySearch
                            ? "can't search nothing, bro"
                            : null,
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 10.0),
                    child: ElevatedButton(
                      child: const Text('Find Book'),
                      onPressed: () async {
                        logger.i(
                            'Find Book pressed; \n_isLoading before = $_isLoading \nTitle = ${_searchTextController.value.text}');

                        String sanitizeSearch =
                            _searchTextController.text.trimLeft();

                        // validate search title
                        setState(() {
                          _validateEmptySearch = sanitizeSearch.isEmpty;
                        });

                        // process only if search field is not empty
                        if (!_validateEmptySearch) {
                          _searchTextController.text = sanitizeSearch;
                          _searchBooks(sanitizeSearch);
                        }
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 15.0, right: 15.0),
                    child: Divider(
                      thickness: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            // bottom part
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Icon(Icons.search_sharp),
                    )
                  // : const Center(
                  //     child: Icon(Icons.thumb_up),
                  //   )
                  : ListView.builder(
                      itemCount: _books.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _books.length) {
                          // create card for the last entry
                          return Card(
                            color: const Color.fromRGBO(255, 238, 173, 1.0),
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 15.0,
                              ),
                              title: Text(
                                'Total books found: ${_books.length}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        } else {
                          // all the other Card for found books
                          return Card(
                            color: bookListColor(_books[index]['status']),
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 15.0,
                              ),
                              title: Text(_books[index]['title']),
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
                                    )),
                                    TextSpan(
                                        text: ' ${_books[index]['author']}\n'),
                                  ],
                                ),
                              ),
                              onTap: () {
                                logger.i(
                                    'tapped: ${_books[index]['title']}, index = $index');
                              },
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        ));
  }
}

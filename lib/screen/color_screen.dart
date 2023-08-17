// import 'package:books_finder/books_finder.dart';
import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';

class ColorScreen extends StatelessWidget {
  const ColorScreen({Key? key}) : super(key: key);
  // final logger = Logger();

  @override
  Widget build(BuildContext context) {
    // final TextEditingController _isbnController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(
        //     Icons.arrow_back_sharp,
        //   ),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: const Text('tsundoku'),
      ),
      body: Container(
        color: Colors.lightBlue.shade900,
        child: const Center(
          child: Text(
            'coming soon...',
            style: TextStyle(color: Colors.white, fontSize: 22.0),
          ),
        ),
      ),

      // experiment starts
      // body: SingleChildScrollView(
      //   child: Container(
      //     padding: const EdgeInsets.only(
      //       top: 15,
      //       left: 15,
      //       right: 15,
      //       bottom: 15,
      //     ),
      //     child: Column(
      //       mainAxisSize: MainAxisSize.min,
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         Padding(
      //           padding: const EdgeInsets.all(10.0),
      //           child: TextField(
      //             controller: _isbnController,
      //             decoration: const InputDecoration(
      //               labelText: 'ISBN-13 Number',
      //               border: OutlineInputBorder(),
      //             ),
      //             // textCapitalization: TextCapitalization.words,
      //             keyboardType: TextInputType.number,
      //             textInputAction: TextInputAction.next,
      //           ),
      //         ),
      //         Padding(
      //           padding: const EdgeInsets.all(10.0),
      //           child: ElevatedButton(
      //             child: const Text('Find Book'),
      //             onPressed: () async {
      //               logger.i('_isbnController = ${_isbnController.value}');

      //               final List<Book> books = await queryBooks(
      //                 _isbnController.text,
      //                 queryType: QueryType.isbn,
      //                 maxResults: 1,
      //                 printType: PrintType.books,
      //                 orderBy: OrderBy.relevance,
      //               );
      //               for (Book book in books) {
      //                 logger.d(
      //                   'title: ${book.info.title}, subtitle: ${book.info.subtitle}, author: ${book.info.authors}\n' 
      //                   'publisher: ${book.info.publisher}, description: ${book.info.description}'
      //                 );
      //               }},
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

}
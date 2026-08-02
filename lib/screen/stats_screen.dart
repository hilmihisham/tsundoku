import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:tsundoku/util/book.dart';
import 'package:tsundoku/util/sql_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {

  // logger
  final logger = Logger(); 

  // stats variables
  int _countBooksNew = 0;
  int _countBooksReading = 0;
  int _countBooksFinished = 0;
  int longestDurationDays = 0;
  int shortestDurationDays = 0;
  int longestDurationNewDays = 0;
  int longestNowReadingDays = 0;
  int latestBoughtDays = 0;
  int latestFinishedDays = 0;

  Book? longestDurationBook;
  Book? shortestDurationBook;
  Book? longestDurationNewBook;
  Book? longestNowReadingBook;
  Book? latestBoughtBook;
  Book? latestFinishedBook;

  @override
  void initState() {
    super.initState();
    _getAllStats();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _getAllStats() async {
    // --------------- (0) simplest stats, book count [start] ---------------
    final countNewBooks = await SQLHelper.getCountByStatus("0");
    _countBooksNew = countNewBooks ?? 0;

    final countReadingBooks = await SQLHelper.getCountByStatus("1");
    _countBooksReading = countReadingBooks ?? 0;

    final countFinishedBooks = await SQLHelper.getCountByStatus("2");
    _countBooksFinished = countFinishedBooks ?? 0;

    logger.i("new = $_countBooksNew, reading = $_countBooksReading, finished = $_countBooksFinished");
    // ---------------- (0) simplest stats, book count [end] ----------------

    // --------------- (0.1) latest book bought and finished [start] ---------------
    final dataLatestBoughtAndFinished = await SQLHelper.getLatestBooksInEachStatus();
    logger.i('0.1\n\n$dataLatestBoughtAndFinished');

    if (dataLatestBoughtAndFinished.isNotEmpty) {
      for (final element in dataLatestBoughtAndFinished) {
        if (element.isNew) {
          latestBoughtBook = element;
          if (element.datePurchase != null && element.datePurchase!.isNotEmpty) {
            latestBoughtDays = daysBetween(DateTime.parse(element.datePurchase!), DateTime.now());
          }
          logger.d('latest bought book = $latestBoughtBook');
        }

        if (element.isFinished) {
          latestFinishedBook = element;
          if (element.dateFinished != null && element.dateFinished!.isNotEmpty) {
            latestFinishedDays = daysBetween(DateTime.parse(element.dateFinished!), DateTime.now());
          }
          logger.d('latest finished book = $latestFinishedBook');
        }
      }

      latestBoughtBook ??= Book(
        title: 'Nope, no new book in collection',
        author: 'no one',
        status: '0',
        datePurchase: 'non-existent date',
        isbn: '-1',
      );
      latestFinishedBook ??= Book(
        title: 'Nope, nothing is finished yet',
        author: 'no one',
        status: '2',
        dateFinished: 'non-existent date',
        isbn: '-1',
      );
    } else {
      latestBoughtBook = Book(
        title: 'Nope, no new book in collection',
        author: 'no one',
        status: '0',
        datePurchase: 'non-existent date',
        isbn: '-1',
      );
      latestFinishedBook = Book(
        title: 'Nope, nothing is finished yet',
        author: 'no one',
        status: '2',
        dateFinished: 'non-existent date',
        isbn: '-1',
      );
    }
    // ---------------- (0.1) latest book bought and finished [end] ----------------

    // --------------- (1) get longest time to finish [start] ---------------
    final dataWithDatePurchasedAndFinished = await SQLHelper.getBooksWithDatePurchaseAndFinished();

    if (dataWithDatePurchasedAndFinished.isNotEmpty) {
      longestDurationBook = dataWithDatePurchasedAndFinished.first;

      if (dataWithDatePurchasedAndFinished.length == 1) {
        if (longestDurationBook?.datePurchase != null &&
            longestDurationBook!.datePurchase!.isNotEmpty &&
            longestDurationBook?.dateFinished != null &&
            longestDurationBook!.dateFinished!.isNotEmpty) {
          longestDurationDays = daysBetween(
            DateTime.parse(longestDurationBook!.datePurchase!),
            DateTime.parse(longestDurationBook!.dateFinished!),
          );
        }
      } else {
        longestDurationDays = 0;
        if (longestDurationBook?.datePurchase != null &&
            longestDurationBook!.datePurchase!.isNotEmpty &&
            longestDurationBook?.dateFinished != null &&
            longestDurationBook!.dateFinished!.isNotEmpty) {
          longestDurationDays = daysBetween(
            DateTime.parse(longestDurationBook!.datePurchase!),
            DateTime.parse(longestDurationBook!.dateFinished!),
          );
        }

        for (var i = 1; i < dataWithDatePurchasedAndFinished.length; i++) {
          final nowChecking = dataWithDatePurchasedAndFinished.elementAt(i);
          if (nowChecking.datePurchase == null || nowChecking.datePurchase!.isEmpty || nowChecking.dateFinished == null || nowChecking.dateFinished!.isEmpty) {
            continue;
          }

          final nowCheckingDuration = daysBetween(
            DateTime.parse(nowChecking.datePurchase!),
            DateTime.parse(nowChecking.dateFinished!),
          );

          if (nowCheckingDuration > longestDurationDays) {
            longestDurationDays = nowCheckingDuration;
            longestDurationBook = nowChecking;
          }
        }
      }
    } else {
      longestDurationBook = Book(
        title: 'Nope, nothing is finished yet',
        author: 'no one',
        status: '2',
      );
    }

    logger.i('longest duration book = $longestDurationBook, taking $longestDurationDays days to finish!');
    // ---------------- (1) get longest time to finish [end] ----------------

    // --------------- (2) get shortest time to finish [start] ---------------
    if (dataWithDatePurchasedAndFinished.isNotEmpty) {
      shortestDurationBook = dataWithDatePurchasedAndFinished.first;

      if (dataWithDatePurchasedAndFinished.length == 1) {
        if (shortestDurationBook?.datePurchase != null &&
            shortestDurationBook!.datePurchase!.isNotEmpty &&
            shortestDurationBook?.dateFinished != null &&
            shortestDurationBook!.dateFinished!.isNotEmpty) {
          shortestDurationDays = daysBetween(
            DateTime.parse(shortestDurationBook!.datePurchase!),
            DateTime.parse(shortestDurationBook!.dateFinished!),
          );
        }
      } else {
        shortestDurationDays = 0;
        if (shortestDurationBook?.datePurchase != null &&
            shortestDurationBook!.datePurchase!.isNotEmpty &&
            shortestDurationBook?.dateFinished != null &&
            shortestDurationBook!.dateFinished!.isNotEmpty) {
          shortestDurationDays = daysBetween(
            DateTime.parse(shortestDurationBook!.datePurchase!),
            DateTime.parse(shortestDurationBook!.dateFinished!),
          );
        }

        for (var i = 1; i < dataWithDatePurchasedAndFinished.length; i++) {
          final nowChecking = dataWithDatePurchasedAndFinished.elementAt(i);
          if (nowChecking.datePurchase == null || nowChecking.datePurchase!.isEmpty || nowChecking.dateFinished == null || nowChecking.dateFinished!.isEmpty) {
            continue;
          }

          final nowCheckingDuration = daysBetween(
            DateTime.parse(nowChecking.datePurchase!),
            DateTime.parse(nowChecking.dateFinished!),
          );

          if (nowCheckingDuration < shortestDurationDays) {
            shortestDurationDays = nowCheckingDuration;
            shortestDurationBook = nowChecking;
          }
        }
      }
    } else {
      shortestDurationBook = Book(
        title: 'Nope, nothing is finished yet',
        author: 'no one',
        status: '2',
      );
    }

    logger.i('shortest duration book = $shortestDurationBook, taking just $shortestDurationDays days to finish!');
    // ---------------- (2) get shortest time to finish [end] ----------------

    // --------------- (3) get longest time to start reading [start] ---------------
    final dataNewBooksWithDatePurchase = await SQLHelper.getBooksWithDatePurchaseAndStatus(0);

    if (dataNewBooksWithDatePurchase.isNotEmpty) {
      longestDurationNewBook = dataNewBooksWithDatePurchase.first;

      if (dataNewBooksWithDatePurchase.length == 1) {
        if (longestDurationNewBook?.datePurchase != null && longestDurationNewBook!.datePurchase!.isNotEmpty) {
          longestDurationNewDays = daysBetween(DateTime.parse(longestDurationNewBook!.datePurchase!), DateTime.now());
        }
      } else {
        longestDurationNewDays = 0;
        if (longestDurationNewBook?.datePurchase != null && longestDurationNewBook!.datePurchase!.isNotEmpty) {
          longestDurationNewDays = daysBetween(DateTime.parse(longestDurationNewBook!.datePurchase!), DateTime.now());
        }

        for (var i = 1; i < dataNewBooksWithDatePurchase.length; i++) {
          final nowChecking = dataNewBooksWithDatePurchase.elementAt(i);
          if (nowChecking.datePurchase == null || nowChecking.datePurchase!.isEmpty) {
            continue;
          }

          final nowCheckingDuration = daysBetween(DateTime.parse(nowChecking.datePurchase!), DateTime.now());

          if (nowCheckingDuration > longestDurationNewDays) {
            longestDurationNewDays = nowCheckingDuration;
            longestDurationNewBook = nowChecking;
          }
        }
      }
    } else {
      longestDurationNewBook = Book(
        title: 'No, no new book currently',
        author: 'no one',
        status: '0',
      );
    }
    // ---------------- (3) get longest time to start reading [end] ----------------

    // ----------------- (4) now reading with longest time [start] -----------------
    final dataReadingWithDatePurchased = await SQLHelper.getBooksWithDatePurchaseAndStatus(1);

    if (dataReadingWithDatePurchased.isNotEmpty) {
      longestNowReadingBook = dataReadingWithDatePurchased.first;

      if (dataReadingWithDatePurchased.length == 1) {
        if (longestNowReadingBook?.datePurchase != null && longestNowReadingBook!.datePurchase!.isNotEmpty) {
          longestNowReadingDays = daysBetween(DateTime.parse(longestNowReadingBook!.datePurchase!), DateTime.now());
        }
      } else {
        longestNowReadingDays = 0;
        if (longestNowReadingBook?.datePurchase != null && longestNowReadingBook!.datePurchase!.isNotEmpty) {
          longestNowReadingDays = daysBetween(DateTime.parse(longestNowReadingBook!.datePurchase!), DateTime.now());
        }

        for (var i = 1; i < dataReadingWithDatePurchased.length; i++) {
          final nowChecking = dataReadingWithDatePurchased.elementAt(i);
          if (nowChecking.datePurchase == null || nowChecking.datePurchase!.isEmpty) {
            continue;
          }

          final nowCheckingDuration = daysBetween(DateTime.parse(nowChecking.datePurchase!), DateTime.now());

          if (nowCheckingDuration > longestNowReadingDays) {
            longestNowReadingDays = nowCheckingDuration;
            longestNowReadingBook = nowChecking;
          }
        }
      }
    } else {
      longestNowReadingBook = Book(
        title: 'Hmm, you have no now reading books',
        author: 'not reading anything currently',
        status: '1',
        isbn: '-1',
      );
    }
    // ------------------ (4) now reading with longest time [end] ------------------

    setState(() {});
  }

  /// get days between 2 dates
  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    // logger.i('from = $from, to = $to');

    return (to.difference(from).inHours / 24).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(
        //     Icons.arrow_back_sharp,
        //   ),
        //   onPressed: () => Navigator.pop(context),
        // ),
        leading: const Icon(Icons.arrow_forward_ios_sharp),
        title: const Text('tsundoku'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Container(
            color: const Color.fromARGB(255, 242, 220, 177),
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Your collection is currently holds', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '$_countBooksNew ', style: const TextStyle(fontSize: 35, color: Colors.red, fontWeight: FontWeight.bold),),
                      const TextSpan(text: 'new and unread books,\n'),
                      TextSpan(text: ' $_countBooksReading ', style: const TextStyle(fontSize: 35, color: Color.fromARGB(255, 255, 160, 0), fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' books you currently reading, and\n'),
                      TextSpan(text: '$_countBooksFinished ', style: const TextStyle(fontSize: 35, color: Colors.green, fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' books you already finished reading!'),
                    ]
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Container(
            color: Colors.red[500],
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Latest book purchased', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${latestBoughtBook?.displayTitle ?? 'Nope, no new book in collection'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${latestBoughtBook?.displayAuthor ?? 'no one'}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: 'was purchased on '),
                      TextSpan(text: '${latestBoughtBook?.datePurchase ?? 'non-existent date'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ',\n'),
                      TextSpan(text: '$latestBoughtDays\n', style: const TextStyle(fontSize: 35),),
                      const TextSpan(text: 'days ago.'),
                    ]
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Container(
            color: Colors.green[600],
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Latest finished reading book', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${latestFinishedBook?.displayTitle ?? 'Nope, nothing is finished yet'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${latestFinishedBook?.displayAuthor ?? 'no one'}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: 'was done read on '),
                      TextSpan(text: '${latestFinishedBook?.dateFinished ?? 'non-existent date'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ',\n'),
                      TextSpan(text: '$latestFinishedDays\n', style: const TextStyle(fontSize: 35),),
                      const TextSpan(text: 'days ago.'),
                    ]
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 30.0, thickness: 4.0,),
          Container(
            color: Colors.red[400],
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Book with longest time in tsundoku', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${longestDurationNewBook?.displayTitle ?? 'No, no new book currently'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${longestDurationNewBook?.displayAuthor ?? 'no one'}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: 'now already\n'),
                      TextSpan(text: '$longestDurationNewDays\n', style: const TextStyle(fontSize: 35),),
                      const TextSpan(text: 'days and still never been touched in the bookshelf there.'),
                    ]
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Container(
            color: Colors.amber[300],
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Book you taking the most time with currently', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${longestNowReadingBook?.displayTitle ?? 'Hmm, you have no now reading books'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${longestNowReadingBook?.displayAuthor ?? 'not reading anything currently'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                    ],
                  ),
                ),
                (longestNowReadingBook?.isbn != '-1') 
                  ? Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        children: [
                          const TextSpan(text: 'which it has been\n'),
                          TextSpan(text: '$longestNowReadingDays\n', style: const TextStyle(fontSize: 35),),
                          const TextSpan(text: 'days since you bought it and you\'re still not finished with it yet. Let\'s get on with it now, yeah.'),
                        ],
                      ),
                    )
                  : const Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        children: [
                          TextSpan(text: 'so go out there and\n'),
                          TextSpan(text: 'start reading\n', style: TextStyle(fontSize: 35),),
                          TextSpan(text: 'a book now, yeah. Go!'),
                        ],
                      ),
                    )
                ,
              ],
            ),
          ),
          const Divider(),
          Container(
            color: Colors.green[400],
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Book with longest duration to finish', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${longestDurationBook?.displayTitle ?? 'Nope, nothing is finished yet'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${longestDurationBook?.displayAuthor ?? 'no one'}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: 'totalling\n'),
                      TextSpan(text: '$longestDurationDays\n', style: const TextStyle(fontSize: 35),),
                      const TextSpan(text: 'days to finish.'),
                    ]
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Container(
            color: Colors.green[200],
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Book with shortest duration to finish', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${shortestDurationBook?.displayTitle ?? 'Nope, nothing is finished yet'}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${shortestDurationBook?.displayAuthor ?? 'no one'}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: 'taking just\n'),
                      TextSpan(text: '$shortestDurationDays\n', style: const TextStyle(fontSize: 35),),
                      const TextSpan(text: 'days to finish.'),
                    ]
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Container(
            height: 200,
            color: Colors.amber[200],
            child: const Center(child: Text('More stats coming soon.')),
          ),
          const Divider(),
          Container(
            height: 200,
            color: Colors.amber[100],
            child: const Center(child: Text('More stats coming soon.')),
          ),
        ],
      ),
      // body: Container(
      //   color: Colors.lightBlue.shade900,
      //   child: const Center(
      //     child: Text(
      //       'coming soon...',
      //       style: TextStyle(color: Colors.white, fontSize: 22.0),
      //     ),
      //   ),
      // ),
    );
  }

}
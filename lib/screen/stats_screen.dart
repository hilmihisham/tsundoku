import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:tsundoku/util/sql_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

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

  Map<String, dynamic> longestDurationBook = {};
  Map<String, dynamic> shortestDurationBook = {};
  Map<String, dynamic> longestDurationNewBook = {};
  Map<String, dynamic> longestNowReadingBook = {};

  List<InlineSpan> longestNowReadingStatsDisplay = [];

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
    _countBooksNew = countNewBooks!;

    final countReadingBooks = await SQLHelper.getCountByStatus("1");
    _countBooksReading = countReadingBooks!;

    final countFinishedBooks = await SQLHelper.getCountByStatus("2");
    _countBooksFinished = countFinishedBooks!;

    logger.i("new = $_countBooksNew, reading = $_countBooksReading, finished = $_countBooksFinished");
    // ---------------- (0) simplest stats, book count [end] ----------------

    // --------------- (1) get longest time to finish [start] ---------------
    // get all books with date purchase, date finished
    final dataWithDatePurchasedAndFinished = await SQLHelper.getBooksWithDatePurchaseAndFinished();
    // logger.i(dataWithDatePurchasedAndFinished);

    // compare all duration, get longest
    if (dataWithDatePurchasedAndFinished.isNotEmpty) {
      longestDurationBook = dataWithDatePurchasedAndFinished.first;

      if (dataWithDatePurchasedAndFinished.length == 1) {
        // only 1 book available
        longestDurationDays = daysBetween(DateTime.parse(longestDurationBook['datePurchase']), DateTime.parse(longestDurationBook['dateFinished']));
      }
      else {
        // if there's more than 1 book to compare, get duration for first element first
        longestDurationDays = daysBetween(DateTime.parse(longestDurationBook['datePurchase']), DateTime.parse(longestDurationBook['dateFinished']));
        logger.i('to finish: ${longestDurationBook['title']}, $longestDurationDays days.');

        // then go through the whole list 
        for (var i = 1; i < dataWithDatePurchasedAndFinished.length; i++) {
          Map<String, dynamic> nowChecking = dataWithDatePurchasedAndFinished.elementAt(i);
          int nowCheckingDuration = daysBetween(DateTime.parse(nowChecking['datePurchase']), DateTime.parse(nowChecking['dateFinished']));
          logger.i('${nowChecking['title']}, $nowCheckingDuration days.');

          if (nowCheckingDuration > longestDurationDays) {
            longestDurationDays = nowCheckingDuration;
            longestDurationBook = nowChecking;
          }
        }
      }
    }
    else {
      // no finished book yet
      final noBook = <String, dynamic>{'title': 'Nope, nothing is finished yet', 'author': 'no one'};
      longestDurationBook.addEntries(noBook.entries);
    }
        
    logger.i('longest duration book = $longestDurationBook, taking $longestDurationDays days to finish!');
    // ---------------- (1) get longest time to finish [end] ----------------

    // --------------- (2) get shortest time to finish [start] ---------------
    // use db result from (1)
    if (dataWithDatePurchasedAndFinished.isNotEmpty) {
      shortestDurationBook = dataWithDatePurchasedAndFinished.first;

      if (dataWithDatePurchasedAndFinished.length == 1) {
        // only 1 book available
        shortestDurationDays = daysBetween(DateTime.parse(shortestDurationBook['datePurchase']), DateTime.parse(shortestDurationBook['dateFinished']));
      }
      else {
        // if there's more than 1 book to compare, get duration for first element first
        shortestDurationDays = daysBetween(DateTime.parse(shortestDurationBook['datePurchase']), DateTime.parse(shortestDurationBook['dateFinished']));
        logger.i('to finish: ${shortestDurationBook['title']}, $shortestDurationBook days.');

        // then go through the whole list 
        for (var i = 1; i < dataWithDatePurchasedAndFinished.length; i++) {
          Map<String, dynamic> nowChecking = dataWithDatePurchasedAndFinished.elementAt(i);
          int nowCheckingDuration = daysBetween(DateTime.parse(nowChecking['datePurchase']), DateTime.parse(nowChecking['dateFinished']));
          logger.i('${nowChecking['title']}, $nowCheckingDuration days.');

          if (nowCheckingDuration < shortestDurationDays) {
            shortestDurationDays = nowCheckingDuration;
            shortestDurationBook = nowChecking;
          }
        }
      }
    }
    else {
      // no finished book yet
      final noBook = <String, dynamic>{'title': 'Nope, nothing is finished yet', 'author': 'no one'};
      shortestDurationBook.addEntries(noBook.entries);
    }
    
    logger.i('shortest duration book = $shortestDurationBook, taking just $shortestDurationDays days to finish!');
    // ---------------- (2) get shortest time to finish [end] ----------------

    // --------------- (3) get longest time to start reading [start] ---------------
    final dataNewBooksWithDatePurchase = await SQLHelper.getBooksWithDatePurchaseAndStatus(0);
    
    if (dataNewBooksWithDatePurchase.isNotEmpty) {
      longestDurationNewBook = dataNewBooksWithDatePurchase.first;
      
      if (dataNewBooksWithDatePurchase.length == 1) {
        // only one book
        longestDurationNewDays = daysBetween(DateTime.parse(longestDurationNewBook['datePurchase']), DateTime.now());
      }
      else {
        // if there's more than 1 book to compare, get duration for first element first
        longestDurationNewDays = daysBetween(DateTime.parse(longestDurationNewBook['datePurchase']), DateTime.now());
        logger.i('new book: ${longestDurationNewBook['title']}, already $longestDurationNewBook days.');

        // then go through the whole list 
        for (var i = 1; i < dataNewBooksWithDatePurchase.length; i++) {
          Map<String, dynamic> nowChecking = dataNewBooksWithDatePurchase.elementAt(i);
          int nowCheckingDuration = daysBetween(DateTime.parse(nowChecking['datePurchase']), DateTime.now());
          logger.i('${nowChecking['title']}, already $nowCheckingDuration days.');

          if (nowCheckingDuration > longestDurationNewDays) {
            longestDurationNewDays = nowCheckingDuration;
            longestDurationNewBook = nowChecking;
          }
        }
      }
    }
    else {
      // no new book yet
      final noBook = <String, dynamic>{'title': 'No, no new book currently', 'author': 'no one'};
      longestDurationNewBook.addEntries(noBook.entries);      
    }
    // ---------------- (3) get longest time to start reading [end] ----------------

    // ----------------- (4) now reading with longest time [start] -----------------
    final dataReadingWithDatePurchased = await SQLHelper.getBooksWithDatePurchaseAndStatus(1);

    if (dataReadingWithDatePurchased.isNotEmpty) {
      longestNowReadingBook = dataReadingWithDatePurchased.first;

      if (dataReadingWithDatePurchased.length == 1) {
        // only one book
        longestNowReadingDays = daysBetween(DateTime.parse(longestNowReadingBook['datePurchase']), DateTime.now());
      }
      else {
        // if there's more than 1 book to compare, get duration for first element first
        longestNowReadingDays = daysBetween(DateTime.parse(longestNowReadingBook['datePurchase']), DateTime.now());
        logger.i('now reading book: ${longestNowReadingBook['title']}, already $longestNowReadingBook days from purchased date.');

        // then go through the whole list 
        for (var i = 1; i < dataReadingWithDatePurchased.length; i++) {
          Map<String, dynamic> nowChecking = dataReadingWithDatePurchased.elementAt(i);
          int nowCheckingDuration = daysBetween(DateTime.parse(nowChecking['datePurchase']), DateTime.now());
          logger.i('${nowChecking['title']}, already $nowCheckingDuration days from purchased date.');

          if (nowCheckingDuration > longestNowReadingDays) {
            longestNowReadingDays = nowCheckingDuration;
            longestNowReadingBook = nowChecking;
          }
        }
      }
    }
    else {
      // no now reading book (marked with isbn -1)
      final noBook = <String, dynamic>{'title': 'Hmm, you have no now reading books', 'author': 'not reading anything currently', 'isbn':'-1'};
      longestNowReadingBook.addEntries(noBook.entries);      
    }

    // sets up the stats display for this category here, coz got 2 choices of what to display
    longestNowReadingStatsDisplay.add(TextSpan(text: '${longestNowReadingBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),);
    longestNowReadingStatsDisplay.add(const TextSpan(text: ' by '),);
    longestNowReadingStatsDisplay.add(TextSpan(text: '${longestNowReadingBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),);
    if (longestNowReadingBook['isbn'].compareTo('-1') != 0) {
      // got book in now reading
      longestNowReadingStatsDisplay.add(const TextSpan(text: 'which it has been\n'),);
      longestNowReadingStatsDisplay.add(TextSpan(text: '$longestNowReadingDays\n', style: const TextStyle(fontSize: 35),),);
      longestNowReadingStatsDisplay.add(const TextSpan(text: 'days since you bought it and you\'re still not finished with it yet. Let\'s get on with it now, yeah.'),);
    }
    else {
      longestNowReadingStatsDisplay.add(const TextSpan(text: 'so go out there and\n'),);
      longestNowReadingStatsDisplay.add(const TextSpan(text: 'start reading\n', style: TextStyle(fontSize: 35),),);
      longestNowReadingStatsDisplay.add(const TextSpan(text: 'a book now, yeah. Go!'),);
    }
    // ------------------ (4) now reading with longest time [end] ------------------

    // setState to refresh all
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
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Your collection is currently holds', style: TextStyle(fontSize: 20),),
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
            color: Colors.green[400],
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Book with longest duration to finish', style: TextStyle(fontSize: 20),),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${longestDurationBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${longestDurationBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
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
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Book with shortest duration to finish', style: TextStyle(fontSize: 20),),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${shortestDurationBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${shortestDurationBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
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
            color: Colors.red[400],
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Book with longest time in tsundoku', style: TextStyle(fontSize: 20),),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: '${longestDurationNewBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
                      const TextSpan(text: ' by '),
                      TextSpan(text: '${longestDurationNewBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
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
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Book you taking the most time with currently', style: TextStyle(fontSize: 20),),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: longestNowReadingStatsDisplay,
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
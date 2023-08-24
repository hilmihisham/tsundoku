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
  int longestDurationDays = 0;
  int shortestDurationDays = 0;
  int longestDurationNewDays = 0;

  Map<String, dynamic> longestDurationBook = {};
  Map<String, dynamic> shortestDurationBook = {};
  Map<String, dynamic> longestDurationNewBook = {};

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
    final dataNewBooksWithDatePurchase = await SQLHelper.getBooksWithDatePurchaseAndStatusNewBook();
    
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
            height: 200,
            color: Colors.green[500],
            padding: const EdgeInsets.all(20.0),
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
            height: 200,
            color: Colors.green[300],
            padding: const EdgeInsets.all(20.0),
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
            height: 200,
            color: Colors.red[400],
            padding: const EdgeInsets.all(20.0),
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
            height: 200,
            color: Colors.amber[300],
            child: const Center(child: Text('More stats coming soon.')),
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
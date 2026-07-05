import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:tsundoku/util/constants.dart';
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

  Map<String, dynamic> longestDurationBook = {};
  Map<String, dynamic> shortestDurationBook = {};
  Map<String, dynamic> longestDurationNewBook = {};
  Map<String, dynamic> longestNowReadingBook = {};
  Map<String, dynamic> latestBoughtBook = {};
  Map<String, dynamic> latestFinishedBook = {};

  List<Widget> statisticsCarouselList = [];

  @override
  void initState() {
    super.initState();
    _getAllStats();
    // _buildStatisticsCarouselList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// call db query to get all the stats data
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

    // --------------- (0.1) latest book bought and finished [start] ---------------
    final dataLatestBoughtAndFinished = await SQLHelper.getLatestBooksInEachStatus();
    logger.i('0.1\n\n$dataLatestBoughtAndFinished');

    // sort the query result
    if (dataLatestBoughtAndFinished.isNotEmpty) {

      for (var element in dataLatestBoughtAndFinished) {
        if (element['status'] == '0') {
          latestBoughtBook.addAll(element);
          latestBoughtDays = daysBetween(DateTime.parse(element['datePurchase']), DateTime.now());
          logger.d('latest bought book = $latestBoughtBook');
        }

        if (element['status'] == '2') {
          latestFinishedBook.addAll(element);
          latestFinishedDays = daysBetween(DateTime.parse(element['dateFinished']), DateTime.now());
          logger.d('latest finished book = $latestFinishedBook');
        }
      }

      // check if there's no latest bought or latest finished book
      if (latestBoughtBook.isEmpty) {
        final noBookBought = <String, dynamic>{'title': 'Nope, no new book in collection', 'author': 'no one', 'datePurchase':'non-existent date', 'isbn':'-1'};
        latestBoughtBook.addEntries(noBookBought.entries);
        logger.d('latest bought book = $latestBoughtBook');
      }
      if (latestFinishedBook.isEmpty) {
        final noBookFinished = <String, dynamic>{'title': 'Nope, nothing is finished yet', 'author': 'no one', 'dateFinished':'non-existent date', 'isbn':'-1'};
        latestFinishedBook.addEntries(noBookFinished.entries);
        logger.d('latest finished book = $latestFinishedBook');
      }
    }
    else {
      // no data
      final noBookBought = <String, dynamic>{'title': 'Nope, no new book in collection', 'author': 'no one', 'datePurchase':'non-existent date', 'isbn':'-1'};
      latestBoughtBook.addEntries(noBookBought.entries);

      final noBookFinished = <String, dynamic>{'title': 'Nope, nothing is finished yet', 'author': 'no one', 'dateFinished':'non-existent date', 'isbn':'-1'};
      latestFinishedBook.addEntries(noBookFinished.entries);
    }
    // ---------------- (0.1) latest book bought and finished [end] ----------------

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
        // logger.i('to finish: ${longestDurationBook['title']}, $longestDurationDays days.');

        // then go through the whole list 
        for (var i = 1; i < dataWithDatePurchasedAndFinished.length; i++) {
          Map<String, dynamic> nowChecking = dataWithDatePurchasedAndFinished.elementAt(i);
          int nowCheckingDuration = daysBetween(DateTime.parse(nowChecking['datePurchase']), DateTime.parse(nowChecking['dateFinished']));
          // logger.i('${nowChecking['title']}, $nowCheckingDuration days.');

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
        // logger.i('to finish: ${shortestDurationBook['title']}, $shortestDurationBook days.');

        // then go through the whole list 
        for (var i = 1; i < dataWithDatePurchasedAndFinished.length; i++) {
          Map<String, dynamic> nowChecking = dataWithDatePurchasedAndFinished.elementAt(i);
          int nowCheckingDuration = daysBetween(DateTime.parse(nowChecking['datePurchase']), DateTime.parse(nowChecking['dateFinished']));
          // logger.i('${nowChecking['title']}, $nowCheckingDuration days.');

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
        // logger.i('new book: ${longestDurationNewBook['title']}, already $longestDurationNewBook days.');

        // then go through the whole list 
        for (var i = 1; i < dataNewBooksWithDatePurchase.length; i++) {
          Map<String, dynamic> nowChecking = dataNewBooksWithDatePurchase.elementAt(i);
          int nowCheckingDuration = daysBetween(DateTime.parse(nowChecking['datePurchase']), DateTime.now());
          // logger.i('${nowChecking['title']}, already $nowCheckingDuration days.');

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
        // logger.i('now reading book: ${longestNowReadingBook['title']}, already $longestNowReadingBook days from purchased date.');

        // then go through the whole list 
        for (var i = 1; i < dataReadingWithDatePurchased.length; i++) {
          Map<String, dynamic> nowChecking = dataReadingWithDatePurchased.elementAt(i);
          int nowCheckingDuration = daysBetween(DateTime.parse(nowChecking['datePurchase']), DateTime.now());
          // logger.i('${nowChecking['title']}, already $nowCheckingDuration days from purchased date.');

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
    // ------------------ (4) now reading with longest time [end] ------------------

    _buildStatisticsCarouselList();

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

  void _buildStatisticsCarouselList() async {
    statisticsCarouselList.add(
      CarouselCard(
        cardColor: Constants.appColors.red1,
        cardTitle: 'Latest book purchased',
        book: latestBoughtBook,
        innerMessage: 'was purchased on',
        showDatePurchased: true,
        dayCount: latestBoughtDays
      )
    );

    statisticsCarouselList.add(
      CarouselCard(
        cardColor: Constants.appColors.green1, 
        cardTitle: 'Latest finished reading book', 
        book: latestFinishedBook,
        innerMessage: 'was done read on', 
        showDatePurchased: true,
        dayCount: latestFinishedDays
      )
    );

    statisticsCarouselList.add(
      CarouselCard(
        cardColor: Constants.appColors.red2, 
        cardTitle: 'Book with longest time in tsundoku', 
        book: longestDurationNewBook,
        innerMessage: 'now already', 
        showDatePurchased: false,
        dayCount: longestDurationNewDays,
        dayCountEndMsg: 'days and still never been touched in the bookshelf there',
      )
    );

    statisticsCarouselList.add(
      CarouselCard(
        cardColor: Constants.appColors.yellow1, 
        cardTitle: 'Book you taking the most time with currently', 
        book: longestNowReadingBook,
        innerMessage: 'which it has been', 
        showDatePurchased: false,
        dayCount: longestNowReadingDays,
        dayCountEndMsg: 'days since you bought it and you\'re still not finished with it yet. Let\'s get on with it now, yeah.',
      )
    );

    statisticsCarouselList.add(
      CarouselCard(
        cardColor: Constants.appColors.green1, 
        cardTitle: 'Book with longest duration to finish', 
        book: longestDurationBook,
        innerMessage: 'totalling', 
        showDatePurchased: false,
        dayCount: longestDurationDays,
        dayCountEndMsg: 'days to finish.',
      )
    );

    statisticsCarouselList.add(
      CarouselCard(
        cardColor: Constants.appColors.green2, 
        cardTitle: 'Book with shortest duration to finish', 
        book: shortestDurationBook,
        innerMessage: 'taking just', 
        showDatePurchased: false,
        dayCount: shortestDurationDays,
        dayCountEndMsg: 'days to finish.',
      )
    );

    // setState to refresh all
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.arrow_forward_ios_sharp),
        title: const Text('tsundoku'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          // Container(
          //   color: const Color.fromARGB(255, 242, 220, 177),
          //   padding: const EdgeInsets.all(30.0),
          //   margin: EdgeInsets.all(15),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text('Your collection is currently holds', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
          //       Text.rich(
          //         textAlign: TextAlign.center,
          //         TextSpan(
          //           children: [
          //             TextSpan(text: '$_countBooksNew ', style: const TextStyle(fontSize: 35, color: Colors.red, fontWeight: FontWeight.bold),),
          //             const TextSpan(text: 'new and unread books,\n'),
          //             TextSpan(text: ' $_countBooksReading ', style: const TextStyle(fontSize: 35, color: Color.fromARGB(255, 255, 160, 0), fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ' books you currently reading, and\n'),
          //             TextSpan(text: '$_countBooksFinished ', style: const TextStyle(fontSize: 35, color: Colors.green, fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ' books you already finished reading!'),
          //           ]
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          Card.outlined(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Constants.appColors.red1,  // Change your border color here
                width: 5.0,                       // Set the thickness of the border
              ),
              borderRadius: BorderRadius.circular(12.0), // Match the corner radius
            ),
            color: Constants.appColors.red2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$_countBooksNew ', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                        const TextSpan(text: 'new and unread books'),
                      ],
                    ),
                  ),
                ],
              ), 
            ),
          ),
          Card.outlined(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Constants.appColors.yellow1,  // Change your border color here
                width: 5.0,                       // Set the thickness of the border
              ),
              borderRadius: BorderRadius.circular(12.0), // Match the corner radius
            ),
            color: Constants.appColors.yellow2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$_countBooksReading ', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                        const TextSpan(text: 'books you currently reading'),
                      ],
                    ),
                  ),
                ],
              ), 
            ),
          ),
          Card.outlined(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Constants.appColors.green1,  // Change your border color here
                width: 5.0,                       // Set the thickness of the border
              ),
              borderRadius: BorderRadius.circular(12.0), // Match the corner radius
            ),
            color: Constants.appColors.green2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$_countBooksFinished ', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                        const TextSpan(text: 'books you already finished reading'),
                      ],
                    ),
                  ),
                ],
              ), 
            ),
          ),
          const Divider(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 550),
            child: CarouselView(
              itemExtent: 330,
              shrinkExtent: 200,
              children: statisticsCarouselList,
            ),
          ),
          const Divider(),
          // Container(
          //   color: Colors.red[500],
          //   padding: const EdgeInsets.all(30.0),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text('Latest book purchased', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
          //       Text.rich(
          //         textAlign: TextAlign.center,
          //         TextSpan(
          //           children: [
          //             TextSpan(text: '${latestBoughtBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ' by '),
          //             TextSpan(text: '${latestBoughtBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: 'was purchased on '),
          //             TextSpan(text: '${latestBoughtBook['datePurchase']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ',\n'),
          //             TextSpan(text: '$latestBoughtDays\n', style: const TextStyle(fontSize: 35),),
          //             const TextSpan(text: 'days ago.'),
          //           ]
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const Divider(),
          // Container(
          //   color: Colors.green[600],
          //   padding: const EdgeInsets.all(30.0),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text('Latest finished reading book', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
          //       Text.rich(
          //         textAlign: TextAlign.center,
          //         TextSpan(
          //           children: [
          //             TextSpan(text: '${latestFinishedBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ' by '),
          //             TextSpan(text: '${latestFinishedBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: 'was done read on '),
          //             TextSpan(text: '${latestFinishedBook['dateFinished']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ',\n'),
          //             TextSpan(text: '$latestFinishedDays\n', style: const TextStyle(fontSize: 35),),
          //             const TextSpan(text: 'days ago.'),
          //           ]
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const Divider(height: 30.0, thickness: 4.0,),
          // Container(
          //   color: Colors.red[400],
          //   padding: const EdgeInsets.all(30.0),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text('Book with longest time in tsundoku', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
          //       Text.rich(
          //         textAlign: TextAlign.center,
          //         TextSpan(
          //           children: [
          //             TextSpan(text: '${longestDurationNewBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ' by '),
          //             TextSpan(text: '${longestDurationNewBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: 'now already\n'),
          //             TextSpan(text: '$longestDurationNewDays\n', style: const TextStyle(fontSize: 35),),
          //             const TextSpan(text: 'days and still never been touched in the bookshelf there.'),
          //           ]
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const Divider(),
          // Container(
          //   color: Colors.amber[300],
          //   padding: const EdgeInsets.all(30.0),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text('Book you taking the most time with currently', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
          //       Text.rich(
          //         textAlign: TextAlign.center,
          //         TextSpan(
          //           children: [
          //             TextSpan(text: '${longestNowReadingBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ' by '),
          //             TextSpan(text: '${longestNowReadingBook['author']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //           ],
          //         ),
          //       ),
          //       (longestNowReadingBook['isbn'] != '-1') 
          //         ? Text.rich(
          //             textAlign: TextAlign.center,
          //             TextSpan(
          //               children: [
          //                 const TextSpan(text: 'which it has been\n'),
          //                 TextSpan(text: '$longestNowReadingDays\n', style: const TextStyle(fontSize: 35),),
          //                 const TextSpan(text: 'days since you bought it and you\'re still not finished with it yet. Let\'s get on with it now, yeah.'),
          //               ],
          //             ),
          //           )
          //         : const Text.rich(
          //             textAlign: TextAlign.center,
          //             TextSpan(
          //               children: [
          //                 TextSpan(text: 'so go out there and\n'),
          //                 TextSpan(text: 'start reading\n', style: TextStyle(fontSize: 35),),
          //                 TextSpan(text: 'a book now, yeah. Go!'),
          //               ],
          //             ),
          //           )
          //       ,
          //     ],
          //   ),
          // ),
          // const Divider(),
          // Container(
          //   color: Colors.green[400],
          //   padding: const EdgeInsets.all(30.0),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text('Book with longest duration to finish', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
          //       Text.rich(
          //         textAlign: TextAlign.center,
          //         TextSpan(
          //           children: [
          //             TextSpan(text: '${longestDurationBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ' by '),
          //             TextSpan(text: '${longestDurationBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: 'totalling\n'),
          //             TextSpan(text: '$longestDurationDays\n', style: const TextStyle(fontSize: 35),),
          //             const TextSpan(text: 'days to finish.'),
          //           ]
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const Divider(),
          // Container(
          //   color: Colors.green[200],
          //   padding: const EdgeInsets.all(30.0),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text('Book with shortest duration to finish', style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
          //       Text.rich(
          //         textAlign: TextAlign.center,
          //         TextSpan(
          //           children: [
          //             TextSpan(text: '${shortestDurationBook['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: ' by '),
          //             TextSpan(text: '${shortestDurationBook['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
          //             const TextSpan(text: 'taking just\n'),
          //             TextSpan(text: '$shortestDurationDays\n', style: const TextStyle(fontSize: 35),),
          //             const TextSpan(text: 'days to finish.'),
          //           ]
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const Divider(),
          // Container(
          //   height: 200,
          //   color: Colors.amber[200],
          //   child: const Center(child: Text('More stats coming soon.')),
          // ),
          // const Divider(),
          Container(
            height: 100,
            color: Colors.amber[100],
            child: const Center(child: Text('More stats coming soon.')),
          ),
        ],
      ),
    );
  }

}

class CarouselCard extends StatelessWidget {
  /// showDatePurchase: if the statistics want to show date of purchased, set this as true
  /// 
  /// dayCountEndMsg: if empty, will default to "days ago" sentence at the end of statistic
  const CarouselCard({
    super.key,
    required this.cardColor,
    required this.cardTitle,
    required this.book,
    required this.innerMessage,
    required this.showDatePurchased,
    required this.dayCount,
    this.dayCountEndMsg = '',
  });

  // final int index;
  // final String label;
  final Color cardColor;
  final String cardTitle;
  final Map<String, dynamic> book;
  final String innerMessage;
  final bool showDatePurchased;
  final int dayCount;
  final String dayCountEndMsg;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: cardColor,
      child: Container(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(cardTitle, style: TextStyle(fontSize: 20,), textAlign: TextAlign.center,),
            Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                children: [
                  TextSpan(text: '${book['title']}', style: const TextStyle(fontWeight: FontWeight.bold),),
                  const TextSpan(text: ' by '),
                  TextSpan(text: '${book['author']}\n', style: const TextStyle(fontWeight: FontWeight.bold),),
                  TextSpan(text: '$innerMessage '),
                  TextSpan(text: (showDatePurchased) ? '${book['datePurchase']}' : '', style: const TextStyle(fontWeight: FontWeight.bold),),
                  TextSpan(text: (showDatePurchased) ? ',\n' : '\n'),
                  TextSpan(text: '$dayCount\n', style: const TextStyle(fontSize: 35),),
                  TextSpan(text: (dayCountEndMsg.isEmpty) ? 'days ago.' : dayCountEndMsg),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}
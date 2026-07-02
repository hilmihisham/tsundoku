import 'package:flutter/material.dart';

class BookTicketDetails extends StatelessWidget {
  final Map<String, dynamic> book;

  final TextStyle titleTextStyle = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 11,
      height: 1,
      letterSpacing: .2,
      fontWeight: FontWeight.w600,
      color: Color(0xffafafaf),
  );
  final TextStyle contentTextStyle =
      TextStyle(fontFamily: 'Oswald', fontSize: 16, height: 1.8, letterSpacing: .3, color: Color(0xff083e64));

  BookTicketDetails(this.book, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: Colors.white,
      ),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PUBLISHER', style: titleTextStyle),
                  Text(book['publisher'] ?? 'N/A', style: contentTextStyle),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STATUS', style: titleTextStyle),
                  Text(book['status'] ?? 'X', style: contentTextStyle),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DATE OF PURCHASE', style: titleTextStyle),
                  Text(book['datePurchase'] ?? 'N/A', style: contentTextStyle),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DATE FINISHED', style: titleTextStyle),
                  Text(book['dateFinished'] ?? '...', style: contentTextStyle),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
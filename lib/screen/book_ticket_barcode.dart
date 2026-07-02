import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class BookTicketBarcode extends StatelessWidget {
  // logger
  final logger = Logger();
  
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: MaterialButton(
            child: Image.asset('assets/images/barcode.png'),
            onPressed: () {
              logger.i('Button was pressed');
            }),
      ));
}

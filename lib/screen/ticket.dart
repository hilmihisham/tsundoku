import 'package:flutter/material.dart';
import 'package:tsundoku/screen/book_folding_ticket.dart';

import 'book_ticket_details.dart';
import 'book_ticket_summary.dart';
import 'book_ticket_barcode.dart';

class Ticket extends StatefulWidget {
  static const double nominalOpenHeight = 400;
  static const double nominalClosedHeight = 160;
  final Map<String, dynamic> book;
  final VoidCallback? onClick;

  const Ticket({super.key, required this.book, required this.onClick});

  @override
  State<StatefulWidget> createState() => _TicketState();
}

class _TicketState extends State<Ticket> {
  BookTicketSummary? topCard;
  late BookTicketSummary frontCard = BookTicketSummary(book: widget.book);
  late BookTicketDetails middleCard = BookTicketDetails(widget.book);
  BookTicketBarcode bottomCard = BookTicketBarcode();
  bool _isOpen = false;

  Widget get backCard => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          color: Color(0xffdce6ef),
        ),
      );
  
  @override
  Widget build(BuildContext context) {
    return BookFoldingTicket(entries: _getEntries(), isOpen: _isOpen, onClick: _handleOnTap);
  }
  
  List<FoldEntry> _getEntries() {
    return [
      FoldEntry(height: 160.0, front: topCard),
      FoldEntry(height: 160.0, front: middleCard, back: frontCard),
      FoldEntry(height: 80.0, front: bottomCard, back: backCard)
    ];
  }

  void _handleOnTap() {
    widget.onClick?.call();
    setState(() {
      _isOpen = !_isOpen;
      topCard = BookTicketSummary(book: widget.book, theme: SummaryTheme.dark, isOpen: _isOpen);
    });
  }
}
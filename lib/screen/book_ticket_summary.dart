import 'package:flutter/material.dart';

enum SummaryTheme { dark, light }

class BookTicketSummary extends StatelessWidget {
  final Map<String, dynamic> book;
  final SummaryTheme theme;
  final bool isOpen;

  const BookTicketSummary({super.key, required this.book, this.theme = SummaryTheme.light, this.isOpen = false});

  Color get mainTextColor => Color(0xFF083e64);
  Color get secondaryTextColor => Color(0xFF838383);
  Color get separatorColor => Color(0xff396583);

  TextStyle get bodyTextStyle => TextStyle(color: mainTextColor, fontSize: 13, fontFamily: 'Oswald');

  bool get isLight => theme == SummaryTheme.light;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _getBackgroundDecoration(),
      width: double.infinity,
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // _buildTicketHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Stack(
                children: [
                  Align(alignment: Alignment.centerLeft, child: _buildBookTitle()),
                ],
              ),
            ),
            _buildBottomIcon(),
          ],
        ),
      ),
    );
  }
  
  Decoration _getBackgroundDecoration() {
    return isLight
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: Colors.white,
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: Colors.grey[800],
          );
  }
  
  Widget _buildTicketHeader(BuildContext context) {
    var headerStyle = TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.bold,
      color: Color(0xFFe46565),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          book['title'] ?? 'Unknown Title',
          style: headerStyle,
        ),
        Text(
          book['author'] ?? 'Unknown Author',
          style: headerStyle,
        ),
      ],
    );
  }
  
  Widget _buildBookTitle() {
    String title = book['title'] ?? 'Unknown Title';
    return Column(
      children: [
        Text(
          title.length > 60 ? '${title.substring(0, 60)}...' : title,
          style: bodyTextStyle.copyWith(fontSize: 22),
        ),
        Text(
          book['datePurchase'] ?? 'Unknown Date of Purchase',
          style: bodyTextStyle.copyWith(color: secondaryTextColor),
        ),
      ],
    );
  }
  
  Widget _buildBottomIcon() {
    IconData icon = isLight ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up;
    return Icon(
      icon,
      color: mainTextColor,
      size: 18,
    );
  }
}
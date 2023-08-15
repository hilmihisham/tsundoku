import 'package:flutter/material.dart';
import 'package:tsundoku/screen/color_screen.dart';
import 'package:tsundoku/screen/home_screen.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    //_pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('tsundoku'),
      // ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: const [
          HomeScreen(),
          ColorScreen(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 7.0,),
            barIcon(icon: Icons.home, page: 0,),
            barIcon(icon: Icons.leaderboard_sharp, page: 1),
            const SizedBox(width: 7.0,),
          ],
        ),
      ),
    );
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    _pageController.jumpToPage(page);
  }

  Widget barIcon({IconData icon = Icons.home, int page = 0}) {
    return IconButton(
      icon: Icon(icon, size: 24.0),
      color:
          _page == page ? Colors.white : Colors.blueGrey[300],
      onPressed: () => _pageController.jumpToPage(page),
    );
  }

}


import 'package:flutter/material.dart';
import 'package:tsundoku/screen/base_screen.dart';
// import 'package:tsundoku/screen/home_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false, // remove debug banner
      title: 'tsundoku',
      // theme: ThemeData(
      //   primarySwatch: Colors.blueGrey,
      // ),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.cyan,
      ),
      // home: const HomeScreen(),
      home: const BaseScreen(),
    );
  }
}

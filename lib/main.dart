import 'package:flutter/material.dart';
import 'package:tsundoku/screen/base_screen.dart';

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
        colorSchemeSeed: const Color.fromRGBO(150, 206, 180, 1.0),
        bottomAppBarTheme: const BottomAppBarTheme(color: Color.fromRGBO(135, 185, 162, 1.0))
      ),
      home: const BaseScreen(),
    );
  }
}

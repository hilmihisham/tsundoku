import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tsundoku/screen/base_screen.dart';
import 'package:tsundoku/util/notification_service.dart';

void main() async {
  // preserve splash screen until first home screenloading is complete
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // initialize notification service globally
  await NotificationService().initNotifications();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});


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
        bottomAppBarTheme: const BottomAppBarThemeData(color: Color.fromRGBO(135, 185, 162, 1.0))
      ),
      home: const BaseScreen(),
    );
  }
}

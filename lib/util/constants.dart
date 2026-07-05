import 'package:flutter/material.dart';

class Constants {
  static const appVersion = _AppVersion();
  static const csvHeader = _CsvHeader();
  static const appColors = _AppColors();
}

class _AppVersion {
  const _AppVersion();

  // reminder: also go update version number in pubspec & readme file
  final String versionNumber = '0.9.0';
}

class _CsvHeader {
  const _CsvHeader();

  final String column1 = '0';
  final String column2 = 'tsundoku';
  final String column3 = 'aolabs';
  final String column4 = '0';
}

class _AppColors {
  // color name from coolors.co
  const _AppColors();
  
  Color get red1 => Colors.red.shade400; // strawberry red
  Color get red2 => const Color(0xFFF6A3A2); // powder blush

  Color get yellow1 => Colors.amber; // amber gold
  Color get yellow2 => const Color(0xFFFFE699); // jasmine
  
  Color get green1 => Colors.green.shade400; // moss green
  Color get green2 => const Color(0xFFB9DFBA); // celadon

}
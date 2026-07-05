
class Constants {
  static const appVersion = _AppVersion();
  static const csvHeader = _CsvHeader();
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
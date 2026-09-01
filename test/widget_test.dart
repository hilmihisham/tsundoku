import 'package:flutter_test/flutter_test.dart';
import 'package:tsundoku/screen/addbook_screen.dart';

void main() {
  group('date resolution logic', () {
    test('returns today when purchase date is blank', () {
      final result = resolveReadCompletionDate(
        purchaseDate: '',
        currentTime: DateTime(2026, 9, 1),
      );

      expect(result, '2026-09-01');
    });

    test('returns today when purchase date is invalid', () {
      final result = resolveReadCompletionDate(
        purchaseDate: 'not-a-date',
        currentTime: DateTime(2026, 9, 1),
      );

      expect(result, '2026-09-01');
    });

    test('uses purchase date when it is in the future', () {
      final result = resolveReadCompletionDate(
        purchaseDate: '2026-09-05',
        currentTime: DateTime(2026, 9, 1),
      );

      expect(result, '2026-09-05');
    });

    test('uses today when purchase date is before today', () {
      final result = resolveReadCompletionDate(
        purchaseDate: '2026-08-20',
        currentTime: DateTime(2026, 9, 1),
      );

      expect(result, '2026-09-01');
    });

    test('keeps explicit completion date when present', () {
      final result = resolveReadCompletionDate(
        purchaseDate: '2026-08-20',
        completionDate: '2026-08-30',
        currentTime: DateTime(2026, 9, 1),
      );

      expect(result, '2026-08-30');
    });
  });
}

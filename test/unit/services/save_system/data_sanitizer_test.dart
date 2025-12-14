import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/save_system/data_sanitizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataSanitizer', () {
    test('sanitizeData convertit DateTime en ISO8601', () {
      final dt = DateTime(2025, 1, 2, 3, 4, 5);
      final result = DataSanitizer.sanitizeData(dt);
      expect(result, isA<String>());
      expect(result, dt.toIso8601String());
    });

    test('sanitizeData convertit Map avec clés non-string en Map<String, dynamic>', () {
      final input = {
        1: 'one',
        true: 2,
        'nested': {3: 'three'},
      };

      final result = DataSanitizer.sanitizeData(input) as Map<String, dynamic>;

      expect(result.keys, containsAll(<String>['1', 'true', 'nested']));
      expect(result['1'], 'one');
      expect(result['true'], 2);

      final nested = result['nested'] as Map<String, dynamic>;
      expect(nested['3'], 'three');
    });

    test('sanitizeData removeNulls filtre les nulls dans les listes et maps', () {
      final input = {
        'a': null,
        'b': [1, null, 2],
      };

      final result = DataSanitizer.sanitizeData(input, removeNulls: true) as Map<String, dynamic>;

      expect(result.containsKey('a'), isFalse);
      expect(result['b'], [1, 2]);
    });

    test('sanitizeNumber remplace NaN/Infinity par defaultValue', () {
      expect(DataSanitizer.sanitizeNumber(double.nan, defaultValue: 7), 7);
      expect(DataSanitizer.sanitizeNumber(double.infinity, defaultValue: 7), 7);
    });

    test('sanitizeString trim et remplace vide par defaultValue', () {
      expect(DataSanitizer.sanitizeString('  hello  '), 'hello');
      expect(DataSanitizer.sanitizeString('', defaultValue: 'x'), 'x');
    });
  });
}

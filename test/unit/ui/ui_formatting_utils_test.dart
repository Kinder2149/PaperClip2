import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/ui/utils/ui_formatting_utils.dart';

void main() {
  group('UiFormattingUtils.formatDurationHms', () {
    test('formats 0s', () {
      expect(UiFormattingUtils.formatDurationHms(Duration.zero), '0s');
    });

    test('formats 59s', () {
      expect(UiFormattingUtils.formatDurationHms(const Duration(seconds: 59)), '59s');
    });

    test('formats 1m05s', () {
      expect(UiFormattingUtils.formatDurationHms(const Duration(minutes: 1, seconds: 5)), '1m 5s');
    });

    test('formats 1h01m01s', () {
      expect(UiFormattingUtils.formatDurationHms(const Duration(hours: 1, minutes: 1, seconds: 1)), '1h 1m 1s');
    });
  });
}

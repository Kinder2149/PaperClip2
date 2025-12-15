import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/format/game_format.dart';

void main() {
  group('GameFormat', () {
    test('money formats with euro symbol', () {
      final v = GameFormat.money(1.234);
      expect(v.contains('€'), isTrue);
    });

    test('moneyPerMin adds /min suffix', () {
      expect(GameFormat.moneyPerMin(12.3).endsWith('/min'), isTrue);
    });

    test('percentFromRatio formats percent', () {
      final v = GameFormat.percentFromRatio(0.123, decimals: 1);
      expect(v.endsWith('%'), isTrue);
    });

    test('quantityCompact uses K suffix for >= 1000', () {
      final v = GameFormat.quantityCompact(1500, decimals: 1);
      expect(v.contains('K'), isTrue);
    });

    test('durationHms formats as H:MM:SS', () {
      expect(GameFormat.durationHms(0), '0:00:00');
      expect(GameFormat.durationHms(59), '0:00:59');
      expect(GameFormat.durationHms(60), '0:01:00');
      expect(GameFormat.durationHms(3661), '1:01:01');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/services/google/sync/sync_opt_in.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncOptIn', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('default is false when not set', () async {
      final v = await SyncOptIn.instance.get();
      expect(v, isFalse);
    });

    test('set(true) persists and get() returns true', () async {
      await SyncOptIn.instance.set(true);
      final v = await SyncOptIn.instance.get();
      expect(v, isTrue);
    });

    test('set(false) persists and get() returns false', () async {
      await SyncOptIn.instance.set(false);
      final v = await SyncOptIn.instance.get();
      expect(v, isFalse);
    });
  });
}

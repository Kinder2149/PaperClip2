import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/reset_history_entry.dart';

/// Tests pour le modèle ResetHistoryEntry
void main() {
  group('ResetHistoryEntry', () {
    test('création avec tous les paramètres', () {
      final timestamp = DateTime(2026, 4, 7, 12, 0);
      final entry = ResetHistoryEntry(
        timestamp: timestamp,
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );

      expect(entry.timestamp, equals(timestamp));
      expect(entry.levelBefore, equals(25));
      expect(entry.quantumGained, equals(10));
      expect(entry.innovationGained, equals(5));
    });

    test('toJson sérialise correctement', () {
      final timestamp = DateTime(2026, 4, 7, 12, 0);
      final entry = ResetHistoryEntry(
        timestamp: timestamp,
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );

      final json = entry.toJson();

      expect(json['timestamp'], equals('2026-04-07T12:00:00.000'));
      expect(json['levelBefore'], equals(25));
      expect(json['quantumGained'], equals(10));
      expect(json['innovationGained'], equals(5));
    });

    test('fromJson désérialise correctement', () {
      final json = {
        'timestamp': '2026-04-07T12:00:00.000',
        'levelBefore': 25,
        'quantumGained': 10,
        'innovationGained': 5,
      };

      final entry = ResetHistoryEntry.fromJson(json);

      expect(entry.timestamp, equals(DateTime(2026, 4, 7, 12, 0)));
      expect(entry.levelBefore, equals(25));
      expect(entry.quantumGained, equals(10));
      expect(entry.innovationGained, equals(5));
    });

    test('toString retourne format lisible', () {
      final timestamp = DateTime(2026, 4, 7, 12, 0);
      final entry = ResetHistoryEntry(
        timestamp: timestamp,
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );

      final str = entry.toString();

      expect(str, contains('ResetHistoryEntry'));
      expect(str, contains('levelBefore: 25'));
      expect(str, contains('Q: 10'));
      expect(str, contains('PI: 5'));
    });

    test('égalité entre deux entrées identiques', () {
      final timestamp = DateTime(2026, 4, 7, 12, 0);
      final entry1 = ResetHistoryEntry(
        timestamp: timestamp,
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );
      final entry2 = ResetHistoryEntry(
        timestamp: timestamp,
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );

      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('inégalité entre deux entrées différentes', () {
      final timestamp = DateTime(2026, 4, 7, 12, 0);
      final entry1 = ResetHistoryEntry(
        timestamp: timestamp,
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );
      final entry2 = ResetHistoryEntry(
        timestamp: timestamp,
        levelBefore: 30, // Différent
        quantumGained: 10,
        innovationGained: 5,
      );

      expect(entry1, isNot(equals(entry2)));
    });

    test('cycle complet toJson -> fromJson', () {
      final original = ResetHistoryEntry(
        timestamp: DateTime(2026, 4, 7, 12, 30, 45),
        levelBefore: 42,
        quantumGained: 15,
        innovationGained: 8,
      );

      final json = original.toJson();
      final restored = ResetHistoryEntry.fromJson(json);

      expect(restored, equals(original));
    });
  });
}

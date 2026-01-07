import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paperclip2/env_config.dart';

/// E2E FastAPI: JWT (TEST_JWT_A) -> PUT save -> GET latest -> GET list -> POST analytics (best-effort)
void main() {
  setUpAll(() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  });

  test('FastAPI E2E: saves + analytics', () async {
    final base = EnvConfig.backendBaseUrl;
    if (base.isEmpty) {
      print('SKIP: BACKEND_BASE_URL non défini');
      return;
    }
    final jwt = dotenv.env['TEST_JWT_A']?.trim() ?? '';
    if (jwt.isEmpty) {
      print('SKIP: TEST_JWT_A non défini');
      return;
    }

    // Health check
    final health = await http.get(Uri.parse('$base/health'));
    expect(health.statusCode, 200);

    final headers = {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };

    // New partieId
    final partieId = _uuidV4();

    // PUT /saves/{partieId}
    final putUri = Uri.parse('$base/saves/$partieId');
    final snapshot = {
      'metadata': {'partieId': partieId},
      'core': <String, dynamic>{},
      'stats': <String, dynamic>{},
    };
    final putResp = await http.put(putUri, headers: headers, body: jsonEncode({'snapshot': snapshot}));
    expect(putResp.statusCode, inInclusiveRange(200, 299), reason: 'PUT failed: ${putResp.statusCode} ${putResp.body}');

    // GET /saves/{partieId}/latest
    final latestUri = Uri.parse('$base/saves/$partieId/latest');
    final latest = await http.get(latestUri, headers: {'Authorization': 'Bearer $jwt'});
    expect(latest.statusCode, 200, reason: 'Latest failed: ${latest.statusCode} ${latest.body}');
    final latestJson = jsonDecode(latest.body) as Map;
    expect(latestJson['partie_id'] ?? latestJson['partieId'], equals(partieId));
    expect(latestJson['version'], anyOf([1, isA<int>()]));

    // GET /saves?page=1&limit=50
    final listUri = Uri.parse('$base/saves?page=1&limit=50');
    final listResp = await http.get(listUri, headers: {'Authorization': 'Bearer $jwt'});
    expect(listResp.statusCode, 200, reason: 'List failed: ${listResp.statusCode} ${listResp.body}');
    final listJson = jsonDecode(listResp.body) as Map;
    expect(listJson['items'], isA<List>());

    // POST /analytics/events (best-effort)
    final evtUri = Uri.parse('$base/analytics/events');
    final evt = {
      'name': 'level_up',
      'properties': {'level': 2},
      'timestamp': '2025-01-04T12:34:56Z'
    };
    final evtResp = await http.post(evtUri, headers: headers, body: jsonEncode(evt));
    expect(evtResp.statusCode, anyOf([200, 202, 404]));
  });
}

String _uuidV4() {
  // simple UUID v4 generator for tests (not cryptographically strong)
  String _randHex(int len) {
    final r = List<int>.generate(len, (_) => (DateTime.now().microsecondsSinceEpoch * 9973 + _seed++) % 16);
    const hex = '0123456789abcdef';
    return r.map((n) => hex[n]).join();
  }

  final time = DateTime.now().microsecondsSinceEpoch & 0xffffffff;
  final p1 = _randHex(8);
  final p2 = _randHex(4);
  final p3 = '4' + _randHex(3); // version 4
  final n = int.parse(_randHex(1), radix: 16);
  final p4 = ((0x8 | (n & 0x3))).toRadixString(16) + _randHex(3); // variant 8,b
  final p5 = _randHex(12);
  return '$p1-$p2-$p3-$p4-$p5';
}

int _seed = 0;

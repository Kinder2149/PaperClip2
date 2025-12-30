import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/services/cloud/http_cloud_persistence_port.dart';

Future<HttpServer> _startServer(FutureOr<void> Function(HttpRequest) handler) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(handler);
  return server;
}

Uri _uriFor(HttpServer s, String path) => Uri.parse('http://${s.address.address}:${s.port}$path');

void main() {
  group('HttpCloudPersistencePort status fallbacks', () {
    test('statusById uses header ETag when provided', () async {
      final server = await _startServer((req) async {
        if (req.uri.path.endsWith('/status')) {
          req.response.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
          req.response.headers.set(HttpHeaders.etagHeader, 'abc');
          req.response.write(jsonEncode({'partieId': 'p1', 'syncState': 'ok'}));
          await req.response.close();
          return;
        }
        req.response.statusCode = 404; await req.response.close();
      });
      final base = _uriFor(server, '');
      final port = HttpCloudPersistencePort(baseUrl: base.toString());
      final st = await port.statusById(partieId: 'p1');
      expect(st.syncState, 'ok');
      await server.close(force: true);
    });

    test('statusById uses body etag when header missing', () async {
      final server = await _startServer((req) async {
        if (req.uri.path.endsWith('/status')) {
          req.response.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
          req.response.write(jsonEncode({'partieId': 'p2', 'syncState': 'ok', 'etag': 'xyz'}));
          await req.response.close();
          return;
        }
        req.response.statusCode = 404; await req.response.close();
      });
      final base = _uriFor(server, '');
      final port = HttpCloudPersistencePort(baseUrl: base.toString());
      final st = await port.statusById(partieId: 'p2');
      expect(st.syncState, 'ok');
      await server.close(force: true);
    });

    test('statusById uses remoteVersion as fallback', () async {
      final server = await _startServer((req) async {
        if (req.uri.path.endsWith('/status')) {
          req.response.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
          req.response.write(jsonEncode({'partieId': 'p3', 'syncState': 'ok', 'remoteVersion': 42}));
          await req.response.close();
          return;
        }
        req.response.statusCode = 404; await req.response.close();
      });
      final base = _uriFor(server, '');
      final port = HttpCloudPersistencePort(baseUrl: base.toString());
      final st = await port.statusById(partieId: 'p3');
      expect(st.syncState, 'ok');
      expect(st.remoteVersion, 42);
      await server.close(force: true);
    });
  });

  group('HttpCloudPersistencePort listParties parsing', () {
    test('listParties parses mixed types and dates', () async {
      final server = await _startServer((req) async {
        if (req.uri.path.endsWith('/api/cloud/parties')) {
          req.response.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
          req.response.write(jsonEncode([
            {
              'partieId': 'a',
              'name': 'A',
              'gameVersion': '1',
              'remoteVersion': 1,
              'lastPushAt': '2024-01-01T00:00:00Z',
              'lastPullAt': null,
              'playerId': 'player-x'
            },
            {
              'partieId': 'b',
              'remoteVersion': '2',
              'lastPushAt': null,
              'lastPullAt': '2024-01-02T00:00:00Z'
            }
          ]));
          await req.response.close();
          return;
        }
        req.response.statusCode = 404; await req.response.close();
      });
      final base = _uriFor(server, '');
      final port = HttpCloudPersistencePort(
        baseUrl: base.toString(),
        playerIdProvider: () async => 'player-x',
      );
      final list = await port.listParties();
      expect(list.length, 2);
      expect(list.first.partieId, 'a');
      expect(list.first.remoteVersion, 1);
      expect(list.first.lastPushAt, isNotNull);
      expect(list[1].partieId, 'b');
      expect(list[1].remoteVersion, 2);
      expect(list[1].lastPullAt, isNotNull);
      await server.close(force: true);
    });
  });
}

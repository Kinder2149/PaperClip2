import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/backend/backend_health_service.dart';

void main() {
  group('BackendHealthService', () {
    late HttpServer server;
    late Uri baseUri;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUri = Uri.parse('http://${server.address.host}:${server.port}');
      // Simple router
      unawaited(() async {
        await for (final req in server) {
          if (req.method == 'GET' && req.uri.path == '/health') {
            req.response.statusCode = 200;
            req.response.headers.contentType = ContentType.json;
            req.response.write(jsonEncode({'status': 'ok'}));
            await req.response.close();
          } else {
            req.response.statusCode = 404;
            await req.response.close();
          }
        }
      }());
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('returns true when /health -> 200 {status: ok}', () async {
      final svc = BackendHealthService(baseUrl: baseUri.toString());
      final ok = await svc.checkHealth();
      expect(ok, isTrue);
    });

    test('returns false when server down or timeout', () async {
      await server.close(force: true);
      final svc = BackendHealthService(baseUrl: baseUri.toString(), timeout: const Duration(milliseconds: 200));
      final ok = await svc.checkHealth();
      expect(ok, isFalse);
    });
  });
}

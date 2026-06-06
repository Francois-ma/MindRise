import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindrise_mobile/core/network/api_client.dart';
import 'package:mindrise_mobile/core/network/auth_session_events.dart';

void main() {
  group('JWT expiry detection', () {
    final now = DateTime.utc(2026, 6, 6, 12);

    test('accepts an access token with enough remaining lifetime', () {
      final token = _token(exp: now.millisecondsSinceEpoch ~/ 1000 + 120);

      expect(isJwtExpiring(token, now: now), isFalse);
    });

    test('refreshes a token near expiry', () {
      final token = _token(exp: now.millisecondsSinceEpoch ~/ 1000 + 20);

      expect(isJwtExpiring(token, now: now), isTrue);
    });

    test('refreshes malformed tokens', () {
      expect(isJwtExpiring('not-a-jwt', now: now), isTrue);
    });
  });

  test('session expiry events notify authentication listeners', () async {
    final events = AuthSessionEvents();
    final notification = events.expired.first;

    events.notifyExpired();

    await expectLater(notification, completes);
    events.dispose();
  });
}

String _token({required int exp}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'none'})}.${encode({'exp': exp})}.';
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_hbb/mobile/personal_android_update.dart';

Map<String, dynamic> manifest(String version) => {
      'schema': 1,
      'package_id': personalAndroidPackage,
      'version': version,
      'download_url': personalUpdateDownloadUrl,
    };

void main() {
  test(
      'only newer personal releases prompt; version numbers compare numerically',
      () {
    for (final version in ['1.5.1-kyk.10', '1.5.2-kyk.1']) {
      final update = PersonalAndroidUpdate.parse(
          jsonEncode(manifest(version)), '1.5.1-kyk.9');
      expect(update?.version, version);
      expect(update?.downloadUrl.toString(), personalUpdateDownloadUrl);
    }
    for (final version in [
      '1.5.1-kyk.9',
      '1.5.1-kyk.8',
      '1.5.0-kyk.99',
      '1.5.2'
    ]) {
      expect(
          PersonalAndroidUpdate.parse(
              jsonEncode(manifest(version)), '1.5.1-kyk.9'),
          isNull);
    }
  });

  test('missing, foreign, or redirected release data cannot offer an update',
      () {
    for (final data in [
      <String, dynamic>{},
      {...manifest('1.5.1-kyk.10'), 'package_id': 'other'},
      {
        ...manifest('1.5.1-kyk.10'),
        'download_url': 'https://example.com/app.apk'
      },
      {...manifest('1.5.1-kyk.10'), 'version': 10}
    ]) {
      expect(
          PersonalAndroidUpdate.parse(jsonEncode(data), '1.5.1-kyk.9'), isNull);
    }
    expect(() => PersonalAndroidUpdate.parse('broken', '1.5.1-kyk.9'),
        throwsFormatException);
  });

  test(
      'startup check handles missing release and propagates offline/malformed results to caller',
      () async {
    final ok = MockClient(
        (_) async => http.Response(jsonEncode(manifest('1.5.1-kyk.10')), 200));
    expect((await fetchPersonalAndroidUpdate(ok, '1.5.1-kyk.9'))?.version,
        '1.5.1-kyk.10');
    final missing = MockClient((_) async => http.Response('', 404));
    expect(await fetchPersonalAndroidUpdate(missing, '1.5.1-kyk.9'), isNull);
    final broken = MockClient((_) async => http.Response('broken', 200));
    await expectLater(fetchPersonalAndroidUpdate(broken, '1.5.1-kyk.9'),
        throwsFormatException);
    final offline =
        MockClient((_) async => throw http.ClientException('offline'));
    await expectLater(fetchPersonalAndroidUpdate(offline, '1.5.1-kyk.9'),
        throwsA(isA<http.ClientException>()));
  });
}

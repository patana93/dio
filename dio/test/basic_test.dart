@TestOn('vm')
import 'dart:async';
import 'dart:io';

import 'package:diox/diox.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';

void main() {
  test('test headers', () {
    final headers = Headers.fromMap({
      'set-cookie': ['k=v', 'k1=v1'],
      'content-length': ['200'],
      'test': ['1', '2'],
    });
    headers.add('SET-COOKIE', 'k2=v2');
    expect(headers.value('content-length'), '200');
    expect(Future(() => headers.value('test')), throwsException);
    expect(headers['set-cookie']?.length, 3);
    headers.remove('set-cookie', 'k=v');
    expect(headers['set-cookie']?.length, 2);
    headers.removeAll('set-cookie');
    expect(headers['set-cookie'], isNull);
    final ls = [];
    headers.forEach((k, list) => ls.addAll(list));
    expect(ls.length, 3);
    expect(headers.toString(), 'content-length: 200\ntest: 1\ntest: 2\n');
    headers.set('content-length', '300');
    expect(headers.value('content-length'), '300');
    headers.set('content-length', ['400']);
    expect(headers.value('content-length'), '400');

    final headers1 = Headers();
    headers1.set('xx', 'v');
    expect(headers1.value('xx'), 'v');
    headers1.clear();
    expect(headers1.map.isEmpty, isTrue);
  });

  test('send with an invalid URL', () async {
    await expectLater(
      Dio().get('http://http.invalid'),
      throwsA((e) => e is DioError && e.error is SocketException),
    );
  }, testOn: "vm");

  test('cancellation', () async {
    final dio = Dio();
    final token = CancelToken();
    Future.delayed(const Duration(milliseconds: 10), () {
      token.cancel('cancelled');
      dio.httpClientAdapter.close(force: true);
    });

    final url = 'https://pub.dev';
    await expectLater(
      dio.get(url, cancelToken: token),
      throwsA((e) => e is DioError && CancelToken.isCancel(e)),
    );
  });

  test('status error', () async {
    final dio = Dio()
      ..options.baseUrl = EchoAdapter.mockBase
      ..httpClientAdapter = EchoAdapter();
    await expectLater(
      dio.get('/401'),
      throwsA((e) =>
          e is DioError &&
          e.type == DioErrorType.badResponse &&
          e.response!.statusCode == 401),
    );
    final r = await dio.get(
      '/401',
      options: Options(validateStatus: (status) => true),
    );
    expect(r.statusCode, 401);
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;

/// Opens a POST SSE connection. On web, [http.Client] streams line-by-line;
/// Dio's web adapter buffers the full body unless we avoid it.
Stream<String> openSsePostLineStream({
  required Future<String?> Function() resolveToken,
  required String baseUrl,
  required String path,
  required Map<String, dynamic> body,
  required Map<String, String> extraHeaders,
  CancelToken? cancelToken,
  required Future<Response<dynamic>> Function(
    String path,
    Map<String, dynamic> data,
    CancelToken? cancelToken,
    Map<String, String> headers,
  ) dioPostStream,
}) {
  if (kIsWeb) {
    return _webSseLines(
      resolveToken: resolveToken,
      baseUrl: baseUrl,
      path: path,
      body: body,
      extraHeaders: extraHeaders,
      cancelToken: cancelToken,
    );
  }
  return _dioSseLines(
    path: path,
    body: body,
    extraHeaders: extraHeaders,
    cancelToken: cancelToken,
    dioPostStream: dioPostStream,
  );
}

Stream<String> _webSseLines({
  required Future<String?> Function() resolveToken,
  required String baseUrl,
  required String path,
  required Map<String, dynamic> body,
  required Map<String, String> extraHeaders,
  CancelToken? cancelToken,
}) async* {
  final client = http.Client();

  cancelToken?.whenCancel.then((_) {
    client.close();
  });

  try {
    final token = await resolveToken();
    final uri = AppConstants.apiUri(path);
    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      ...extraHeaders,
    });
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.body = json.encode(body);

    if (kDebugMode) {
      print('[CHAT_STREAM] web SSE POST $uri');
    }

    final response = await client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errText = await response.stream.bytesToString();
      if (kDebugMode) {
        print('[CHAT_STREAM] web error ${response.statusCode} $uri body=$errText');
      }
      throw DioException(
        requestOptions: RequestOptions(path: uri.toString()),
        response: Response(
          requestOptions: RequestOptions(path: uri.toString()),
          statusCode: response.statusCode,
          data: errText,
        ),
        type: DioExceptionType.badResponse,
        message: 'Chat stream failed (${response.statusCode}) for $uri',
      );
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    var lineIndex = 0;
    await for (final line in lines) {
      if (cancelToken?.isCancelled == true) break;
      lineIndex++;
      if (kDebugMode && lineIndex <= 5) {
        print('[CHAT_STREAM] web line#$lineIndex len=${line.length}');
      }
      yield line;
    }

    if (kDebugMode) {
      print('[CHAT_STREAM] web done lines=$lineIndex');
    }
  } finally {
    client.close();
  }
}

Stream<String> _dioSseLines({
  required String path,
  required Map<String, dynamic> body,
  required Map<String, String> extraHeaders,
  CancelToken? cancelToken,
  required Future<Response<dynamic>> Function(
    String path,
    Map<String, dynamic> data,
    CancelToken? cancelToken,
    Map<String, String> headers,
  ) dioPostStream,
}) async* {
  final response = await dioPostStream(path, body, cancelToken, extraHeaders);
  if (response.data is! ResponseBody) return;

  final byteStream = (response.data as ResponseBody).stream;
  var lineIndex = 0;
  await for (final line
      in utf8.decoder.bind(byteStream).transform(const LineSplitter())) {
    if (cancelToken?.isCancelled == true) break;
    lineIndex++;
    if (kDebugMode && lineIndex <= 5) {
      print('[CHAT_STREAM] dio line#$lineIndex len=${line.length}');
    }
    yield line;
  }
  if (kDebugMode) {
    print('[CHAT_STREAM] dio done lines=$lineIndex');
  }
}

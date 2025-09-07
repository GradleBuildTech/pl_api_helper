import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../base/token_base.dart';

class TokenHttpClient extends BaseTokenInterceptor with http.BaseClient {
  final http.Client inner;

  TokenHttpClient({
    required this.inner,
    super.refreshEndpoint,
    super.refreshPayloadBuilder,
    super.refreshResponseParser,
    super.onUnauthenticated,
    required super.tokenDelegate,
  });

  final List<Function()> _queue = [];
  bool _isRefreshing = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add Authorization header
    final accessToken = await tokenDelegate.getAccessToken();
    if (accessToken.isNotEmpty) {
      request.headers["Authorization"] = "Bearer $accessToken";
    }

    late http.StreamedResponse response;
    try {
      response = await inner.send(request);
    } catch (_) {
      rethrow;
    }
    final isAuthError =
        response.statusCode == HttpStatus.unauthorized ||
        response.statusCode == HttpStatus.forbidden;
    if (!isAuthError) return response;

    if (accessToken.isEmpty || refreshEndpoint == null) {
      return response;
    }
    if (_isRefreshing) {
      final completer = Completer<http.Response>();
      _queue.add(() async {
        try {
          final retriedRequest = http.Request(request.method, request.url)
            ..headers.addAll(request.headers)
            ..bodyBytes = await request.finalize().toBytes();
          final retriedResponse = await send(retriedRequest);
          completer.complete(http.Response.fromStream(retriedResponse));
        } catch (e) {
          completer.completeError(e);
        }
      });
      final data = await completer.future;
      final bytes = utf8.encode(data.body);
      final stream = http.ByteStream.fromBytes(bytes);
      return http.StreamedResponse(stream, data.statusCode, request: request);
    }
    _isRefreshing = true;
    try {
      final newAccessToken = await refreshToken();
      if (newAccessToken.isEmpty) {
        _isRefreshing = false;
        _queue.clear();
        return response;
      }
      //Retry the original request with the new token
      final retriedRequest = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..headers["Authorization "] = "Bearer $newAccessToken"
        ..bodyBytes = await request.finalize().toBytes();
      for (final task in _queue) {
        await task();
      }
      _queue.clear();
      _isRefreshing = false;
      response = await send(retriedRequest);

      return response;
    } catch (_) {
      _isRefreshing = false;
      _queue.clear();
      return response;
    }
  }

  @override
  Future<String> refreshToken() async {
    if (refreshEndpoint == null ||
        refreshEndpoint!.isEmpty ||
        refreshPayloadBuilder == null) {
      await tokenDelegate.deleteToken();
      return "";
    }
    final refreshToken = await tokenDelegate.getRefreshToken();
    if (refreshToken.isEmpty) {
      await tokenDelegate.deleteToken();
      return "";
    }
    final refreshPayload = refreshPayloadBuilder!(refreshToken);
    final uri = Uri.parse(refreshEndpoint!);
    try {
      final refreshResponse = await http.post(
        uri,
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode(refreshPayload),
      );
      if (refreshResponse.statusCode == 200) {
        final responseData = jsonDecode(refreshResponse.body);
        final (newAccessToken, newRefreshToken) =
            responseData?.call(responseData) ?? (null, null);

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await tokenDelegate.saveTokens(newAccessToken, newRefreshToken);
          return newAccessToken;
        } else {
          handleTokenClear();
        }
      } else {
        handleTokenClear();
      }
    } catch (_) {
      handleTokenClear();
    }
    return "";
  }
}

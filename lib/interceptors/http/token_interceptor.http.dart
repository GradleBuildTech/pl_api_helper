import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pl_api_helper/utils/logger.dart';

import '../base/token_base.dart';
import 'models/base_interceptors.dart';

class HttpTokenInterceptor extends BaseTokenInterceptor
    implements BaseInterceptor {
  final http.Client client;
  HttpTokenInterceptor({
    required this.client,
    required super.tokenDelegate,
    super.refreshEndpoint,
    super.refreshPayloadBuilder,
    super.refreshResponseParser,
    super.onUnauthenticated,
  });

  /// Indicates whether a token refresh is currently in progress.
  @override
  Future<void> onRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    try {
      final accessToken = await tokenDelegate.getAccessToken();
      if (accessToken.isEmpty) {
        return;
      }
      headers ??= {};
      headers["Authorization"] = "Bearer $accessToken";
    } catch (e) {
      Logger.d("TokenHttpClient", e.toString());
    }
  }

  /// Called when an error occurs during the request
  @override
  Future<http.StreamedResponse?> onError(Object error) async => null;

  /// Called after a response is received
  @override
  Future<void> onResponse(http.Response response) async {
    final statusCode = response.statusCode;
    final isAuthError = response.statusCode == HttpStatus.unauthorized ||
        response.statusCode == HttpStatus.forbidden;
    if (statusCode == HttpStatus.badGateway ||
        statusCode == HttpStatus.serviceUnavailable) {
      return;
    }
    if (!isAuthError) return;
    final accessToken = await tokenDelegate.getAccessToken();
    if (accessToken.isEmpty) {
      return;
    }

    final newAccessToken = await refreshToken();
    if (newAccessToken.isEmpty) {
      return;
    }

    final completer = Completer<http.Response>();
    try {
      final retriedRequest =
          http.Request(response.request!.method, response.request!.url)
            ..headers.addAll(response.request!.headers)
            ..bodyBytes = await response.request!.finalize().toBytes();
      final retriedResponse = await client.send(retriedRequest);
      completer.complete(http.Response.fromStream(retriedResponse));
    } catch (e) {
      completer.completeError(e);
    }
    final data = await completer.future;
    response = data;
    return;
  }

  /// Refreshes the access token using the refresh token.
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

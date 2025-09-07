import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../delegation/token_delegation.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor({
    required String baseUrl,
    String? refreshEndpoint,
    Map<String, dynamic> Function(String token)? refreshPayloadBuilder,
    required TokenDelegation tokenDelegate,
    Function()? onUnauthenticated,
  }) : _tokenDelegate = tokenDelegate,
       _onUnauthenticated = onUnauthenticated,
       _baseUrl = baseUrl,
       _refreshEndpoint = refreshEndpoint,
       _refreshPayloadBuilder = refreshPayloadBuilder;

  final TokenDelegation _tokenDelegate;

  final Function()? _onUnauthenticated;

  final String _baseUrl;

  final String? _refreshEndpoint;

  final Map<String, dynamic> Function(String token)? _refreshPayloadBuilder;

  bool _isRefreshing = false;

  final List<Function()> _queue = [];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var accessToken = await _tokenDelegate.getAccessToken();
    if (accessToken.isEmpty) {
      return handler.next(options);
    }

    options.headers["Authorization"] = "Bearer $accessToken";
    return handler.next(options);
  }

  @override
  // ignore: deprecated_member_use
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final isAuthError =
        statusCode == HttpStatus.unauthorized ||
        statusCode == HttpStatus.forbidden;

    /// Handle display of maintenance pop-up
    if (statusCode == HttpStatus.badGateway ||
        statusCode == HttpStatus.serviceUnavailable ||
        statusCode == null) {
      if (statusCode == HttpStatus.serviceUnavailable) {}

      return handler.next(err);
    }

    if (!isAuthError) return handler.next(err);

    final accessToken = await _tokenDelegate.getAccessToken();
    if (accessToken.isEmpty) {
      return handler.next(err);
    }

    final options = err.response!.requestOptions;

    // If the request is already being retried, queue it
    if (_isRefreshing) {
      final completer = Completer<Response>();
      _queue.add(() async {
        try {
          options.headers["Authorization"] =
              "Bearer ${await _tokenDelegate.getAccessToken()}";
          final response = await Dio().fetch(options);
          completer.complete(response);
        } catch (e) {
          completer.completeError(e);
        }
      });
      return handler.resolve(await completer.future);
    }

    _isRefreshing = true;

    try {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken.isEmpty) {
        _isRefreshing = false;
        _queue.clear();
        return handler.next(err); // Failed refresh
      }

      options.headers["Authorization"] = "Bearer $newAccessToken";
      final retryResponse = await Dio().fetch(options);

      for (final req in _queue) {
        await req();
      }
      _queue.clear();
      _isRefreshing = false;

      return handler.resolve(retryResponse);
    } catch (e) {
      _isRefreshing = false;
      _queue.clear();
      return handler.next(err);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == HttpStatus.unauthorized ||
        response.statusCode == HttpStatus.forbidden) {
      _handleTokenClear();
    }
    return handler.next(response);
  }

  /// [_refreshAccessToken] will try to get a new access token using the refresh token.
  /// If successful, it will save the new access token and return it.
  /// If the refresh token is invalid or expired, it will clear the tokens and return an empty string.
  /// If the refresh token is not available, it will also clear the tokens and return an empty string.
  /// If any error occurs during the request, it will clear the tokens
  Future<String> _refreshAccessToken() async {
    if (_refreshEndpoint == null ||
        _refreshEndpoint.isEmpty ||
        _refreshPayloadBuilder == null) {
      _handleTokenClear();
      return "";
    }
    final refreshToken = await _tokenDelegate.getRefreshToken();
    if (refreshToken.isEmpty) {
      _handleTokenClear(emitUnauthenticated: false);
      return "";
    }

    final dio = Dio()
      ..options.baseUrl = _baseUrl
      ..options.connectTimeout = const Duration(seconds: 10)
      ..options.receiveTimeout = const Duration(seconds: 10)
      ..interceptors.add(LogInterceptor());

    try {
      final response = await dio.post(
        _refreshEndpoint,
        data: _refreshPayloadBuilder(refreshToken),
      );
      if (response.statusCode == HttpStatus.ok) {
        final data = response.data;
        final newToken = data["data"]?["accessToken"] as String?;
        final newFreshToken = data["data"]?["refreshToken"] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          await _tokenDelegate.saveAccessToken(newToken);
          await _tokenDelegate.saveRefreshToken(newFreshToken ?? "");
          return newToken;
        }
      }
      _handleTokenClear();
    } catch (_) {
      _handleTokenClear();
    }

    return "";
  }

  void _handleTokenClear({bool emitUnauthenticated = true}) async {
    await _tokenDelegate.deleteToken();
    if (emitUnauthenticated) {
      _onUnauthenticated?.call();
    }
  }
}

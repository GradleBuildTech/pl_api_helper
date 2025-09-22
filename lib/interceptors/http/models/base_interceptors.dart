import 'package:http/http.dart' as http;

/// Base class for HTTP interceptors
/// Allows modification of requests, responses, and error handling
abstract class BaseInterceptor {
  /// Called before a request is sent
  Future<void> onRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {}

  /// Called after a response is received
  Future<void> onResponse(http.Response response) async {}

  /// Called when an error occurs during the request
  Future<http.StreamedResponse?> onError(Object error) async => null;
}

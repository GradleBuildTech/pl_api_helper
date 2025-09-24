import 'package:http/http.dart' as http;

/// [BaseInterceptor] - Abstract base class for HTTP interceptors
///
/// This class provides the foundation for creating custom HTTP interceptors
/// that can modify requests, responses, and handle errors.
///
/// Key features:
/// - Request modification before sending
/// - Response processing after receiving
/// - Error handling and recovery
/// - Chainable interceptor support
///
/// Usage:
/// Extend this class and override the methods you need to implement
/// your custom interceptor logic.
abstract class BaseInterceptor {
  /// Called before a request is sent
  ///
  /// This method is invoked before the HTTP request is sent to the server.
  /// You can modify headers, query parameters, or request body here.
  ///
  /// Parameters:
  /// - [method]: HTTP method (GET, POST, PUT, DELETE)
  /// - [url]: Request URL
  /// - [headers]: Request headers (can be modified)
  /// - [queryParameters]: Query parameters (can be modified)
  /// - [body]: Request body (can be modified)
  Future<void> onRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {}

  /// Called after a response is received
  ///
  /// This method is invoked after the HTTP response is received from the server.
  /// You can process the response, extract data, or perform additional operations.
  ///
  /// Parameters:
  /// - [response]: HTTP response object
  Future<void> onResponse(http.Response response) async {}

  /// Called when an error occurs during the request
  ///
  /// This method is invoked when an error occurs during the HTTP request.
  /// You can handle the error, provide fallback responses, or perform recovery actions.
  ///
  /// Parameters:
  /// - [error]: The error that occurred
  ///
  /// Returns: Optional StreamedResponse to use as fallback, or null to propagate error
  Future<http.StreamedResponse?> onError(Object error) async => null;
}

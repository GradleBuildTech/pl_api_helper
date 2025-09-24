part of 'helper.dart';

/// [HttpHelper] - Standard HTTP client implementation of ApiHelper
///
/// This is a singleton class that provides HTTP client functionality using the standard `http` package.
/// It's a lightweight alternative to DioApiHelper, suitable for simple HTTP requests.
///
/// Key features:
/// - Standard HTTP client from the `http` package
/// - Singleton pattern for global access
/// - Support for all HTTP methods (GET, POST, PUT, DELETE)
/// - Request/response interceptors
/// - Automatic response parsing and error handling
/// - Cache integration for GET requests
/// - Timeout configuration
class HttpHelper extends ApiHelper {
  /// Singleton instance of HttpHelper
  static HttpHelper? _instance;

  /// The underlying HTTP client from the `http` package
  final http.Client _client = http.Client();

  /// Base URL for API requests
  String? _baseUrl;

  /// Default headers to include with all requests
  Map<String, String> _defaultHeaders = {};

  /// Request timeout duration
  Duration _timeout = const Duration(seconds: 30);

  /// Private constructor for singleton pattern
  HttpHelper._();

  /// Factory constructor to initialize the singleton instance
  ///
  /// Parameters:
  /// - [apiConfig]: API configuration object (optional)
  /// - [baseUrl]: Base URL for API requests (optional)
  ///
  /// Returns: HttpHelper singleton instance
  factory HttpHelper.init({ApiConfig? apiConfig, String? baseUrl}) {
    _instance ??= HttpHelper._();
    _instance?._baseUrl = baseUrl ?? apiConfig?.baseUrl;
    _instance?._defaultHeaders = apiConfig?.defaultHeaders ?? {};
    _instance?._timeout = apiConfig?.timeout ?? const Duration(seconds: 30);

    return _instance!;
  }

  /// Get the singleton instance
  ///
  /// Throws an exception if the instance hasn't been initialized yet.
  ///
  /// Returns: HttpHelper singleton instance
  ///
  /// Throws: Exception if not initialized
  static HttpHelper get instance {
    if (_instance == null) {
      throw Exception("HttpHelper is not initialized");
    }
    return _instance!;
  }

  /// List of registered interceptors for request/response modification
  final List<BaseInterceptor> _interceptors = [];

  /// Add an interceptor to the HTTP client
  ///
  /// Interceptors can be used to modify requests and responses,
  /// add authentication headers, handle errors, etc.
  ///
  /// Parameters:
  /// - [client]: Base interceptor to add
  void addInterceptor(BaseInterceptor client) {
    _interceptors.add(client);
  }

  @override
  Future<void> handleHttpResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    for (var interceptor in _interceptors) {
      await interceptor.onError(response);
    }
    throw ApiError.fromHttp(response);
  }

  /// Executes an HTTP request based on the provided method, URL, headers, query parameters, and request body.
  @override
  Future<T> executeRequest<T>({
    required ApiMethod method,
    required String url,
    CacheConfig? cacheConfig,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? request,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  }) async {
    var headers = _defaultHeaders;
    for (var interceptor in _interceptors) {
      await interceptor.onRequest(
        method: method.name,
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        body: request,
      );
    }

    final requestHeader = {'Content-Type': 'application/json', ...headers};

    final buildUrl = ApiHelper.buildUrl(
      path: url,
      baseUrl: _baseUrl,
      queryParameters: queryParameters,
    );
    if (buildUrl.isEmpty) {
      throw Exception("Base URL is not set");
    }

    ///Build request
    http.Response response;
    try {
      switch (method) {
        case ApiMethod.get:
          final uri = Uri.parse(buildUrl);
          response =
              await _client.get(uri, headers: requestHeader).timeout(_timeout);
          break;
        case ApiMethod.post:
          final uri = Uri.parse(buildUrl);
          response = await _client
              .post(
                uri,
                headers: requestHeader,
                body: request != null ? jsonEncode(request) : null,
              )
              .timeout(_timeout);
          break;
        case ApiMethod.put:
          final uri = Uri.parse(buildUrl);
          response = await _client
              .put(
                uri,
                headers: requestHeader,
                body: request != null ? jsonEncode(request) : null,
              )
              .timeout(_timeout);
          break;
        case ApiMethod.delete:
          final uri = Uri.parse(buildUrl);
          response = await _client
              .delete(
                uri,
                headers: requestHeader,
                body: request != null ? jsonEncode(request) : null,
              )
              .timeout(_timeout);
          break;
      }
    } catch (e) {
      Logger.d("HttpHelper", e.toString());
      throw ApiError(type: ApiErrorType.unknown, message: e.toString());
    }
    for (var interceptor in _interceptors) {
      await interceptor.onResponse(response);
    }

    await handleHttpResponse(response);

    if (cacheConfig != null) {
      await cacherManager.setData(buildUrl, response.body, cacheConfig);
    }

    return await parseResponse<T>(
      mapper: mapper,
      responseBody: response.body,
      newThreadParse: newThreadParse,
    );
  }

  @override
  Future<T> parseResponse<T>({
    bool newThreadParse = true,
    String? responseBody,
    Map<String, dynamic>? jsonBody,
    required ApiResponseMapper<T> mapper,
  }) async {
    assert(
      responseBody != null || jsonBody != null,
      'Either responseBody or jsonBody must be provided',
    );
    if (responseBody != null) {
      final Map<String, dynamic> json = jsonDecode(responseBody);
      final apiResponse = newThreadParse
          ? await parseApiResponse<T>(json, (json) => mapper(json))
          : ApiResponse<T>.fromJson(
              json,
              (data) => mapper(data as Map<String, dynamic>),
            );
      return apiResponse.data;
    }

    final apiResponse = newThreadParse
        ? await parseApiResponse<T>(jsonBody!, (json) => mapper(json))
        : ApiResponse<T>.fromJson(
            jsonBody!,
            (data) => mapper(data as Map<String, dynamic>),
          );
    return apiResponse.data;
  }

  @override
  Future<T> uploadFile<T>({
    required String url,
    required File file,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  }) {
    throw UnimplementedError();
  }
}

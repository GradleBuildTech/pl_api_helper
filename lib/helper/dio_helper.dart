part of 'helper.dart';

/// [DioApiHelper] - Dio-based implementation of ApiHelper
///
/// This is a singleton class that provides HTTP client functionality using the Dio package.
/// Dio offers advanced features like interceptors, request/response transformation,
/// and better error handling compared to the standard HTTP client.
///
/// Usage example:
/// ```dart
/// Dio dio = Dio();
/// String baseUrl = 'https://api.example.com';
/// DioApiHelper apiHelper = DioApiHelper.init(dio: dio, baseUrl: baseUrl);
/// ```
///
/// Key features:
/// - Singleton pattern for global access
/// - Dio HTTP client with advanced features
/// - Automatic response parsing and error handling
/// - Cache integration for GET requests
/// - Interceptor support for request/response modification
class DioApiHelper extends ApiHelper {
  /// Singleton instance of DioApiHelper
  static DioApiHelper? _instance;

  /// Private constructor for singleton pattern
  ///
  /// Initializes the Dio client and base URL from provided parameters or ApiConfig
  DioApiHelper._({ApiConfig? apiConfig, Dio? dio, String? baseUrl}) {
    _dio = dio ?? apiConfig?.toDio();
    _baseUrl = baseUrl ?? apiConfig?.baseUrl;
  }

  /// Factory constructor to initialize the singleton instance
  ///
  /// Parameters:
  /// - [dio]: Dio HTTP client instance (optional)
  /// - [baseUrl]: Base URL for API requests (optional)
  /// - [cacherManager]: Cache manager instance (optional)
  ///
  /// Returns: DioApiHelper singleton instance
  factory DioApiHelper.init({
    Dio? dio,
    String? baseUrl,
    CacherManager? cacherManager,
  }) {
    _instance ??= DioApiHelper._(dio: dio, baseUrl: baseUrl);
    return _instance!;
  }

  /// Get the singleton instance
  ///
  /// Throws an exception if the instance hasn't been initialized yet.
  ///
  /// Returns: DioApiHelper singleton instance
  ///
  /// Throws: Exception if not initialized
  static DioApiHelper get instance {
    if (_instance == null) {
      throw Exception(
        'DioApiHelper is not initialized. Call DioApiHelper.init() first.',
      );
    }
    return _instance!;
  }

  /// Dio HTTP client instance
  Dio? _dio;

  /// Base URL for API requests
  String? _baseUrl;

  /// Add an interceptor to the Dio client
  ///
  /// Interceptors can be used to modify requests and responses,
  /// add authentication headers, handle errors, etc.
  ///
  /// Parameters:
  /// - [interceptor]: Dio interceptor to add
  void addInterceptor(Interceptor interceptor) {
    if (_dio != null) {
      _dio!.interceptors.add(interceptor);
    }
  }

  /// Upload a file to the server
  ///
  /// Currently not implemented in this version.
  /// This method is required by the ApiHelper interface.
  ///
  /// Parameters:
  /// - [url]: Endpoint URL for file upload
  /// - [file]: File to upload
  /// - [mapper]: Response data mapper function
  /// - [newThreadParse]: Parse response in separate isolate
  ///
  /// Returns: Future<T> - Parsed response data
  ///
  /// Throws: UnimplementedError
  @override
  Future<T> uploadFile<T>({
    required String url,
    required File file,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  }) {
    throw UnimplementedError();
  }

  /// Handle Dio response and validate status code
  ///
  /// This method validates the HTTP response status code and throws
  /// appropriate errors for non-successful responses.
  ///
  /// Parameters:
  /// - [response]: Dio response object
  ///
  /// Throws: ApiError if response indicates an error
  @override
  Future<void> handleDioResponse(Response response) async {
    final statusCode = response.statusCode;

    // Check if status code is null (shouldn't happen with Dio)
    if (statusCode == null) {
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Response status code is null',
      );
    }

    // Check if status code indicates success (200-299)
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    // Throw error for non-success status codes
    throw ApiError.fromDioResponse(response);
  }

  /// Parse HTTP response data into the desired object type
  ///
  /// This method handles the conversion of raw response data (JSON string or Map)
  /// into the desired object type using the provided mapper function.
  /// Supports both single-threaded and multi-threaded parsing.
  ///
  /// Parameters:
  /// - [newThreadParse]: Parse response in separate isolate to avoid blocking UI
  /// - [responseBody]: Raw response body as string
  /// - [jsonBody]: Pre-parsed JSON data as Map
  /// - [mapper]: Function to convert JSON to object type T
  ///
  /// Returns: Future<T> - Parsed object
  @override
  Future<T> parseResponse<T>({
    bool newThreadParse = true,
    String? responseBody,
    Map<String, dynamic>? jsonBody,
    required ApiResponseMapper<T> mapper,
  }) async {
    // Ensure at least one data source is provided
    assert(
      responseBody != null || jsonBody != null,
      'Either responseBody or jsonBody must be provided',
    );

    // Handle string response body
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

    // Handle pre-parsed JSON data
    final apiResponse = newThreadParse
        ? await parseApiResponse<T>(jsonBody!, (json) => mapper(json))
        : ApiResponse<T>.fromJson(
            jsonBody!,
            (data) => mapper(data as Map<String, dynamic>),
          );
    return apiResponse.data;
  }

  /// Execute HTTP request using Dio client
  ///
  /// This method performs the actual HTTP request using the configured Dio client.
  /// It handles request configuration, response validation, caching, and error handling.
  ///
  /// Parameters:
  /// - [method]: HTTP method (GET, POST, PUT, DELETE)
  /// - [url]: Endpoint URL
  /// - [cacheConfig]: Cache configuration for storing response
  /// - [queryParameters]: URL query parameters
  /// - [request]: Request body data
  /// - [mapper]: Response data mapper function
  /// - [newThreadParse]: Parse response in separate isolate
  ///
  /// Returns: Future<T> - Parsed response data
  ///
  /// Throws: ApiError for various error conditions
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
    // Validate that Dio client and base URL are configured
    if (_dio == null || _baseUrl == null) {
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Dio or baseUrl is null',
      );
    }

    try {
      // Configure request options
      const extra = <String, dynamic>{};
      final headers = <String, dynamic>{};
      dynamic data = request ?? {};

      // Execute the HTTP request using Dio
      final result = await _dio?.fetch<Map<String, dynamic>>(
        ApiHelper.setStreamType<T>(
          Options(method: method.name, headers: headers, extra: extra)
              .compose(
                _dio!.options,
                url,
                queryParameters: queryParameters,
                data: data,
              )
              .copyWith(
                baseUrl: ApiHelper.combineBaseUrls(
                  _dio!.options.baseUrl,
                  _baseUrl,
                ),
              ),
        ),
      );

      // Validate response
      if (result == null) {
        throw ApiError(
          type: ApiErrorType.unknown,
          message: 'Dio response is null',
        );
      }

      // Validate response status code
      await handleDioResponse(result);

      // Cache the response if caching is configured
      if (cacheConfig != null) {
        await cacherManager.setData(
          ApiHelper.buildUrl(path: url, queryParameters: queryParameters),
          jsonEncode(result.data),
          cacheConfig,
        );
      }

      // Parse and return the response data
      return await parseResponse<T>(mapper: mapper, jsonBody: result.data);
    } on DioException catch (e) {
      // Handle Dio-specific errors
      if (e.response != null) {
        await handleDioResponse(e.response!);
      }
      throw ApiError.fromDio(e);
    } on SocketException catch (e) {
      // Handle network connectivity errors
      throw ApiError(type: ApiErrorType.noInternet, message: e.message);
    } on TimeoutException catch (e) {
      // Handle request timeout errors
      throw ApiError(type: ApiErrorType.timeout, message: e.message);
    } catch (e) {
      // Handle any other unexpected errors
      throw ApiError(type: ApiErrorType.unknown, message: e.toString());
    }
  }
}

// Core Dart libraries for async operations and data handling
import 'dart:async'; // Async/await support and Future/Stream operations
import 'dart:convert'; // JSON encoding/decoding and data conversion
import 'dart:io'; // File operations for file uploads
import 'dart:isolate'; // Multi-threading support for response parsing

// HTTP client libraries
import 'package:dio/dio.dart'
    as dio; // Dio HTTP client (aliased to avoid conflicts)
import 'package:dio/dio.dart'; // Dio HTTP client
import 'package:http/http.dart' as http; // Alternative HTTP client

// Internal modules
import 'package:pl_api_helper/cache/cache.dart'; // Cache management system
import 'package:pl_api_helper/utils/method.dart'; // HTTP method definitions

import '../interceptors/http/models/base_interceptors.dart'; // Base interceptor classes
import '../models/models.dart'; // Data models and DTOs
import '../utils/logger.dart'; // Logging utilities

// Include helper implementations
part 'dio_helper.dart'; // Dio-based HTTP helper implementation
part 'http_helper.dart'; // Standard HTTP helper implementation

/// Type definition for response data mapping function
/// Generic type T allows mapping JSON response to any object type
/// This function takes raw JSON data and converts it to the desired model
typedef ApiResponseMapper<T> = T Function(Map<String, dynamic> data);

/// [ApiHelper] - Abstract base class for all API helper implementations
///
/// This is the foundation class that provides a common interface for making HTTP requests.
/// Specific implementations (DioApiHelper, HttpHelper) extend this class.
///
/// Key features:
/// - Support for HTTP methods: GET, POST, PUT, DELETE, UPLOAD
/// - Integrated cache system for GET requests
/// - Generic type support for response mapping
/// - Multi-threading support for response parsing
/// - Error handling and response validation
abstract class ApiHelper {
  /// Getter to access CacherManager singleton instance
  /// CacherManager handles caching for API requests to improve performance
  CacherManager get cacherManager => CacherManager.instance;

  /// [GET] - Fetch data from a REST API endpoint
  ///
  /// Performs an HTTP GET request to retrieve data from the server.
  /// Supports caching to optimize performance and reduce network calls.
  ///
  /// Parameters:
  /// - [url]: Endpoint URL (can be relative or absolute)
  /// - [mapper]: Function to convert JSON response to object type T
  /// - [cacheConfig]: Cache configuration (optional) - if null, no caching
  /// - [forceGet]: Skip cache and force fresh request from server
  /// - [queryParameters]: Query parameters for URL (optional)
  /// - [newThreadParse]: Parse response in separate isolate to avoid blocking UI thread
  ///
  /// Returns: Future<T> - Parsed response data
  Future<T> get<T>({
    required String url,
    required ApiResponseMapper<T> mapper,
    CacheConfig? cacheConfig,
    bool forceGet = false,
    Map<String, dynamic>? queryParameters,
    bool newThreadParse = true,
  }) async =>
      await _handleRequest<T>(
        method: ApiMethod.get,
        url: url,
        cacheConfig: cacheConfig,
        forceGet: forceGet,
        queryParameters: queryParameters,
        mapper: mapper,
        newThreadParse: newThreadParse,
      );

  /// [POST] - Send data to a REST API endpoint
  ///
  /// Performs an HTTP POST request to send data to the server.
  /// Typically used for creating new resources or submitting forms.
  ///
  /// Parameters:
  /// - [url]: Endpoint URL (can be relative or absolute)
  /// - [mapper]: Function to convert JSON response to object type T
  /// - [request]: Request body data (optional) - will be JSON encoded
  /// - [newThreadParse]: Parse response in separate isolate to avoid blocking UI thread
  ///
  /// Returns: Future<T> - Parsed response data
  Future<T> post<T>({
    required String url,
    required ApiResponseMapper<T> mapper,
    Map<String, dynamic>? request,
    bool newThreadParse = true,
  }) async =>
      await _handleRequest<T>(
        method: ApiMethod.post,
        url: url,
        request: request,
        mapper: mapper,
        newThreadParse: newThreadParse,
      );

  /// [PUT] - Update data at a REST API endpoint
  ///
  /// Performs an HTTP PUT request to update existing data on the server.
  /// Typically used for updating entire resources.
  ///
  /// Parameters:
  /// - [url]: Endpoint URL (can be relative or absolute)
  /// - [mapper]: Function to convert JSON response to object type T
  /// - [request]: Request body data (optional) - will be JSON encoded
  /// - [newThreadParse]: Parse response in separate isolate to avoid blocking UI thread
  ///
  /// Returns: Future<T> - Parsed response data
  Future<T> put<T>({
    required String url,
    required ApiResponseMapper<T> mapper,
    Map<String, dynamic>? request,
    bool newThreadParse = true,
  }) async =>
      await _handleRequest<T>(
        method: ApiMethod.put,
        url: url,
        request: request,
        mapper: mapper,
        newThreadParse: newThreadParse,
      );

  /// [DELETE] - Remove data from a REST API endpoint
  ///
  /// Performs an HTTP DELETE request to remove data from the server.
  /// Typically used for deleting resources.
  ///
  /// Parameters:
  /// - [url]: Endpoint URL (can be relative or absolute)
  /// - [mapper]: Function to convert JSON response to object type T
  /// - [request]: Request body data (optional) - will be JSON encoded
  /// - [newThreadParse]: Parse response in separate isolate to avoid blocking UI thread
  ///
  /// Returns: Future<T> - Parsed response data
  Future<T> delete<T>({
    required String url,
    required ApiResponseMapper<T> mapper,
    Map<String, dynamic>? request,
    bool newThreadParse = true,
  }) async =>
      await _handleRequest<T>(
        method: ApiMethod.delete,
        url: url,
        request: request,
        mapper: mapper,
        newThreadParse: newThreadParse,
      );

  /// [UPLOAD] - Upload a file to a REST API endpoint
  ///
  /// Performs a file upload request to send files to the server.
  /// Typically used for uploading images, documents, or other files.
  ///
  /// Parameters:
  /// - [url]: Endpoint URL (can be relative or absolute)
  /// - [file]: File object to upload
  /// - [mapper]: Function to convert JSON response to object type T
  /// - [newThreadParse]: Parse response in separate isolate to avoid blocking UI thread
  ///
  /// Returns: Future<T> - Parsed response data
  Future<T> uploadFile<T>({
    required String url,
    required File file,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  });

  /// Internal method to handle request logic and caching
  ///
  /// This method implements the core request handling logic:
  /// 1. For GET requests with caching enabled, check cache first
  /// 2. If cached data exists and is valid, return it immediately
  /// 3. If no cached data or method is not GET, execute the actual request
  /// 4. Cache the response if caching is configured
  ///
  /// Parameters:
  /// - [method]: HTTP method (GET, POST, PUT, DELETE)
  /// - [url]: Endpoint URL
  /// - [forceGet]: Skip cache and force fresh request
  /// - [cacheConfig]: Cache configuration
  /// - [queryParameters]: URL query parameters
  /// - [request]: Request body data
  /// - [file]: File to upload (for upload requests)
  /// - [mapper]: Response data mapper function
  /// - [newThreadParse]: Parse response in separate isolate
  ///
  /// Returns: Future<T> - Parsed response data
  Future<T> _handleRequest<T>({
    required ApiMethod method,
    required String url,
    bool forceGet = false,
    CacheConfig? cacheConfig,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? request,
    File? file,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  }) async {
    // Build complete URL with query parameters
    final buildUrl = ApiHelper.buildUrl(
      path: url,
      queryParameters: queryParameters,
    );

    // Check cache for GET requests if caching is enabled and not forcing fresh data
    if (method == ApiMethod.get && !forceGet && cacheConfig != null) {
      final cacheData = await cacherManager.getData(buildUrl);
      if (cacheData != null) {
        // Return cached data if available
        return parseResponse(responseBody: cacheData, mapper: mapper);
      }
    }

    // Execute the actual HTTP request
    return await executeRequest<T>(
      method: method,
      url: url,
      cacheConfig: cacheConfig,
      queryParameters: queryParameters,
      request: request,
      mapper: mapper,
      newThreadParse: newThreadParse,
    );
  }

  /// Abstract method to execute the actual HTTP request
  ///
  /// This method must be implemented by subclasses to perform the request
  /// using a specific HTTP client (e.g., Dio, http).
  /// Each implementation handles the specifics of their HTTP client.
  ///
  /// Parameters:
  /// - [method]: HTTP method (GET, POST, PUT, DELETE)
  /// - [url]: Endpoint URL
  /// - [cacheConfig]: Cache configuration
  /// - [queryParameters]: URL query parameters
  /// - [request]: Request body data
  /// - [mapper]: Response data mapper function
  /// - [newThreadParse]: Parse response in separate isolate
  ///
  /// Returns: Future<T> - Parsed response data
  Future<T> executeRequest<T>({
    required ApiMethod method,
    required String url,
    CacheConfig? cacheConfig,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? request,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  });

  /// Parse HTTP response data into the desired object type
  ///
  /// This method handles the conversion of raw response data (JSON string or Map)
  /// into the desired object type using the provided mapper function.
  /// Supports multi-threading for large responses to avoid blocking the UI.
  ///
  /// Parameters:
  /// - [newThreadParse]: Parse response in separate isolate to avoid blocking UI
  /// - [responseBody]: Raw response body as string
  /// - [jsonBody]: Pre-parsed JSON data as Map
  /// - [mapper]: Function to convert JSON to object type T
  ///
  /// Returns: Future<T> - Parsed object
  Future<T> parseResponse<T>({
    bool newThreadParse = true,
    String? responseBody,
    Map<String, dynamic>? jsonBody,
    required ApiResponseMapper<T> mapper,
  });

  /// Handle HTTP response for standard HTTP client
  ///
  /// This method is called after receiving a response from the HTTP client.
  /// It handles response validation and error checking.
  ///
  /// Parameters:
  /// - [response]: HTTP response object from the http package
  ///
  /// Throws: ApiError if response indicates an error
  Future<void> handleHttpResponse(http.Response response) async {}

  /// Handle Dio response for Dio HTTP client
  ///
  /// This method is called after receiving a response from the Dio client.
  /// It handles response validation and error checking.
  ///
  /// Parameters:
  /// - [response]: Dio response object
  ///
  /// Throws: ApiError if response indicates an error
  Future<void> handleDioResponse(dio.Response response) async {}

  /// Configure Dio request options based on expected response type
  ///
  /// This static method automatically sets the appropriate response type
  /// for Dio requests based on the generic type T.
  ///
  /// Parameters:
  /// - [requestOptions]: Dio request options to configure
  ///
  /// Returns: Configured request options
  static dio.RequestOptions setStreamType<T>(
    dio.RequestOptions requestOptions,
  ) {
    // Only configure response type if not already set to bytes or stream
    if (T != dynamic &&
        !(requestOptions.responseType == dio.ResponseType.bytes ||
            requestOptions.responseType == dio.ResponseType.stream)) {
      if (T == String) {
        // For String type, expect plain text response
        requestOptions.responseType = dio.ResponseType.plain;
      } else {
        // For other types, expect JSON response
        requestOptions.responseType = dio.ResponseType.json;
      }
    }
    return requestOptions;
  }

  /// Combine base URLs intelligently
  ///
  /// This method handles URL combination logic:
  /// - If baseUrl is null or empty, return dioBaseUrl
  /// - If baseUrl is absolute, return it as-is
  /// - If baseUrl is relative, resolve it against dioBaseUrl
  ///
  /// Parameters:
  /// - [dioBaseUrl]: Primary base URL from Dio configuration
  /// - [baseUrl]: Secondary base URL (can be null, relative, or absolute)
  ///
  /// Returns: Combined URL string
  static String combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    // Return primary URL if secondary is null or empty
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    // If absolute URL, return as-is
    if (url.isAbsolute) {
      return url.toString();
    }

    // Resolve relative URL against primary base URL
    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }

  /// Parse API response in a separate isolate for better performance
  ///
  /// This method uses Dart isolates to parse large JSON responses
  /// in a separate thread, preventing UI blocking.
  ///
  /// Parameters:
  /// - [json]: Raw JSON data as Map
  /// - [mapper]: Function to convert JSON to object type T
  ///
  /// Returns: Future<ApiResponse<T>> - Parsed API response
  Future<ApiResponse<T>> parseApiResponse<T>(
    Map<String, dynamic> json,
    ApiResponseMapper<T> mapper,
  ) async {
    // Create a receive port for isolate communication
    final p = ReceivePort();

    // Spawn isolate to parse JSON in background thread
    await Isolate.spawn((SendPort sendPort) {
      final result = ApiResponse<T>.fromJson(
        json,
        (inner) => mapper(inner as Map<String, dynamic>),
      );
      sendPort.send(result);
    }, p.sendPort);

    // Wait for and return the parsed result
    return await p.first as ApiResponse<T>;
  }

  /// Build complete URL from base URL, path, and query parameters
  ///
  /// This method constructs a complete URL by combining:
  /// - Base URL (optional)
  /// - Path (required)
  /// - Query parameters (optional)
  ///
  /// Handles URL formatting issues like duplicate slashes and proper query parameter encoding.
  ///
  /// Parameters:
  /// - [baseUrl]: Base URL (optional)
  /// - [path]: Endpoint path (required)
  /// - [queryParameters]: Query parameters as key-value pairs (optional)
  ///
  /// Returns: Complete URL string, or empty string if error occurs
  static String buildUrl({
    String? baseUrl,
    required String path,
    Map<String, dynamic>? queryParameters,
  }) {
    try {
      var url = "";

      // Remove trailing slash from base URL if present
      if (baseUrl?.endsWith('/') ?? false) {
        baseUrl = baseUrl!.substring(0, baseUrl.length - 1);
      }

      // Remove leading slash from path if present
      if (path.startsWith('/')) {
        path = path.substring(1);
      }

      // Combine base URL and path
      url = (baseUrl != null ? '$baseUrl/$path' : path);

      // Add query parameters if provided
      if (queryParameters != null && queryParameters.isNotEmpty) {
        for (var key in queryParameters.keys) {
          final value = queryParameters[key];
          if (value != null) {
            // Add parameter with proper separator
            if (url.contains('?')) {
              url = '$url&$key=$value';
            } else {
              url = '$url?$key=$value';
            }
          }
        }
      }

      return url;
    } catch (e) {
      // Return empty string if URL building fails
      return "";
    }
  }
}

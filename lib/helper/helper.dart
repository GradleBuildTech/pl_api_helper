import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';

import 'package:http/http.dart' as http;
import 'package:pl_api_helper/cache/cache.dart';
import 'package:pl_api_helper/utils/method.dart';

import '../models/models.dart';

part 'dio_helper.dart';

typedef ApiResponseMapper<T> = T Function(Map<String, dynamic> data);

///[ApiHelper] is a base class for API helpers.
/// It provides methods for making HTTP requests and parsing responses.
abstract class ApiHelper {
  CacherManager get cacherManager => CacherManager.instance;

  ///[GET]  Fetch data from a REST API endpoint.
  Future<T> get<T>({
    required String url,
    required ApiResponseMapper<T> mapper,
    CacheConfig? cacheConfig,
    bool forceGet = false,
    Map<String, dynamic>? queryParameters,
    bool newThreadParse = true,
  }) async => await _handleRequest<T>(
    method: ApiMethod.get,
    url: url,
    cacheConfig: cacheConfig,
    forceGet: forceGet,
    queryParameters: queryParameters,
    mapper: mapper,
    newThreadParse: newThreadParse,
  );

  ///[POST] Send data to a REST API endpoint.
  Future<T> post<T>({
    required String url,
    required ApiResponseMapper<T> mapper,
    Map<String, dynamic>? request,
    bool newThreadParse = true,
  }) async => await _handleRequest<T>(
    method: ApiMethod.post,
    url: url,
    request: request,
    mapper: mapper,
    newThreadParse: newThreadParse,
  );

  ///[PUT] Update data at a REST API endpoint.
  Future<T> put<T>({
    required String url,
    required ApiResponseMapper<T> mapper,
    Map<String, dynamic>? request,
    bool newThreadParse = true,
  }) async => await _handleRequest<T>(
    method: ApiMethod.put,
    url: url,
    request: request,
    mapper: mapper,
    newThreadParse: newThreadParse,
  );

  ///[DELETE] Remove data from a REST API endpoint.
  Future<T> delete<T>({
    required String url,
    required ApiResponseMapper<T> mapper,
    Map<String, dynamic>? request,
    bool newThreadParse = true,
  }) async => await _handleRequest<T>(
    method: ApiMethod.delete,
    url: url,
    request: request,
    mapper: mapper,
    newThreadParse: newThreadParse,
  );

  ///[UPLOAD] Upload a file to a REST API endpoint.
  Future<T> uploadFile<T>({
    required String url,
    required File file,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  });

  /// Handle the request and caching logic
  /// - If the method is GET and caching is enabled, it will first check the cache.
  /// If a cached response is found, it will be returned.
  /// - If no cached response is found or the method is not GET, it will execute
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
    final buildUrl = ApiHelper.buildUrl(
      path: url,

      queryParameters: queryParameters,
    );
    if (method == ApiMethod.get && !forceGet && cacheConfig != null) {
      final cacheData = await cacherManager.getData(buildUrl);
      if (cacheData != null) {
        return parseResponse(responseBody: cacheData, mapper: mapper);
      }
    }

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

  /// Execute the actual HTTP request.
  /// This method must be implemented by subclasses to perform the request
  /// using a specific HTTP client (e.g., Dio, http).
  Future<T> executeRequest<T>({
    required ApiMethod method,
    required String url,
    CacheConfig? cacheConfig,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? request,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  });

  Future<T> parseResponse<T>({
    bool newThreadParse = true,
    String? responseBody,
    Map<String, dynamic>? jsonBody,
    required ApiResponseMapper<T> mapper,
  });

  ///[Http support]
  Future<void> handleHttpResponse(http.Response response) async {}

  ///[Dio support]
  Future<void> handleDioResponse(dio.Response response) async {}

  static dio.RequestOptions setStreamType<T>(
    dio.RequestOptions requestOptions,
  ) {
    if (T != dynamic &&
        !(requestOptions.responseType == dio.ResponseType.bytes ||
            requestOptions.responseType == dio.ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = dio.ResponseType.plain;
      } else {
        requestOptions.responseType = dio.ResponseType.json;
      }
    }
    return requestOptions;
  }

  static String combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }

  Future<ApiResponse<T>> parseApiResponse<T>(
    Map<String, dynamic> json,
    ApiResponseMapper<T> mapper,
  ) async {
    final p = ReceivePort();

    await Isolate.spawn((SendPort sendPort) {
      final result = ApiResponse<T>.fromJson(
        json,
        (inner) => mapper(inner as Map<String, dynamic>),
      );
      sendPort.send(result);
    }, p.sendPort);

    return await p.first as ApiResponse<T>;
  }

  static String buildUrl({
    String? baseUrl,
    required String path,
    Map<String, dynamic>? queryParameters,
  }) {
    try {
      var url = "";
      if (baseUrl?.endsWith('/') ?? false) {
        baseUrl = baseUrl!.substring(0, baseUrl.length - 1);
      }
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      url = (baseUrl != null ? '$baseUrl/$path' : path);
      if (queryParameters != null && queryParameters.isNotEmpty) {
        for (var key in queryParameters.keys) {
          final value = queryParameters[key];
          if (value != null) {
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
      return "";
    }
  }
}

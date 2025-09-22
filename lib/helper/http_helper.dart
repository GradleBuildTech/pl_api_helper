import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pl_api_helper/cache/cache_config.dart';
import 'package:pl_api_helper/interceptors/http/models/base_interceptors.dart';
import 'package:pl_api_helper/utils/logger.dart';
import 'package:pl_api_helper/utils/method.dart';

import '../models/models.dart';
import 'helper.dart';

///[HttpHelper] is a singleton class for making HTTP requests using the `http` package.
/// It extends the [ApiHelper] class and implements methods for GET, POST, PUT, DELETE requests,
/// as well as handling responses and parsing data.
class HttpHelper extends ApiHelper {
  static HttpHelper? _instance;

  /// The underlying HTTP client from the `http` package.
  final http.Client _client = http.Client();

  String? _baseUrl;

  Map<String, String> _defaultHeaders = {};

  Duration _timeout = const Duration(seconds: 30);

  HttpHelper._();

  factory HttpHelper.init({ApiConfig? apiConfig, String? baseUrl}) {
    _instance ??= HttpHelper._();
    _instance?._baseUrl = baseUrl ?? apiConfig?.baseUrl;
    _instance?._defaultHeaders = apiConfig?.defaultHeaders ?? {};
    _instance?._timeout = apiConfig?.timeout ?? const Duration(seconds: 30);

    return _instance!;
  }

  static HttpHelper get instance {
    if (_instance == null) {
      throw Exception("HttpHelper is not initialized");
    }
    return _instance!;
  }

  final List<BaseInterceptor> _interceptors = [];

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
          response = await _client
              .get(uri, headers: requestHeader)
              .timeout(_timeout);
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

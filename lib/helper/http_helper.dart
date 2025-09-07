import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pl_api_helper/cache/cache_config.dart';
import 'package:pl_api_helper/utils/method.dart';

import '../models/models.dart';
import 'helper.dart';

class HttpHelper extends ApiHelper {
  static HttpHelper? _instance;

  final http.Client _client = http.Client();
  String? _baseUrl;
  Map<String, String> _defaultHeaders = {};
  Duration _timeout = const Duration(seconds: 30);
  bool Function(int?) _validateStatus = (status) =>
      status != null && status < 500;

  HttpHelper._({ApiConfig? apiConfig, String? baseUrl}) {
    _baseUrl = baseUrl ?? apiConfig?.baseUrl;
    _defaultHeaders = apiConfig?.defaultHeaders ?? {};
    _timeout = apiConfig?.timeout ?? const Duration(seconds: 30);
    _validateStatus =
        apiConfig?.validateStatus ?? (status) => status != null && status < 500;
  }

  void addInterceptor(http.BaseClient client) {}

  @override
  Future<T> executeRequest<T>({
    required ApiMethod method,
    required String url,
    CacheConfig? cacheConfig,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? request,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<T> pareseResponse<T>({
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
    } else if (jsonBody != null) {
      final apiResponse = newThreadParse
          ? await parseApiResponse<T>(jsonBody, (json) => mapper(json))
          : ApiResponse<T>.fromJson(
              jsonBody,
              (data) => mapper(data as Map<String, dynamic>),
            );
      return apiResponse.data;
    } else {
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Both responseBody and jsonBody are null',
      );
    }
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

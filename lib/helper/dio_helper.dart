part of 'helper.dart';

///[Singleton]
/// Dio implementation of [ApiHelper]
/// Requires an instance of [Dio] and a base URL to be provided during initialization.
/// If not provided, they must be set before making any requests.
/// ```dart
/// Dio dio = Dio();
/// String baseUrl = 'https://api.example.com';
/// DioApiHelper apiHelper = DioApiHelper(dio: dio, baseUrl: base
/// Url);
/// ```
class DioApiHelper extends ApiHelper {
  static DioApiHelper? _instance;

  DioApiHelper._({ApiConfig? apiConfig, Dio? dio, String? baseUrl}) {
    _dio = dio ?? apiConfig?.toDio();
    _baseUrl = baseUrl ?? apiConfig?.baseUrl;
  }

  factory DioApiHelper.init({
    Dio? dio,
    String? baseUrl,
    CacherManager? cacherManager,
  }) {
    _instance ??= DioApiHelper._(dio: dio, baseUrl: baseUrl);
    return _instance!;
  }

  static DioApiHelper get instance {
    if (_instance == null) {
      throw Exception(
        'DioApiHelper is not initialized. Call DioApiHelper.init() first.',
      );
    }
    return _instance!;
  }

  Dio? _dio;
  String? _baseUrl;

  void addInterceptor(Interceptor interceptor) {
    if (_dio != null) {
      _dio!.interceptors.add(interceptor);
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

  @override
  Future<void> handleDioResponse(Response response) async {
    final statudCode = response.statusCode;
    if (statudCode == null) {
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Response status code is null',
      );
    }
    if (statudCode >= 200 && statudCode < 300) {
      return;
    }
    throw ApiError.fromDioResponse(response);
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
  Future<T> executeRequest<T>({
    required ApiMethod method,
    required String url,
    CacheConfig? cacheConfig,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? request,
    required ApiResponseMapper<T> mapper,
    bool newThreadParse = true,
  }) async {
    if (_dio == null || _baseUrl == null) {
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'Dio or baseUrl is null',
      );
    }
    try {
      const extra = <String, dynamic>{};
      final headers = <String, dynamic>{};

      dynamic data = request ?? {};
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
      if (result == null) {
        throw ApiError(
          type: ApiErrorType.unknown,
          message: 'Dio response is null',
        );
      }
      await handleDioResponse(result);

      if (cacheConfig != null) {
        await cacherManager.setData(
          ApiHelper.buildUrl(path: url, queryParameters: queryParameters),
          jsonEncode(result.data),
          cacheConfig,
        );
      }
      return await pareseResponse<T>(mapper: mapper, jsonBody: result.data);
    } on DioException catch (e) {
      if (e.response != null) {
        await handleDioResponse(e.response!);
      }
      throw ApiError.fromDio(e);
    } on SocketException catch (e) {
      throw ApiError(type: ApiErrorType.noInternet, message: e.message);
    } on TimeoutException catch (e) {
      throw ApiError(type: ApiErrorType.timeout, message: e.message);
    } catch (e) {
      throw ApiError(type: ApiErrorType.unknown, message: e.toString());
    }
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';

import '../../cache/cache.dart';
import '../../utils/constnants.dart';
import '../../utils/method.dart';

extension _X on Map<ApiMethod, Set<String>> {
  bool compareWithRequest(RequestOptions options) {
    final paths = this[ApiMethod.fromString(options.method)];
    if (paths == null) return false;
    return paths.contains(options.path);
  }
}

/// Interceptor for caching API responses
/// Uses CacherManager to store and retrieve cached data
/// Supports GET requests caching based on specified paths and methods
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(
///   CacheInterceptor(
///     dio: dio,
///     cachingPaths: {
///       ApiMethod.GET: {'/api/data', '/api/info'},
///     },
///     cacheConfig: CacheConfig(
///       duration: Duration(minutes: 10),
///       useMemoryCache: true,
///       useDiskCache: true,
///     ),
///   ),
/// );
/// ```
class CacheInterceptor extends Interceptor {
  final Dio dio;
  final Duration defaultCacheDuration;
  final Map<ApiMethod, Set<String>> cachingPaths;
  final CacheConfig cacheConfig;

  CacheInterceptor({
    this.cacheConfig = kDefaultCacheConfig,
    this.cachingPaths = const {},
    this.defaultCacheDuration = const Duration(minutes: 5),
    required this.dio,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final cacheKey = _generateCacheKey(options);
    final isCachable = cachingPaths.compareWithRequest(options);
    if (isCachable) {
      final cachedData = await CacherManager.instance.getData(cacheKey);
      if (cachedData != null) {
        try {
          final data = jsonDecode(cachedData);
          return handler.resolve(
            Response(requestOptions: options, data: data, statusCode: 200),
          );
        } catch (_) {
          // ignore error and continue with the request
        }
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final cacheKey = _generateCacheKey(response.requestOptions);
    final isCachable = cachingPaths.compareWithRequest(response.requestOptions);
    if (isCachable && response.statusCode == 200) {
      await CacherManager.instance.setData(
        cacheKey,
        jsonEncode(response.data),
        cacheConfig,
      );
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final cacheKey = _generateCacheKey(err.requestOptions);
    final cachedData = await CacherManager.instance.getData(cacheKey);

    if (cachedData != null) {
      try {
        final data = jsonDecode(cachedData);

        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: data,
            statusCode: 200,
          ),
        );
      } catch (_) {
        // ignore error and forward the original error
      }
    }

    return handler.next(err);
  }

  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    return uri;
  }
}

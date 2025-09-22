import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../cache/cache.dart';
import '../../utils/constants.dart';
import '../../utils/method.dart';

/// HTTP Client with caching capabilities
/// Uses CacherManager to store and retrieve cached data
/// Supports GET requests caching based on specified paths and methods'
///```dart
/// final client = CacheHttpClient(
///  cachingPaths: {
///   ApiMethod.GET: {'/api/data', '/api/info'},
///  },
///   cacheConfig: CacheConfig(
///     duration: Duration(minutes: 10),
///     useMemoryCache: true,
///     useDiskCache: true,
///   ),
/// );
/// final response = await client.get(Uri.parse('https://example.com/api/data'));
///```
class CacheHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Map<ApiMethod, Set<String>> cachingPaths;
  final CacheConfig cacheConfig;

  CacheHttpClient({
    http.Client? inner,
    this.cachingPaths = const {},
    this.cacheConfig = kDefaultCacheConfig,
  }) : _inner = inner ?? http.Client();

  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final cacheKey = _generateCacheKey(request);
    final isCachable = _isCachable(request);

    if (isCachable) {
      final cachedData = await CacherManager.instance.getData(cacheKey);
      if (cachedData != null) {
        try {
          final bytes = utf8.encode(cachedData);
          final stream = http.ByteStream.fromBytes(bytes);
          return http.StreamedResponse(stream, 200, request: request);
        } catch (_) {}
      }
    }

    late http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (_) {
      final cachedData = await CacherManager.instance.getData(cacheKey);
      if (cachedData != null) {
        final bytes = utf8.encode(cachedData);
        final stream = http.ByteStream.fromBytes(bytes);
        return http.StreamedResponse(stream, 200, request: request);
      }
      rethrow;
    }

    if (isCachable && response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      await CacherManager.instance.setData(cacheKey, data, cacheConfig);
      final stream = http.ByteStream.fromBytes(utf8.encode(data));
      return http.StreamedResponse(
        stream,
        response.statusCode,
        request: request,
        headers: response.headers,
      );
    }

    return response;
  }

  bool _isCachable(http.BaseRequest request) {
    final method = ApiMethod.fromString(request.method);
    final paths = cachingPaths[method];
    if (paths == null) return false;
    return paths.contains(request.url.path);
  }

  String _generateCacheKey(http.BaseRequest request) {
    return request.url.toString();
  }
}

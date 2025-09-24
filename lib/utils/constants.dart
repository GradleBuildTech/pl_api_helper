import '../cache/cache.dart';

/// [kDefaultCacheConfig] - Default cache configuration
///
/// This constant provides a sensible default configuration for API response caching.
/// It can be used as a starting point for cache configuration or as a fallback
/// when no specific cache configuration is provided.
///
/// Default settings:
/// - Cache duration: 5 minutes
/// - Memory cache: enabled
/// - Disk cache: enabled
/// - No maximum cache size limit
/// - Cache works regardless of connection status
const kDefaultCacheConfig = CacheConfig(
  duration: Duration(minutes: 5),
  useMemoryCache: true,
  useDiskCache: true,
  maxCacheSize: null,
  onlyGetWhenDisconnected: false,
);

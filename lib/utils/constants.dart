import '../cache/cache.dart';

const kDefaultCacheConfig = CacheConfig(
  duration: Duration(minutes: 5),
  useMemoryCache: true,
  useDiskCache: true,
  maxCacheSize: null,
  onlyCacheNetworkNotFound: false,
);

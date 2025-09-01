class CacheConfig {
  final Duration duration;

  final String? keyPrefix;

  final bool useMemoryCache;

  final bool useDiskCache;

  final int? maxCacheSize;

  final bool onlyCacheNetworkNotFound;

  const CacheConfig({
    this.duration = const Duration(minutes: 5),
    this.keyPrefix,
    this.useMemoryCache = true,
    this.useDiskCache = true,
    this.maxCacheSize,
    this.onlyCacheNetworkNotFound = false,
  });

  CacheConfig copyWith({
    Duration? duration,
    String? keyPrefix,
    bool? useMemoryCache,
    bool? useDiskCache,
    int? maxCacheSize,
    bool? onlyCacheNetworkNotFound,
  }) {
    return CacheConfig(
      onlyCacheNetworkNotFound:
          onlyCacheNetworkNotFound ?? this.onlyCacheNetworkNotFound,
      duration: duration ?? this.duration,
      keyPrefix: keyPrefix ?? this.keyPrefix,
      useMemoryCache: useMemoryCache ?? this.useMemoryCache,
      useDiskCache: useDiskCache ?? this.useDiskCache,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
    );
  }
}

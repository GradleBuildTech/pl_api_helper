class CacheConfig {
  final Duration duration;

  final String? keyPrefix;

  final bool useMemoryCache;

  final bool useDiskCache;

  final int? maxCacheSize;

  final bool onlyGetWhenDisconnected;

  const CacheConfig({
    this.duration = const Duration(minutes: 5),
    this.keyPrefix,
    this.useMemoryCache = true,
    this.useDiskCache = true,
    this.maxCacheSize,
    this.onlyGetWhenDisconnected = false,
  });

  CacheConfig copyWith({
    Duration? duration,
    String? keyPrefix,
    bool? useMemoryCache,
    bool? useDiskCache,
    int? maxCacheSize,
    bool? onlyGetWhenDisconnected,
  }) {
    return CacheConfig(
      onlyGetWhenDisconnected:
          onlyGetWhenDisconnected ?? this.onlyGetWhenDisconnected,
      duration: duration ?? this.duration,
      keyPrefix: keyPrefix ?? this.keyPrefix,
      useMemoryCache: useMemoryCache ?? this.useMemoryCache,
      useDiskCache: useDiskCache ?? this.useDiskCache,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
    );
  }
}

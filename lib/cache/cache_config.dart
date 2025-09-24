/// [CacheConfig] - Configuration class for API response caching
///
/// This class defines the caching behavior for API responses, including
/// cache duration, storage options, and size limits.
///
/// Key features:
/// - Configurable cache duration
/// - Memory and disk cache options
/// - Cache size limits
/// - Network-aware caching
class CacheConfig {
  /// Duration for which cached data remains valid
  final Duration duration;

  /// Optional prefix for cache keys to avoid conflicts
  final String? keyPrefix;

  /// Whether to use memory cache for faster access
  final bool useMemoryCache;

  /// Whether to use disk cache for persistence
  final bool useDiskCache;

  /// Maximum cache size in bytes (null for unlimited)
  final int? maxCacheSize;

  /// Whether to only use cache when disconnected from network
  final bool onlyGetWhenDisconnected;

  /// Constructor for CacheConfig
  ///
  /// Parameters:
  /// - [duration]: Cache duration (default: 5 minutes)
  /// - [keyPrefix]: Optional prefix for cache keys
  /// - [useMemoryCache]: Enable memory cache (default: true)
  /// - [useDiskCache]: Enable disk cache (default: true)
  /// - [maxCacheSize]: Maximum cache size in bytes (default: null for unlimited)
  /// - [onlyGetWhenDisconnected]: Use cache only when offline (default: false)
  const CacheConfig({
    this.duration = const Duration(minutes: 5),
    this.keyPrefix,
    this.useMemoryCache = true,
    this.useDiskCache = true,
    this.maxCacheSize,
    this.onlyGetWhenDisconnected = false,
  });

  /// Create a copy of CacheConfig with updated values
  ///
  /// This method creates a new CacheConfig instance with the same values as the current
  /// instance, but with the specified parameters updated.
  ///
  /// Parameters:
  /// - [duration]: New cache duration (optional)
  /// - [keyPrefix]: New key prefix (optional)
  /// - [useMemoryCache]: New memory cache setting (optional)
  /// - [useDiskCache]: New disk cache setting (optional)
  /// - [maxCacheSize]: New maximum cache size (optional)
  /// - [onlyGetWhenDisconnected]: New offline-only setting (optional)
  ///
  /// Returns: New CacheConfig instance with updated values
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

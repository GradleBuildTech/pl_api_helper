import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pl_api_helper/cache/cache_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prefix for all cache keys to avoid conflicts with other app data
const kPrefix = 'pl_api_helper_';

/// Extension to add prefix to cache keys
extension _X on String {
  /// Add the cache prefix to a string key
  String get withPrefix => '$kPrefix$this'.toLowerCase();
}

/// [CacherManager] - Singleton manager for API response caching
///
/// This class provides a comprehensive caching solution for API responses,
/// supporting both memory and disk caching with network awareness.
///
/// Key features:
/// - Singleton pattern for global access
/// - Memory and disk cache support
/// - Network connectivity awareness
/// - Automatic cache expiration
/// - Cache size management
/// - Thread-safe operations
class CacherManager {
  /// Singleton instance of CacherManager
  static CacherManager? _instance;

  /// Get the singleton instance
  static CacherManager get instance => _instance ??= CacherManager._();

  /// Private constructor for singleton pattern
  CacherManager._();

  /// SharedPreferences instance for disk caching
  SharedPreferences? _preferences;

  /// Connectivity instance for network status checking
  final Connectivity _connectivity = Connectivity();

  /// Get SharedPreferences instance (lazy initialization)
  ///
  /// Returns: SharedPreferences instance for disk caching
  Future<SharedPreferences> get preferences async {
    if (_preferences != null) return _preferences!;
    _preferences = await SharedPreferences.getInstance();

    return _preferences!;
  }

  /// In-memory cache storage
  final Map<String, _CacheData> _cache = {};

  /// Initialize SharedPreferences if not already done
  Future<void> _initialize() async {
    _preferences ??= await preferences;
  }

  /// Check if device has network connectivity
  ///
  /// Returns: true if connected to network, false otherwise
  Future<bool> hasNetwork() async {
    final result = await _connectivity.checkConnectivity();
    return result.firstOrNull != ConnectivityResult.none;
  }

  /// Get cached data by key
  ///
  /// This method retrieves cached data from memory first, then from disk if needed.
  /// It respects cache expiration and network connectivity settings.
  ///
  /// Parameters:
  /// - [key]: Cache key to retrieve data for
  ///
  /// Returns: Cached data string, or null if not found or expired
  Future<String?> getData(String key) async {
    // Check memory cache first
    final memoryData = _cache[key.withPrefix];
    if (memoryData != null) {
      // Return data if not expired
      if (!memoryData.isExpired) return memoryData.data;
      // Return expired data if offline (fallback)
      if (!await hasNetwork()) {
        return memoryData.data;
      }
    }

    // Check disk cache if memory cache miss
    await _initialize();
    final localCached = _preferences?.getString(key.withPrefix);
    if (localCached != null) {
      try {
        final cachedData = jsonDecode(localCached) as Map<String, dynamic>;
        final cacheData = _CacheData.fromJson(cachedData);

        // Return data if not expired or if offline
        if (!cacheData.isExpired || !await hasNetwork()) {
          _cache[key.withPrefix] = cacheData;
          return cacheData.data;
        }

        // Remove expired data
        await removeData(key.withPrefix);
        return null;
      } catch (_) {
        // Remove corrupted data
        await removeData(key.withPrefix);
      }
    }
    return null;
  }

  /// Set cached data by key
  ///
  /// This method stores data in both memory and disk cache based on configuration.
  ///
  /// Parameters:
  /// - [key]: Cache key to store data under
  /// - [data]: Data to cache
  /// - [config]: Cache configuration
  Future<void> setData(String key, String data, CacheConfig config) async {
    final cacheData = _CacheData(
      data: data,
      cacheTime: DateTime.now().add(config.duration),
    );

    // Store in memory cache if enabled
    if (config.useMemoryCache) {
      _cache[key.withPrefix] = cacheData;
    }

    // Store in disk cache if enabled
    if (config.useDiskCache) {
      await _initialize();
      await _preferences?.setString(
        key.withPrefix,
        jsonEncode(cacheData.toJson()),
      );
    }
  }

  /// Remove cached data by key
  ///
  /// This method removes data from both memory and disk cache.
  ///
  /// Parameters:
  /// - [key]: Cache key to remove
  Future<void> removeData(String key) async {
    _cache.remove(key.withPrefix);
    await _initialize();
    await _preferences?.remove(key.withPrefix);
  }

  /// Clear all cached data
  ///
  /// This method removes all cached data from both memory and disk.
  /// Only removes keys with the specific cache prefix.
  Future<void> clear() async {
    _cache.clear();
    await _initialize();

    // Only remove keys with the specific prefix
    final keysToRemove = _preferences
            ?.getKeys()
            .where((key) => key.startsWith(kPrefix))
            .toList() ??
        [];
    for (final key in keysToRemove) {
      await _preferences?.remove(key);
    }
  }

  /// Get total cache size in bytes
  ///
  /// This method calculates the total size of all cached data on disk.
  ///
  /// Returns: Total cache size in bytes
  Future<int> getCacheSize() async {
    await _initialize();
    final keys = _preferences?.getKeys().where(
          (key) => key.startsWith(kPrefix),
        );
    if (keys == null || keys.isEmpty) return 0;

    int totalSize = 0;
    for (final key in keys) {
      final value = _preferences?.getString(key);
      if (value != null) {
        totalSize += value.length;
      }
    }
    return totalSize;
  }
}

/// Internal class to represent cached data with expiration
///
/// This class encapsulates cached data along with its expiration time.
/// It provides methods to check if data is expired and to serialize/deserialize data.
class _CacheData {
  /// The cached data string
  final String data;

  /// The time when the cache expires
  final DateTime cacheTime;

  /// Constructor for _CacheData
  ///
  /// Parameters:
  /// - [data]: The cached data string
  /// - [cacheTime]: The time when the cache expires
  _CacheData({required this.data, required this.cacheTime});

  /// Check if the cached data has expired
  ///
  /// Returns: true if the cache has expired, false otherwise
  bool get isExpired => DateTime.now().isAfter(cacheTime);

  /// Convert _CacheData to JSON format
  ///
  /// Returns: Map<String, dynamic> representing the cached data
  Map<String, dynamic> toJson() {
    return {'data': data, 'cacheTime': cacheTime.toIso8601String()};
  }

  /// Create _CacheData from JSON format
  ///
  /// Parameters:
  /// - [json]: JSON data as Map<String, dynamic>
  ///
  /// Returns: _CacheData instance
  factory _CacheData.fromJson(Map<String, dynamic> json) {
    return _CacheData(
      data: json['data'] as String,
      cacheTime: DateTime.parse(json['cacheTime'] as String),
    );
  }
}

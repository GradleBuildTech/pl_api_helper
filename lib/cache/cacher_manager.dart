import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pl_api_helper/cache/cache_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kPrefix = 'pl_api_helper_';

extension _X on String {
  String get withPrefix => '$kPrefix$this'.toLowerCase();
}

///[Singleton] Manager for all Cachers
class CacherManager {
  static CacherManager? _instance;
  static CacherManager get instance => _instance ??= CacherManager._();

  CacherManager._();

  SharedPreferences? _preferences;

  final Connectivity _connectivity = Connectivity();

  Future<SharedPreferences> get preferences async {
    if (_preferences != null) return _preferences!;
    _preferences = await SharedPreferences.getInstance();

    return _preferences!;
  }

  final Map<String, _CacheData> _cache = {};

  Future<void> _initialize() async {
    _preferences ??= await preferences;
  }

  Future<bool> hasNetwork() async {
    final result = await _connectivity.checkConnectivity();
    return result.firstOrNull != ConnectivityResult.none;
  }

  /// Get cached data by key
  Future<String?> getData(String key) async {
    final memoryData = _cache[key.withPrefix];
    if (memoryData != null) {
      if (!memoryData.isExpired) return memoryData.data;
      if (!await hasNetwork()) {
        return memoryData.data;
      }
    }

    await _initialize();
    final localCached = _preferences?.getString(key.withPrefix);
    if (localCached != null) {
      try {
        final cachedData = jsonDecode(localCached) as Map<String, dynamic>;
        final cacheData = _CacheData.fromJson(cachedData);
        if (!cacheData.isExpired || !await hasNetwork()) {
          _cache[key.withPrefix] = cacheData;
          return cacheData.data;
        }

        await removeData(key.withPrefix);
        return null;
      } catch (_) {
        await removeData(key.withPrefix);
      }
    }
    return null;
  }

  /// Set cached data by key
  Future<void> setData(String key, String data, CacheConfig config) async {
    final cacheData = _CacheData(
      data: data,
      cacheTime: DateTime.now().add(config.duration),
    );
    if (config.useMemoryCache) {
      _cache[key.withPrefix] = cacheData;
    }

    if (config.useDiskCache) {
      await _initialize();
      await _preferences?.setString(
        key.withPrefix,
        jsonEncode(cacheData.toJson()),
      );
    }
  }

  /// Remove cached data by key
  Future<void> removeData(String key) async {
    _cache.remove(key.withPrefix);
    await _initialize();
    await _preferences?.remove(key.withPrefix);
  }

  Future<void> clear() async {
    _cache.clear();
    await _initialize();
    //Only remove keys with the specific prefix
    final keysToRemove =
        _preferences
            ?.getKeys()
            .where((key) => key.startsWith(kPrefix))
            .toList() ??
        [];
    for (final key in keysToRemove) {
      await _preferences?.remove(key);
    }
  }

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
class _CacheData {
  final String data;
  final DateTime cacheTime;

  _CacheData({required this.data, required this.cacheTime});

  bool get isExpired => DateTime.now().isAfter(cacheTime);

  Map<String, dynamic> toJson() {
    return {'data': data, 'cacheTime': cacheTime.toIso8601String()};
  }

  factory _CacheData.fromJson(Map<String, dynamic> json) {
    return _CacheData(
      data: json['data'] as String,
      cacheTime: DateTime.parse(json['cacheTime'] as String),
    );
  }
}

import 'package:dio/dio.dart';

/// [UploadManager] is the manager for the upload task.
class UploadManager {
  static const tag = 'UploadManager';

  static const int uploadChunkSize = 1024 * 1024 * 5; // 5MB

  static const int uploadChunkTimeout = 10000; // 10 seconds

  static const int uploadChunkRetries = 3;

  static const int uploadChunkRetryDelay = 1000; // 1 second

  final Dio dio;

  UploadManager({required this.dio});

  ///Singleton
  static UploadManager? _instance;

  factory UploadManager.init({Dio? dio}) {
    _instance ??= UploadManager(dio: dio ?? Dio());
    return _instance!;
  }

  static UploadManager get instance => _instance ?? UploadManager.init();
}

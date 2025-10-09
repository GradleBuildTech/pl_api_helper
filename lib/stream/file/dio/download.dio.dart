import 'dart:async';

import 'package:dio/dio.dart';

import '../../../models/file/download.dart';

/// [DownloadManager] is the manager for the download task.
/// [downloadChunkSize] is the size of the chunk to download.
class DownloadManager {
  static const tag = 'DownloadManager';

  static const int downloadChunkSize = 1024 * 1024 * 5; // 5MB

  static const int downloadChunkTimeout = 10000; // 10 seconds

  static const int downloadChunkRetries = 3;

  static const int downloadChunkRetryDelay = 1000; // 1 second

  final Dio dio;

  DownloadManager({required this.dio});

  ///Singleton
  static DownloadManager? _instance;

  factory DownloadManager.init({Dio? dio}) {
    _instance ??= DownloadManager(dio: dio ?? Dio());
    return _instance!;
  }

  static DownloadManager get instance => _instance ?? DownloadManager.init();

  /// [DownloadModel] is the model for the download task.
  final Map<int, DownloadModel> _downTasks = {};

  /// [DownloadModel] is the model for the download task.
  final Map<int, Completer<DownloadModel>> _downTasksCompleters = {};

  /// [DownloadModel] is the model for the download task.
  final Map<int, StreamController<DownloadModel>> _downTasksControllers = {};

  /// [viewProcess] is the method to view the process of the download task.
  Stream<DownloadModel> viewProcess(int taskId) {
    return _downTasksControllers[taskId]?.stream ?? Stream.empty();
  }

  /// [download] is the method to download the file.
  Future<DownloadModel> download(
    int taskId,
    String fileName,
    int totalSize,
  ) async {
    throw UnimplementedError();
  }

  /// [cancel] is the method to cancel the download task.
  Future<void> cancel(int taskId) {
    throw UnimplementedError();
  }

  /// [pause] is the method to pause the download task.
  Future<void> pause(int taskId) {
    throw UnimplementedError();
  }

  /// [getDownloadModel] is the method to get the download model.
  Future<DownloadModel> getDownloadModel(int taskId) {
    return _downTasksCompleters[taskId]?.future ??
        Future.value(DownloadModel(
            url: '', status: DownloadStatus.pending, progress: 0, error: null));
  }

  /// [deleteDownloadModel] is the method to delete the download task.
  void deleteDownloadModel(int taskId) {
    _downTasks.remove(taskId);
    _downTasksCompleters.remove(taskId);
    _downTasksControllers.remove(taskId);
  }

  /// [getDownloadModels] is the method to get the download models.
  Future<List<DownloadModel>> getDownloadModels() {
    return Future.value(_downTasks.values.toList());
  }

  /// [dispose] is the method to dispose the download task.
  void dispose() {
    _downTasks.clear();
    _downTasksCompleters.clear();
    _downTasksControllers.clear();
  }

  Future<void> _downChunk() {
    throw UnimplementedError();
  }
}

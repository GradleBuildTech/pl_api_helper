enum DownloadStatus {
  /// [pending] is the status when the download is pending.
  pending,

  /// [downloading] is the status when the download is downloading.
  downloading,

  /// [completed] is the status when the download is completed.
  completed,

  /// [failed] is the status when the download is failed.
  failed
}

class DownloadModel {
  /// [url] is the url of the file to download.
  final String url;

  /// [status] is the status of the download.
  final DownloadStatus status;

  /// [progress] is the progress of the download.
  final double progress;

  /// [error] is the error of the download.
  final String? error;

  /// [DownloadModel] is a constructor for the DownloadModel class.
  const DownloadModel({
    required this.url,
    required this.status,
    required this.progress,
    required this.error,
  });

  /// [copyWith] is a method to copy the DownloadModel with new values.
  DownloadModel copyWith({
    String? url,
    DownloadStatus? status,
    double? progress,
    String? error,
  }) {
    return DownloadModel(
      url: url ?? this.url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

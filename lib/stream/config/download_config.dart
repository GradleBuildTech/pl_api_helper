/// [DownloadConfig] is a configuration class for download settings.
class DownloadConfig {
  /// [chunkSize] is the size of the chunk to download.
  final int chunkSize;

  /// [chunkTimeout] is the timeout for the chunk to download.
  final int chunkTimeout;

  /// [chunkRetries] is the number of retries for the chunk to download.
  final int chunkRetries;

  /// [chunkRetryDelay] is the delay for the chunk to download.
  final int chunkRetryDelay;

  /// [DownloadConfig] is a constructor for the DownloadConfig class.
  const DownloadConfig({
    required this.chunkSize,
    required this.chunkTimeout,
    required this.chunkRetries,
    required this.chunkRetryDelay,
  });

  /// [copyWith] is a method to copy the DownloadConfig with new values.
  DownloadConfig copyWith({
    int? chunkSize,
    int? chunkTimeout,
    int? chunkRetries,
    int? chunkRetryDelay,
  }) {
    return DownloadConfig(
      chunkSize: chunkSize ?? this.chunkSize,
      chunkTimeout: chunkTimeout ?? this.chunkTimeout,
      chunkRetries: chunkRetries ?? this.chunkRetries,
      chunkRetryDelay: chunkRetryDelay ?? this.chunkRetryDelay,
    );
  }
}
